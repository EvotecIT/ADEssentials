function Get-WinADDHCPSummary {
    <#
    .SYNOPSIS
    Retrieves comprehensive DHCP server information from Active Directory forest.

    .DESCRIPTION
    This function gathers comprehensive DHCP server information from all DHCP servers in the Active Directory forest.
    It collects server details, scope information, database settings, audit logs, and performs validation checks
    for common DHCP configuration issues such as lease duration, DNS settings, and failover configuration.

    When Extended mode is enabled, the function additionally collects:
    - IPv6 scope information and statistics
    - Multicast scope configuration
    - DHCP security filters and MAC address filtering
    - Network binding configuration
    - DHCP policies and processing order
    - Static reservations across all scopes
    - Active lease information for high-utilization scopes
    - Comprehensive DHCP option analysis
    - Enhanced server settings and authorization status

    .PARAMETER Forest
    Specifies the name of the forest to retrieve DHCP information from. If not specified, uses current forest.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from DHCP information retrieval.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from DHCP information retrieval.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include in DHCP information retrieval.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in DHCP information retrieval.

    .PARAMETER ComputerName
    Specifies specific DHCP servers to perform detailed analysis on. If not provided, discovers all DHCP servers in the forest.
    When specified, all discovered servers will be shown but only the specified servers will have detailed scope and configuration analysis.

    .PARAMETER SkipRODC
    Indicates whether to skip Read-Only Domain Controllers (RODC) when retrieving DHCP information.

    .PARAMETER ExtendedForestInformation
    Specifies additional extended forest information to include in the output.

    .PARAMETER Extended
    When specified, includes additional detailed information about scopes, reservations, and options.

    .EXAMPLE
    Get-WinADDHCPSummary

    Retrieves DHCP summary information from all DHCP servers in the current forest.

    .EXAMPLE
    Get-WinADDHCPSummary -Forest "example.com" -Extended

    Retrieves extended DHCP summary information from all DHCP servers in the "example.com" forest.

    .EXAMPLE
    Get-WinADDHCPSummary -ComputerName "dhcp01.example.com", "dhcp02.example.com"

    Retrieves all DHCP servers from AD but performs detailed analysis only on the specified servers.

    .EXAMPLE
    Get-WinADDHCPSummary -IncludeDomains "domain1.com", "domain2.com" -SkipRODC

    Retrieves DHCP summary information from specific domains, excluding RODCs.

    .NOTES
    This function requires the DHCP PowerShell module and appropriate permissions to query DHCP servers.
    The function performs validation checks for common DHCP misconfigurations including:
    - Lease duration longer than 48 hours
    - Missing DHCP failover configuration
    - DNS update settings with public DNS servers
    - Missing domain name options

    .OUTPUTS
    Returns a hashtable containing:
    - Servers: List of DHCP servers with their status and configuration
    - Scopes: All IPv4 DHCP scopes with detailed information
    - ScopesWithIssues: IPv4 scopes that have configuration issues
    - IPv6Scopes: IPv6 scope information (Extended mode only)
    - IPv6ScopesWithIssues: IPv6 scopes with configuration problems (Extended mode only)
    - MulticastScopes: Multicast scope configuration (Extended mode only)
    - Reservations: Static IP reservations across all scopes (Extended mode only)
    - Leases: Active lease information for high-utilization scopes (Extended mode only)
    - Policies: DHCP policies and their configuration (Extended mode only)
    - SecurityFilters: MAC address filtering configuration (Extended mode only)
    - ServerSettings: Enhanced server configuration details (Extended mode only)
    - NetworkBindings: Network interface bindings (Extended mode only)
    - Options: Comprehensive DHCP option analysis (Extended mode only)
    - AuditLogs: Audit log configuration (Extended mode only)
    - Databases: Database configuration and backup settings (Extended mode only)
    - Statistics: Summary statistics about servers, scopes, and configurations
    - ValidationResults: Results of configuration validation checks

    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [string[]] $ComputerName,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $Extended
    )

    Write-Verbose "Get-WinADDHCPSummary - Starting DHCP information gathering"

    # Initialize result structure
    $DHCPSummary = [ordered] @{
        Servers              = [System.Collections.Generic.List[Object]]::new()
        Scopes               = [System.Collections.Generic.List[Object]]::new()
        ScopesWithIssues     = [System.Collections.Generic.List[Object]]::new()
        IPv6Scopes           = [System.Collections.Generic.List[Object]]::new()
        IPv6ScopesWithIssues = [System.Collections.Generic.List[Object]]::new()
        MulticastScopes      = [System.Collections.Generic.List[Object]]::new()
        Reservations         = [System.Collections.Generic.List[Object]]::new()
        Leases               = [System.Collections.Generic.List[Object]]::new()
        Policies             = [System.Collections.Generic.List[Object]]::new()
        SecurityFilters      = [System.Collections.Generic.List[Object]]::new()
        ServerSettings       = [System.Collections.Generic.List[Object]]::new()
        NetworkBindings      = [System.Collections.Generic.List[Object]]::new()
        AuditLogs            = [System.Collections.Generic.List[Object]]::new()
        Databases            = [System.Collections.Generic.List[Object]]::new()
        Options              = [System.Collections.Generic.List[Object]]::new()
        Statistics           = [ordered] @{}
        ValidationResults    = [ordered] @{}
    }

    # Get DHCP servers from AD for discovery
    Write-Verbose "Get-WinADDHCPSummary - Discovering DHCP servers in forest"
    try {
        $DHCPServersFromAD = Get-DhcpServerInDC -ErrorAction Stop
        Write-Verbose "Get-WinADDHCPSummary - Found $($DHCPServersFromAD.Count) DHCP servers in AD"
    } catch {
        Write-Warning "Get-WinADDHCPSummary - Failed to get DHCP servers from AD: $($_.Exception.Message)"
        return $DHCPSummary
    }

    # Determine which servers to analyze in detail
    if ($ComputerName.Count -eq 0) {
        # If no specific servers provided, analyze all discovered servers
        $ServersToAnalyze = $DHCPServersFromAD.DnsName
        Write-Verbose "Get-WinADDHCPSummary - Will perform detailed analysis on all $($ServersToAnalyze.Count) discovered servers"
    } else {
        # If specific servers provided, only analyze those
        $ServersToAnalyze = $ComputerName
        Write-Verbose "Get-WinADDHCPSummary - Will perform detailed analysis on $($ServersToAnalyze.Count) specified servers"
    }

    # Create lookup for servers to analyze
    $ServersToAnalyzeSet = @{}
    foreach ($Server in $ServersToAnalyze) {
        $ServersToAnalyzeSet[$Server.ToLower()] = $true
    }

    if ($DHCPServersFromAD.Count -eq 0) {
        Write-Warning "Get-WinADDHCPSummary - No DHCP servers found"

        # Initialize statistics with zero values for empty environments
        $DHCPSummary.Statistics = [ordered] @{
            TotalServers           = 0
            ServersOnline          = 0
            ServersOffline         = 0
            ServersWithIssues      = 0
            ServersWithoutIssues   = 0
            TotalScopes            = 0
            ScopesActive           = 0
            ScopesInactive         = 0
            ScopesWithIssues       = 0
            ScopesWithoutIssues    = 0
            TotalAddresses         = 0
            AddressesInUse         = 0
            AddressesFree          = 0
            OverallPercentageInUse = 0
        }

        # Initialize empty validation results
        $DHCPSummary.ValidationResults = [ordered] @{
            Summary  = [ordered] @{
                TotalCriticalIssues = 0
                TotalWarningIssues  = 0
                TotalInfoIssues     = 0
                ScopesWithCritical  = 0
                ScopesWithWarnings  = 0
                ScopesWithInfo      = 0
            }
            Critical = @()
            Warning  = @()
            Info     = @()
        }

        return $DHCPSummary
    }

    # Get forest information for cross-referencing
    $ForestInformation = $null
    if ($Forest -or $IncludeDomains -or $ExcludeDomains -or $IncludeDomainControllers -or $ExcludeDomainControllers) {
        try {
            $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
        } catch {
            Write-Warning "Get-WinADDHCPSummary - Failed to get forest information: $($_.Exception.Message)"
        }
    }

    # Process each DHCP server (all discovered servers)
    $TotalServers = $DHCPServersFromAD.Count
    $ProcessedServers = 0
    $ServersWithIssues = 0
    $TotalScopes = 0
    $ScopesWithIssues = 0

    foreach ($DHCPServer in $DHCPServersFromAD) {
        $Computer = $DHCPServer.DnsName
        $ProcessedServers++
        Write-Progress -Activity "Processing DHCP Servers" -Status "Processing $Computer ($ProcessedServers of $TotalServers)" -PercentComplete (($ProcessedServers / $TotalServers) * 100) -Id 1

        Write-Verbose "Get-WinADDHCPSummary - Processing DHCP server: $Computer"

        # Determine if this server should be analyzed in detail
        $ShouldAnalyze = $ServersToAnalyzeSet[$Computer.ToLower()] -eq $true

        # Initialize server object
        $ServerInfo = [ordered] @{
            ServerName           = $Computer
            IsReachable          = $false
            IsADDomainController = $false
            DHCPRole             = 'Unknown'
            Version              = $null
            Status               = 'Unknown'
            ErrorMessage         = $null
            ScopeCount           = 0
            ActiveScopeCount     = 0
            InactiveScopeCount   = 0
            ScopesWithIssues     = 0
            TotalAddresses       = 0
            AddressesInUse       = 0
            AddressesFree        = 0
            PercentageInUse      = 0
            GatheredFrom         = $Computer
            GatheredDate         = Get-Date
        }

        # Check if server is a domain controller
        if ($ForestInformation) {
            $DC = $ForestInformation.ForestDomainControllers | Where-Object { $_.HostName -eq $Computer }
            if ($DC) {
                $ServerInfo.IsADDomainController = $true
                $ServerInfo.DHCPRole = 'Domain Controller'
            }
        }

        # Test connectivity and get server information only for servers to analyze
        if ($ShouldAnalyze) {
            try {
                $DHCPServerInfo = Get-DhcpServerVersion -ComputerName $Computer -ErrorAction Stop
                $ServerInfo.IsReachable = $true
                $ServerInfo.Version = $DHCPServerInfo.MajorVersion.ToString() + '.' + $DHCPServerInfo.MinorVersion.ToString()
                $ServerInfo.Status = 'Online'
            } catch {
                $ServerInfo.Status = 'Unreachable'
                $ServerInfo.ErrorMessage = $_.Exception.Message
                Write-Warning "Get-WinADDHCPSummary - Cannot reach DHCP server $Computer`: $($_.Exception.Message)"
                $ServersWithIssues++
                $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
                continue
            }
        } else {
            # For non-analyzed servers, mark as not tested
            $ServerInfo.Status = 'Not Analyzed'
            $ServerInfo.ErrorMessage = 'Server discovered but not selected for detailed analysis'
            $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
            continue
        }

        # Get DHCP scopes
        try {
            $Scopes = Get-DhcpServerv4Scope -ComputerName $Computer -ErrorAction Stop
            $ServerInfo.ScopeCount = $Scopes.Count
            $TotalScopes += $Scopes.Count

            $ActiveScopes = $Scopes | Where-Object { $_.State -eq 'Active' }
            $ServerInfo.ActiveScopeCount = $ActiveScopes.Count
            $ServerInfo.InactiveScopeCount = $Scopes.Count - $ActiveScopes.Count

            Write-Verbose "Get-WinADDHCPSummary - Found $($Scopes.Count) scopes on $Computer"
        } catch {
            Write-Warning "Get-WinADDHCPSummary - Failed to get scopes from $Computer`: $($_.Exception.Message)"
            $ServerInfo.ErrorMessage = $_.Exception.Message
            $ServersWithIssues++
            $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
            continue
        }

        # Process each scope
        $ServerScopesWithIssues = 0
        $ServerTotalAddresses = 0
        $ServerAddressesInUse = 0
        $ServerAddressesFree = 0
        $ScopeCounter = 0

        foreach ($Scope in $Scopes) {
            $ScopeCounter++
            Write-Progress -Activity "Processing DHCP Servers" -Status "Processing $Computer ($ProcessedServers of $TotalServers)" -PercentComplete (($ProcessedServers / $TotalServers) * 100) -Id 1
            Write-Progress -Activity "Processing Scopes on $Computer" -Status "Scope $($Scope.ScopeId) ($ScopeCounter of $($Scopes.Count))" -PercentComplete (($ScopeCounter / $Scopes.Count) * 100) -ParentId 1 -Id 2
            Write-Verbose "Get-WinADDHCPSummary - Processing scope $($Scope.ScopeId) on $Computer"

            $ScopeObject = [ordered] @{
                ServerName         = $Computer
                ScopeId            = $Scope.ScopeId
                Name               = $Scope.Name
                Description        = $Scope.Description
                State              = $Scope.State
                SubnetMask         = $Scope.SubnetMask
                StartRange         = $Scope.StartRange
                EndRange           = $Scope.EndRange
                LeaseDuration      = $Scope.LeaseDuration
                LeaseDurationHours = $Scope.LeaseDuration.TotalHours
                Type               = $Scope.Type
                SuperscopeName     = $Scope.SuperscopeName
                AddressesInUse     = 0
                AddressesFree      = 0
                PercentageInUse    = 0
                Reserved           = 0
                HasIssues          = $false
                Issues             = [System.Collections.Generic.List[string]]::new()
                DNSSettings        = $null
                FailoverPartner    = $null
                GatheredFrom       = $Computer
                GatheredDate       = Get-Date
            }

            # Get scope statistics
            try {
                $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                $ScopeObject.AddressesInUse = $ScopeStats.AddressesInUse
                $ScopeObject.AddressesFree = $ScopeStats.AddressesFree
                $ScopeObject.PercentageInUse = [Math]::Round($ScopeStats.PercentageInUse, 2)
                $ScopeObject.Reserved = $ScopeStats.Reserved

                $ServerTotalAddresses += ($ScopeStats.AddressesInUse + $ScopeStats.AddressesFree)
                $ServerAddressesInUse += $ScopeStats.AddressesInUse
                $ServerAddressesFree += $ScopeStats.AddressesFree
            } catch {
                Write-Warning "Get-WinADDHCPSummary - Failed to get scope statistics for $($Scope.ScopeId) on $Computer`: $($_.Exception.Message)"
            }

            # Validate scope configuration
            # Check lease duration (should not exceed 48 hours unless explicitly documented)
            if ($Scope.LeaseDuration.TotalHours -gt 48) {
                # Check for documented exceptions (like your validator's "DHCP lease time" check)
                if ($Scope.Description -notlike "*DHCP lease time*" -and
                    $Scope.Description -notlike "*lease time*" -and
                    $Scope.Description -notlike "*7d*" -and
                    $Scope.Description -notlike "*day*") {
                    $ScopeObject.Issues.Add("Lease duration exceeds 48 hours ($([Math]::Round($Scope.LeaseDuration.TotalHours, 1)) hours) without documented exception")
                    $ScopeObject.HasIssues = $true
                }
            }

            # Check DNS settings
            try {
                $DNSSettings = Get-DhcpServerv4DnsSetting -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                $ScopeObject.DNSSettings = $DNSSettings

                # Check for dynamic DNS updates with public DNS servers
                if ($DNSSettings.DynamicUpdates -ne 'Never') {
                    try {
                        $Options = Get-DhcpServerv4OptionValue -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        $Option6 = $Options | Where-Object { $_.OptionId -eq 6 }  # DNS Servers
                        $Option15 = $Options | Where-Object { $_.OptionId -eq 15 } # Domain Name

                        if ($Option6 -and $Option6.Value) {
                            # Check for non-private DNS servers (similar to your validator's ^10. check)
                            $NonPrivateDNS = $Option6.Value | Where-Object { $_ -notmatch "^10\." -and $_ -notmatch "^192\.168\." -and $_ -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\." }
                            if ($NonPrivateDNS) {
                                $ScopeObject.Issues.Add("DNS updates enabled with non-private DNS servers: $($NonPrivateDNS -join ', ')")
                                $ScopeObject.HasIssues = $true
                            }
                        }

                        # Enhanced DNS update validation (from your validator)
                        if (-not $DNSSettings.UpdateDnsRRForOlderClients -and -not $DNSSettings.DeleteDnsRROnLeaseExpiry) {
                            $ScopeObject.Issues.Add("Both UpdateDnsRRForOlderClients and DeleteDnsRROnLeaseExpiry are disabled")
                            $ScopeObject.HasIssues = $true
                        } elseif (-not $DNSSettings.UpdateDnsRRForOlderClients) {
                            $ScopeObject.Issues.Add("UpdateDnsRRForOlderClients is disabled")
                            $ScopeObject.HasIssues = $true
                        } elseif (-not $DNSSettings.DeleteDnsRROnLeaseExpiry) {
                            $ScopeObject.Issues.Add("DeleteDnsRROnLeaseExpiry is disabled")
                            $ScopeObject.HasIssues = $true
                        }

                        if (-not $Option15 -or [string]::IsNullOrEmpty($Option15.Value)) {
                            $ScopeObject.Issues.Add("Domain name option (015) is empty")
                            $ScopeObject.HasIssues = $true
                        }
                    } catch {
                        Write-Warning "Get-WinADDHCPSummary - Failed to get DHCP options for scope $($Scope.ScopeId) on $Computer`: $($_.Exception.Message)"
                    }
                }
            } catch {
                Write-Warning "Get-WinADDHCPSummary - Failed to get DNS settings for scope $($Scope.ScopeId) on $Computer`: $($_.Exception.Message)"
            }

            # Check DHCP failover configuration
            try {
                $Failover = Get-DhcpServerv4Failover -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction SilentlyContinue
                if ($Failover) {
                    $ScopeObject.FailoverPartner = $Failover.PartnerServer
                } else {
                    $ScopeObject.Issues.Add("DHCP Failover not configured")
                    $ScopeObject.HasIssues = $true
                }
            } catch {
                # Failover may not be configured, which is not necessarily an error
                Write-Verbose "Get-WinADDHCPSummary - No failover configuration for scope $($Scope.ScopeId) on $Computer"
            }

            if ($ScopeObject.HasIssues) {
                $ServerScopesWithIssues++
                $ScopesWithIssues++
                $DHCPSummary.ScopesWithIssues.Add([PSCustomObject]$ScopeObject)
            }

            $DHCPSummary.Scopes.Add([PSCustomObject]$ScopeObject)
        }

        # Clear scope-level progress when done with this server's scopes
        Write-Progress -Activity "Processing Scopes on $Computer" -Completed -Id 2

        # Update server statistics
        $ServerInfo.ScopesWithIssues = $ServerScopesWithIssues
        $ServerInfo.TotalAddresses = $ServerTotalAddresses
        $ServerInfo.AddressesInUse = $ServerAddressesInUse
        $ServerInfo.AddressesFree = $ServerAddressesFree
        if ($ServerTotalAddresses -gt 0) {
            $ServerInfo.PercentageInUse = [Math]::Round(($ServerAddressesInUse / $ServerTotalAddresses) * 100, 2)
        }

        if ($ServerScopesWithIssues -gt 0) {
            $ServersWithIssues++
        }

        # Get audit log information
        if ($Extended) {
            try {
                $AuditLog = Get-DhcpServerAuditLog -ComputerName $Computer -ErrorAction Stop
                $AuditLogObject = [PSCustomObject] @{
                    ServerName        = $Computer
                    DiskCheckInterval = $AuditLog.DiskCheckInterval
                    Enable            = $AuditLog.Enable
                    MaxMBFileSize     = $AuditLog.MaxMBFileSize
                    MinMBDiskSpace    = $AuditLog.MinMBDiskSpace
                    Path              = $AuditLog.Path
                    GatheredFrom      = $Computer
                    GatheredDate      = Get-Date
                }
                $DHCPSummary.AuditLogs.Add($AuditLogObject)
            } catch {
                Write-Warning "Get-WinADDHCPSummary - Failed to get audit log from $Computer`: $($_.Exception.Message)"
            }

            # Get database information
            try {
                $Database = Get-DhcpServerDatabase -ComputerName $Computer -ErrorAction Stop
                $DatabaseObject = [PSCustomObject] @{
                    ServerName             = $Computer
                    FileName               = $Database.FileName
                    BackupPath             = $Database.BackupPath
                    BackupIntervalMinutes  = $Database.'BackupInterval(m)'
                    CleanupIntervalMinutes = $Database.'CleanupInterval(m)'
                    LoggingEnabled         = $Database.LoggingEnabled
                    RestoreFromBackup      = $Database.RestoreFromBackup
                    GatheredFrom           = $Computer
                    GatheredDate           = Get-Date
                }
                $DHCPSummary.Databases.Add($DatabaseObject)
            } catch {
                Write-Warning "Get-WinADDHCPSummary - Failed to get database information from $Computer`: $($_.Exception.Message)"
            }

            # Get enhanced server configuration (with comprehensive error handling)
            try {
                Write-Verbose "Get-WinADDHCPSummary - Gathering enhanced server configuration for $Computer"

                # Server settings (may require elevated permissions)
                try {
                    $ServerSettings = Get-DhcpServerSetting -ComputerName $Computer -ErrorAction Stop
                    $ServerSettingsObject = [PSCustomObject] @{
                        ServerName                = $Computer
                        ActivatePolicies          = if ($null -ne $ServerSettings.ActivatePolicies) { $ServerSettings.ActivatePolicies } else { $false }
                        ConflictDetectionAttempts = if ($ServerSettings.ConflictDetectionAttempts) { $ServerSettings.ConflictDetectionAttempts } else { 0 }
                        DynamicBootp              = if ($null -ne $ServerSettings.DynamicBootp) { $ServerSettings.DynamicBootp } else { $false }
                        IsAuthorized              = if ($null -ne $ServerSettings.IsAuthorized) { $ServerSettings.IsAuthorized } else { $false }
                        IsDomainJoined            = if ($null -ne $ServerSettings.IsDomainJoined) { $ServerSettings.IsDomainJoined } else { $false }
                        NapEnabled                = if ($null -ne $ServerSettings.NapEnabled) { $ServerSettings.NapEnabled } else { $false }
                        NpsUnreachableAction      = $ServerSettings.NpsUnreachableAction
                        RestoreStatus             = $ServerSettings.RestoreStatus
                        GatheredFrom              = $Computer
                        GatheredDate              = Get-Date
                    }
                    $DHCPSummary.ServerSettings.Add($ServerSettingsObject)
                    Write-Verbose "Get-WinADDHCPSummary - Server settings collected for $Computer"
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*access*denied*" -or $ErrorMessage -like "*permission*") {
                        Write-Verbose "Get-WinADDHCPSummary - Insufficient permissions to read server settings on $Computer"
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - Failed to get server settings from $Computer`: $ErrorMessage"
                    }
                }

                # Network bindings (should be accessible with basic DHCP permissions)
                try {
                    $Bindings = Get-DhcpServerv4Binding -ComputerName $Computer -ErrorAction Stop
                    if ($Bindings -and $Bindings.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($Bindings.Count) network bindings on $Computer"

                        foreach ($Binding in $Bindings) {
                            $BindingObject = [PSCustomObject] @{
                                ServerName     = $Computer
                                InterfaceIndex = if ($Binding.InterfaceIndex) { $Binding.InterfaceIndex } else { 0 }
                                InterfaceAlias = $Binding.InterfaceAlias
                                IPAddress      = $Binding.IPAddress
                                SubnetMask     = $Binding.SubnetMask
                                State          = if ($null -ne $Binding.State) { $Binding.State } else { 'Unknown' }
                                GatheredFrom   = $Computer
                                GatheredDate   = Get-Date
                            }
                            $DHCPSummary.NetworkBindings.Add($BindingObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No network bindings found on $Computer"
                    }
                } catch {
                    Write-Verbose "Get-WinADDHCPSummary - Failed to get network bindings from $Computer`: $($_.Exception.Message)"
                }

                # Security filters (may not be configured on all servers)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking security filters on $Computer"
                    $FilterList = Get-DhcpServerv4FilterList -ComputerName $Computer -ErrorAction Stop

                    $SecurityFilterObject = [PSCustomObject] @{
                        ServerName    = $Computer
                        Allow         = if ($FilterList.Allow) { $FilterList.Allow } else { $false }
                        Deny          = if ($FilterList.Deny) { $FilterList.Deny } else { $false }
                        FilteringMode = if ($FilterList.Allow -and $FilterList.Deny) { 'Both' } elseif ($FilterList.Allow) { 'Allow' } elseif ($FilterList.Deny) { 'Deny' } else { 'None' }
                        GatheredFrom  = $Computer
                        GatheredDate  = Get-Date
                    }
                    $DHCPSummary.SecurityFilters.Add($SecurityFilterObject)
                    Write-Verbose "Get-WinADDHCPSummary - Security filter mode on $Computer`: $($SecurityFilterObject.FilteringMode)"
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*") {
                        Write-Verbose "Get-WinADDHCPSummary - Security filtering not available on $Computer (this is normal for older DHCP servers)"
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - Error checking security filters on $Computer`: $ErrorMessage"
                    }

                    # Add a default entry indicating no filtering
                    $SecurityFilterObject = [PSCustomObject] @{
                        ServerName    = $Computer
                        Allow         = $false
                        Deny          = $false
                        FilteringMode = 'Not Available'
                        GatheredFrom  = $Computer
                        GatheredDate  = Get-Date
                    }
                    $DHCPSummary.SecurityFilters.Add($SecurityFilterObject)
                }

                # IPv6 Scopes (with robust error handling since IPv6 DHCP is rarely deployed)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking for IPv6 DHCP support on $Computer"

                    # Test if IPv6 DHCP service is available first
                    $IPv6Scopes = $null
                    $IPv6Supported = $false

                    try {
                        $IPv6Scopes = Get-DhcpServerv6Scope -ComputerName $Computer -ErrorAction Stop
                        $IPv6Supported = $true
                        Write-Verbose "Get-WinADDHCPSummary - IPv6 DHCP service detected on $Computer"
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        # Common error patterns for IPv6 not supported/configured
                        if ($ErrorMessage -like "*not found*" -or
                            $ErrorMessage -like "*not supported*" -or
                            $ErrorMessage -like "*service*" -or
                            $ErrorMessage -like "*RPC*" -or
                            $ErrorMessage -like "*access*denied*") {
                            Write-Verbose "Get-WinADDHCPSummary - IPv6 DHCP not available on $Computer (this is normal): $ErrorMessage"
                        } else {
                            Write-Warning "Get-WinADDHCPSummary - Unexpected error checking IPv6 DHCP on $Computer`: $ErrorMessage"
                        }
                    }

                    if ($IPv6Supported -and $IPv6Scopes -and $IPv6Scopes.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($IPv6Scopes.Count) IPv6 scopes on $Computer"

                        foreach ($IPv6Scope in $IPv6Scopes) {
                            Write-Verbose "Get-WinADDHCPSummary - Processing IPv6 scope $($IPv6Scope.Prefix) on $Computer"

                            $IPv6ScopeObject = [ordered] @{
                                ServerName        = $Computer
                                Prefix            = $IPv6Scope.Prefix
                                Name              = $IPv6Scope.Name
                                Description       = $IPv6Scope.Description
                                State             = $IPv6Scope.State
                                Preference        = $IPv6Scope.Preference
                                ValidLifetime     = $IPv6Scope.ValidLifetime
                                PreferredLifetime = $IPv6Scope.PreferredLifetime
                                T1                = $IPv6Scope.T1
                                T2                = $IPv6Scope.T2
                                AddressesInUse    = 0
                                AddressesFree     = 0
                                PercentageInUse   = 0
                                HasIssues         = $false
                                Issues            = [System.Collections.Generic.List[string]]::new()
                                GatheredFrom      = $Computer
                                GatheredDate      = Get-Date
                            }

                            # Get IPv6 scope statistics (with additional error handling)
                            try {
                                $IPv6Stats = Get-DhcpServerv6ScopeStatistics -ComputerName $Computer -Prefix $IPv6Scope.Prefix -ErrorAction Stop
                                $IPv6ScopeObject.AddressesInUse = if ($IPv6Stats.AddressesInUse) { $IPv6Stats.AddressesInUse } else { 0 }
                                $IPv6ScopeObject.AddressesFree = if ($IPv6Stats.AddressesFree) { $IPv6Stats.AddressesFree } else { 0 }
                                $IPv6ScopeObject.PercentageInUse = if ($IPv6Stats.PercentageInUse) { [Math]::Round($IPv6Stats.PercentageInUse, 2) } else { 0 }
                                Write-Verbose "Get-WinADDHCPSummary - IPv6 scope $($IPv6Scope.Prefix) utilization: $($IPv6ScopeObject.PercentageInUse)%"
                            } catch {
                                Write-Verbose "Get-WinADDHCPSummary - Failed to get IPv6 scope statistics for $($IPv6Scope.Prefix) on $Computer`: $($_.Exception.Message)"
                                $IPv6ScopeObject.Issues.Add("Unable to retrieve IPv6 scope statistics")
                                $IPv6ScopeObject.HasIssues = $true
                            }

                            # IPv6 scope validation (basic checks since IPv6 DHCP is different)
                            if ($IPv6Scope.State -eq 'InActive') {
                                $IPv6ScopeObject.Issues.Add("IPv6 scope is inactive")
                                $IPv6ScopeObject.HasIssues = $true
                            }

                            # Check for reasonable lifetimes (IPv6 specific)
                            if ($IPv6Scope.ValidLifetime -and $IPv6Scope.ValidLifetime.TotalDays -gt 30) {
                                $IPv6ScopeObject.Issues.Add("Very long valid lifetime: $([Math]::Round($IPv6Scope.ValidLifetime.TotalDays, 1)) days")
                                $IPv6ScopeObject.HasIssues = $true
                            }

                            if ($IPv6ScopeObject.HasIssues) {
                                $DHCPSummary.IPv6ScopesWithIssues.Add([PSCustomObject]$IPv6ScopeObject)
                            }

                            $DHCPSummary.IPv6Scopes.Add([PSCustomObject]$IPv6ScopeObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No IPv6 scopes found on $Computer (IPv6 DHCP not deployed)"
                    }
                } catch {
                    # This catch should rarely be reached due to inner try-catch, but provides final safety net
                    Write-Verbose "Get-WinADDHCPSummary - IPv6 DHCP analysis skipped for $Computer`: $($_.Exception.Message)"
                }

                # Multicast scopes (rarely used - handle gracefully)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking for multicast DHCP scopes on $Computer"
                    $MulticastScopes = Get-DhcpServerv4MulticastScope -ComputerName $Computer -ErrorAction Stop

                    if ($MulticastScopes -and $MulticastScopes.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($MulticastScopes.Count) multicast scopes on $Computer"

                        foreach ($MulticastScope in $MulticastScopes) {
                            Write-Verbose "Get-WinADDHCPSummary - Processing multicast scope $($MulticastScope.Name) on $Computer"

                            $MulticastScopeObject = [PSCustomObject] @{
                                ServerName      = $Computer
                                Name            = $MulticastScope.Name
                                StartRange      = $MulticastScope.StartRange
                                EndRange        = $MulticastScope.EndRange
                                Description     = $MulticastScope.Description
                                State           = $MulticastScope.State
                                Ttl             = $MulticastScope.Ttl
                                ExpiryTime      = $MulticastScope.ExpiryTime
                                LeaseDuration   = $MulticastScope.LeaseDuration
                                AddressesInUse  = 0
                                AddressesFree   = 0
                                PercentageInUse = 0
                                GatheredFrom    = $Computer
                                GatheredDate    = Get-Date
                            }

                            # Get multicast scope statistics (with error handling)
                            try {
                                $MulticastStats = Get-DhcpServerv4MulticastScopeStatistics -ComputerName $Computer -Name $MulticastScope.Name -ErrorAction Stop
                                $MulticastScopeObject.AddressesInUse = if ($MulticastStats.AddressesInUse) { $MulticastStats.AddressesInUse } else { 0 }
                                $MulticastScopeObject.AddressesFree = if ($MulticastStats.AddressesFree) { $MulticastStats.AddressesFree } else { 0 }
                                $MulticastScopeObject.PercentageInUse = if ($MulticastStats.PercentageInUse) { [Math]::Round($MulticastStats.PercentageInUse, 2) } else { 0 }
                                Write-Verbose "Get-WinADDHCPSummary - Multicast scope $($MulticastScope.Name) utilization: $($MulticastScopeObject.PercentageInUse)%"
                            } catch {
                                Write-Verbose "Get-WinADDHCPSummary - Failed to get multicast scope statistics for $($MulticastScope.Name) on $Computer`: $($_.Exception.Message)"
                            }

                            $DHCPSummary.MulticastScopes.Add($MulticastScopeObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No multicast scopes found on $Computer (multicast DHCP not configured)"
                    }
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*") {
                        Write-Verbose "Get-WinADDHCPSummary - Multicast DHCP not available on $Computer (this is normal)"
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - Error checking multicast scopes on $Computer`: $ErrorMessage"
                    }
                }

                # DHCP Policies (advanced feature - may not be available on all DHCP servers)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking for DHCP policies on $Computer"
                    $Policies = Get-DhcpServerv4Policy -ComputerName $Computer -ErrorAction Stop

                    if ($Policies -and $Policies.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($Policies.Count) DHCP policies on $Computer"

                        foreach ($Policy in $Policies) {
                            Write-Verbose "Get-WinADDHCPSummary - Processing policy $($Policy.Name) on $Computer"

                            $PolicyObject = [PSCustomObject] @{
                                ServerName      = $Computer
                                Name            = $Policy.Name
                                ScopeId         = $Policy.ScopeId
                                Description     = $Policy.Description
                                Enabled         = if ($Policy.Enabled) { $Policy.Enabled } else { $false }
                                ProcessingOrder = if ($Policy.ProcessingOrder) { $Policy.ProcessingOrder } else { 0 }
                                Condition       = $Policy.Condition
                                GatheredFrom    = $Computer
                                GatheredDate    = Get-Date
                            }
                            $DHCPSummary.Policies.Add($PolicyObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No DHCP policies configured on $Computer"
                    }
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*" -or $ErrorMessage -like "*not available*") {
                        Write-Verbose "Get-WinADDHCPSummary - DHCP policies not available on $Computer (requires Windows Server 2012+ DHCP)"
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - Error checking DHCP policies on $Computer`: $ErrorMessage"
                    }
                }

                # Reservations analysis for each scope
                foreach ($Scope in $Scopes) {
                    try {
                        $Reservations = Get-DhcpServerv4Reservation -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        foreach ($Reservation in $Reservations) {
                            $ReservationObject = [PSCustomObject] @{
                                ServerName   = $Computer
                                ScopeId      = $Scope.ScopeId
                                IPAddress    = $Reservation.IPAddress
                                ClientId     = $Reservation.ClientId
                                Name         = $Reservation.Name
                                Description  = $Reservation.Description
                                Type         = $Reservation.Type
                                GatheredFrom = $Computer
                                GatheredDate = Get-Date
                            }
                            $DHCPSummary.Reservations.Add($ReservationObject)
                        }
                    } catch {
                        Write-Verbose "Get-WinADDHCPSummary - No reservations found for scope $($Scope.ScopeId) on $Computer"
                    }

                    # Active leases analysis (sample for high utilization scopes)
                    try {
                        $CurrentScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        if ($Scope.State -eq 'Active' -and $CurrentScopeStats.PercentageInUse -gt 75) {
                            $Leases = Get-DhcpServerv4Lease -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop | Select-Object -First 100
                            foreach ($Lease in $Leases) {
                                $LeaseObject = [PSCustomObject] @{
                                    ServerName      = $Computer
                                    ScopeId         = $Scope.ScopeId
                                    IPAddress       = $Lease.IPAddress
                                    AddressState    = $Lease.AddressState
                                    ClientId        = $Lease.ClientId
                                    HostName        = $Lease.HostName
                                    LeaseExpiryTime = $Lease.LeaseExpiryTime
                                    ProbationEnds   = $Lease.ProbationEnds
                                    GatheredFrom    = $Computer
                                    GatheredDate    = Get-Date
                                }
                                $DHCPSummary.Leases.Add($LeaseObject)
                            }
                        }
                    } catch {
                        Write-Verbose "Get-WinADDHCPSummary - Failed to get leases for scope $($Scope.ScopeId) on $Computer"
                    }

                    # Enhanced options collection
                    try {
                        $ScopeOptions = Get-DhcpServerv4OptionValue -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        foreach ($Option in $ScopeOptions) {
                            $OptionObject = [PSCustomObject] @{
                                ServerName   = $Computer
                                ScopeId      = $Scope.ScopeId
                                OptionId     = $Option.OptionId
                                Name         = $Option.Name
                                Value        = ($Option.Value -join ', ')
                                VendorClass  = $Option.VendorClass
                                UserClass    = $Option.UserClass
                                PolicyName   = $Option.PolicyName
                                GatheredFrom = $Computer
                                GatheredDate = Get-Date
                            }
                            $DHCPSummary.Options.Add($OptionObject)
                        }
                    } catch {
                        Write-Verbose "Get-WinADDHCPSummary - Failed to get options for scope $($Scope.ScopeId) on $Computer"
                    }
                }

            } catch {
                Write-Warning "Get-WinADDHCPSummary - Failed to get enhanced server configuration from $Computer`: $($_.Exception.Message)"
            }
        }
    }

    # Calculate overall statistics efficiently using single-pass operations
    $ServersOnlineCount = 0
    $ServersOfflineCount = 0
    $ScopesActiveCount = 0
    $ScopesInactiveCount = 0

    foreach ($Server in $DHCPSummary.Servers) {
        if ($Server.Status -eq 'Online') { $ServersOnlineCount++ }
        elseif ($Server.Status -eq 'Unreachable') { $ServersOfflineCount++ }
    }

    foreach ($Scope in $DHCPSummary.Scopes) {
        if ($Scope.State -eq 'Active') { $ScopesActiveCount++ }
        elseif ($Scope.State -eq 'Inactive') { $ScopesInactiveCount++ }
    }

    $DHCPSummary.Statistics = [ordered] @{
        TotalServers           = $TotalServers
        ServersOnline          = $ServersOnlineCount
        ServersOffline         = $ServersOfflineCount
        ServersWithIssues      = $ServersWithIssues
        ServersWithoutIssues   = $TotalServers - $ServersWithIssues
        TotalScopes            = $TotalScopes
        ScopesActive           = $ScopesActiveCount
        ScopesInactive         = $ScopesInactiveCount
        ScopesWithIssues       = $ScopesWithIssues
        ScopesWithoutIssues    = $TotalScopes - $ScopesWithIssues
        TotalAddresses         = ($DHCPSummary.Servers | Measure-Object -Property TotalAddresses -Sum).Sum
        AddressesInUse         = ($DHCPSummary.Servers | Measure-Object -Property AddressesInUse -Sum).Sum
        AddressesFree          = ($DHCPSummary.Servers | Measure-Object -Property AddressesFree -Sum).Sum
        OverallPercentageInUse = 0
        # Enhanced statistics for new data types
        TotalIPv6Scopes        = $DHCPSummary.IPv6Scopes.Count
        IPv6ScopesWithIssues   = $DHCPSummary.IPv6ScopesWithIssues.Count
        TotalMulticastScopes   = $DHCPSummary.MulticastScopes.Count
        TotalReservations      = $DHCPSummary.Reservations.Count
        TotalPolicies          = $DHCPSummary.Policies.Count
        TotalSecurityFilters   = $DHCPSummary.SecurityFilters.Count
        TotalNetworkBindings   = $DHCPSummary.NetworkBindings.Count
        TotalOptions           = $DHCPSummary.Options.Count
        ServersWithFiltering   = ($DHCPSummary.SecurityFilters | Where-Object { $_.FilteringMode -ne 'None' }).Count
        ServersWithPolicies    = ($DHCPSummary.Policies | Select-Object -Property ServerName -Unique).Count
    }

    # Categorize validation results efficiently using single-pass operations
    $PublicDNSWithUpdates = [System.Collections.Generic.List[Object]]::new()
    $HighUtilization = [System.Collections.Generic.List[Object]]::new()
    $ServersOffline = [System.Collections.Generic.List[Object]]::new()
    $MissingFailover = [System.Collections.Generic.List[Object]]::new()
    $ExtendedLeaseDuration = [System.Collections.Generic.List[Object]]::new()
    $ModerateUtilization = [System.Collections.Generic.List[Object]]::new()
    $DNSRecordManagement = [System.Collections.Generic.List[Object]]::new()
    $MissingDomainName = [System.Collections.Generic.List[Object]]::new()
    $InactiveScopes = [System.Collections.Generic.List[Object]]::new()

    # Single pass through servers for offline check
    foreach ($Server in $DHCPSummary.Servers) {
        if ($Server.Status -eq 'Unreachable') {
            $ServersOffline.Add($Server)
        }
    }

    # Single pass through scopes for all validations
    foreach ($Scope in $DHCPSummary.Scopes) {
        # Check utilization levels
        if ($Scope.State -eq 'Active') {
            if ($Scope.PercentageInUse -gt 90) {
                $HighUtilization.Add($Scope)
            } elseif ($Scope.PercentageInUse -gt 75) {
                $ModerateUtilization.Add($Scope)
            }
        }

        # Check inactive scopes
        if ($Scope.State -eq 'Inactive') {
            $InactiveScopes.Add($Scope)
        }
    }

    # Single pass through scopes with issues for detailed validations
    foreach ($Scope in $DHCPSummary.ScopesWithIssues) {
        foreach ($Issue in $Scope.Issues) {
            if ($Issue -like "*public DNS servers*") {
                $PublicDNSWithUpdates.Add($Scope)
            } elseif ($Issue -like "*Failover not configured*") {
                $MissingFailover.Add($Scope)
            } elseif ($Issue -like "*exceeds 48 hours*") {
                $ExtendedLeaseDuration.Add($Scope)
            } elseif ($Issue -like "*UpdateDnsRRForOlderClients*" -or $Issue -like "*DeleteDnsRROnLeaseExpiry*") {
                $DNSRecordManagement.Add($Scope)
            } elseif ($Issue -like "*Domain name option*") {
                $MissingDomainName.Add($Scope)
            }
        }
    }

    $DHCPSummary.ValidationResults = [ordered] @{
        # Critical issues that require immediate attention
        CriticalIssues = [ordered] @{
            PublicDNSWithUpdates = $PublicDNSWithUpdates
            HighUtilization      = $HighUtilization
            ServersOffline       = $ServersOffline
        }
        # Warning issues that should be addressed soon
        WarningIssues  = [ordered] @{
            MissingFailover       = $MissingFailover
            ExtendedLeaseDuration = $ExtendedLeaseDuration
            ModerateUtilization   = $ModerateUtilization
            DNSRecordManagement   = $DNSRecordManagement
        }
        # Information issues that are good to know but not urgent
        InfoIssues     = [ordered] @{
            MissingDomainName = $MissingDomainName
            InactiveScopes    = $InactiveScopes
        }
        # Summary counters for quick overview
        Summary        = [ordered] @{
            TotalCriticalIssues = 0
            TotalWarningIssues  = 0
            TotalInfoIssues     = 0
            ScopesWithCritical  = 0
            ScopesWithWarnings  = 0
            ScopesWithInfo      = 0
        }
    }

    if ($DHCPSummary.Statistics.TotalAddresses -gt 0) {
        $DHCPSummary.Statistics.OverallPercentageInUse = [Math]::Round(($DHCPSummary.Statistics.AddressesInUse / $DHCPSummary.Statistics.TotalAddresses) * 100, 2)
    }

    # Calculate validation summary counters efficiently
    $DHCPSummary.ValidationResults.Summary.TotalCriticalIssues = (
        $PublicDNSWithUpdates.Count +
        $HighUtilization.Count +
        $ServersOffline.Count
    )

    $DHCPSummary.ValidationResults.Summary.TotalWarningIssues = (
        $MissingFailover.Count +
        $ExtendedLeaseDuration.Count +
        $ModerateUtilization.Count +
        $DNSRecordManagement.Count
    )

    $DHCPSummary.ValidationResults.Summary.TotalInfoIssues = (
        $MissingDomainName.Count +
        $InactiveScopes.Count
    )

    # Calculate unique scope counts for each severity level using efficient single-pass array comprehension
    $CriticalScopes = @(
        $PublicDNSWithUpdates
        $HighUtilization
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithCritical = ($CriticalScopes | Sort-Object -Property ScopeId -Unique).Count

    $WarningScopes = @(
        $MissingFailover
        $ExtendedLeaseDuration
        $ModerateUtilization
        $DNSRecordManagement
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithWarnings = ($WarningScopes | Sort-Object -Property ScopeId -Unique).Count

    $InfoScopes = @(
        $MissingDomainName
        $InactiveScopes
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithInfo = ($InfoScopes | Sort-Object -Property ScopeId -Unique).Count

    Write-Progress -Activity "Processing DHCP Servers" -Completed
    Write-Verbose "Get-WinADDHCPSummary - DHCP information gathering completed"

    return $DHCPSummary
}
