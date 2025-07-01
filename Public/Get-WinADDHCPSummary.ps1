function Get-WinADDHCPSummary {
    <#
    .SYNOPSIS
    Retrieves comprehensive DHCP server information from Active Directory forest.

    .DESCRIPTION
    This function gathers detailed DHCP server information from all DHCP servers in the Active Directory forest.
    It collects server details, scope information, database settings, audit logs, and performs validation checks
    for common DHCP configuration issues such as lease duration, DNS settings, and failover configuration.

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
    Specifies specific DHCP servers to query. If not provided, discovers all DHCP servers in the forest.

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

    Retrieves DHCP summary information from specific DHCP servers.

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
    - Servers: List of DHCP servers with their status
    - Scopes: All DHCP scopes with detailed information
    - ScopesWithIssues: Scopes that have configuration issues
    - Statistics: Summary statistics about servers and scopes
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
        Servers           = [System.Collections.Generic.List[Object]]::new()
        Scopes            = [System.Collections.Generic.List[Object]]::new()
        ScopesWithIssues  = [System.Collections.Generic.List[Object]]::new()
        AuditLogs         = [System.Collections.Generic.List[Object]]::new()
        Databases         = [System.Collections.Generic.List[Object]]::new()
        Statistics        = [ordered] @{}
        ValidationResults = [ordered] @{}
    }

    # Get DHCP servers
    if ($ComputerName.Count -eq 0) {
        Write-Verbose "Get-WinADDHCPSummary - Discovering DHCP servers in forest"
        try {
            $DHCPServersFromAD = Get-DhcpServerInDC -ErrorAction Stop
            $ComputerName = $DHCPServersFromAD.DnsName
            Write-Verbose "Get-WinADDHCPSummary - Found $($ComputerName.Count) DHCP servers in AD"
        } catch {
            Write-Warning "Get-WinADDHCPSummary - Failed to get DHCP servers from AD: $($_.Exception.Message)"
            return $DHCPSummary
        }
    }

    if ($ComputerName.Count -eq 0) {
        Write-Warning "Get-WinADDHCPSummary - No DHCP servers found"

        # Initialize statistics with zero values for empty environments
        $DHCPSummary.Statistics = [ordered] @{
            TotalServers                = 0
            ServersOnline              = 0
            ServersOffline             = 0
            ServersWithIssues          = 0
            ServersWithoutIssues       = 0
            TotalScopes                = 0
            ScopesActive               = 0
            ScopesInactive             = 0
            ScopesWithIssues           = 0
            ScopesWithoutIssues        = 0
            TotalAddresses             = 0
            AddressesInUse             = 0
            AddressesFree              = 0
            OverallPercentageInUse     = 0
        }

        # Initialize empty validation results
        $DHCPSummary.ValidationResults = [ordered] @{
            Summary = [ordered] @{
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

    # Process each DHCP server
    $TotalServers = $ComputerName.Count
    $ProcessedServers = 0
    $ServersWithIssues = 0
    $TotalScopes = 0
    $ScopesWithIssues = 0

    foreach ($Computer in $ComputerName) {
        $ProcessedServers++
        Write-Progress -Activity "Processing DHCP Servers" -Status "Processing $Computer ($ProcessedServers of $TotalServers)" -PercentComplete (($ProcessedServers / $TotalServers) * 100)

        Write-Verbose "Get-WinADDHCPSummary - Processing DHCP server: $Computer"

        # Initialize server object
        $ServerInfo = [ordered] @{
            ServerName           = $Computer
            IsReachable         = $false
            IsADDomainController = $false
            DHCPRole            = 'Unknown'
            Version             = $null
            Status              = 'Unknown'
            ErrorMessage        = $null
            ScopeCount          = 0
            ActiveScopeCount    = 0
            InactiveScopeCount  = 0
            ScopesWithIssues    = 0
            TotalAddresses      = 0
            AddressesInUse      = 0
            AddressesFree       = 0
            PercentageInUse     = 0
            GatheredFrom        = $Computer
            GatheredDate        = Get-Date
        }

        # Check if server is a domain controller
        if ($ForestInformation) {
            $DC = $ForestInformation.ForestDomainControllers | Where-Object { $_.HostName -eq $Computer }
            if ($DC) {
                $ServerInfo.IsADDomainController = $true
                $ServerInfo.DHCPRole = 'Domain Controller'
            }
        }

        # Test connectivity and get server information
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

        foreach ($Scope in $Scopes) {
            Write-Verbose "Get-WinADDHCPSummary - Processing scope $($Scope.ScopeId) on $Computer"

            $ScopeObject = [ordered] @{
                ServerName          = $Computer
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
                if ($Scope.Description -notlike "*lease time*" -and $Scope.Description -notlike "*7d*" -and $Scope.Description -notlike "*day*") {
                    $ScopeObject.Issues.Add("Lease duration exceeds 48 hours ($([Math]::Round($Scope.LeaseDuration.TotalHours, 1)) hours)")
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
                            $PublicDNS = $Option6.Value | Where-Object { $_ -notmatch "^10\." -and $_ -notmatch "^192\.168\." -and $_ -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\." }
                            if ($PublicDNS) {
                                $ScopeObject.Issues.Add("DNS updates enabled with public DNS servers: $($PublicDNS -join ', ')")
                                $ScopeObject.HasIssues = $true
                            }
                        }

                        if (-not $DNSSettings.UpdateDnsRRForOlderClients) {
                            $ScopeObject.Issues.Add("UpdateDnsRRForOlderClients is disabled")
                            $ScopeObject.HasIssues = $true
                        }

                        if (-not $DNSSettings.DeleteDnsRROnLeaseExpiry) {
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
                    ServerName                 = $Computer
                    FileName                   = $Database.FileName
                    BackupPath                 = $Database.BackupPath
                    BackupIntervalMinutes      = $Database.'BackupInterval(m)'
                    CleanupIntervalMinutes     = $Database.'CleanupInterval(m)'
                    LoggingEnabled             = $Database.LoggingEnabled
                    RestoreFromBackup          = $Database.RestoreFromBackup
                    GatheredFrom               = $Computer
                    GatheredDate               = Get-Date
                }
                $DHCPSummary.Databases.Add($DatabaseObject)
            } catch {
                Write-Warning "Get-WinADDHCPSummary - Failed to get database information from $Computer`: $($_.Exception.Message)"
            }
        }

        $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
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
        TotalServers                = $TotalServers
        ServersOnline              = $ServersOnlineCount
        ServersOffline             = $ServersOfflineCount
        ServersWithIssues          = $ServersWithIssues
        ServersWithoutIssues       = $TotalServers - $ServersWithIssues
        TotalScopes                = $TotalScopes
        ScopesActive               = $ScopesActiveCount
        ScopesInactive             = $ScopesInactiveCount
        ScopesWithIssues           = $ScopesWithIssues
        ScopesWithoutIssues        = $TotalScopes - $ScopesWithIssues
        TotalAddresses             = ($DHCPSummary.Servers | Measure-Object -Property TotalAddresses -Sum).Sum
        AddressesInUse             = ($DHCPSummary.Servers | Measure-Object -Property AddressesInUse -Sum).Sum
        AddressesFree              = ($DHCPSummary.Servers | Measure-Object -Property AddressesFree -Sum).Sum
        OverallPercentageInUse     = 0
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
            PublicDNSWithUpdates    = $PublicDNSWithUpdates
            HighUtilization         = $HighUtilization
            ServersOffline          = $ServersOffline
        }
        # Warning issues that should be addressed soon
        WarningIssues = [ordered] @{
            MissingFailover         = $MissingFailover
            ExtendedLeaseDuration   = $ExtendedLeaseDuration
            ModerateUtilization     = $ModerateUtilization
            DNSRecordManagement     = $DNSRecordManagement
        }
        # Information issues that are good to know but not urgent
        InfoIssues = [ordered] @{
            MissingDomainName       = $MissingDomainName
            InactiveScopes          = $InactiveScopes
        }
        # Summary counters for quick overview
        Summary = [ordered] @{
            TotalCriticalIssues     = 0
            TotalWarningIssues      = 0
            TotalInfoIssues         = 0
            ScopesWithCritical      = 0
            ScopesWithWarnings      = 0
            ScopesWithInfo          = 0
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
