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

    .PARAMETER SkipScopeDetails
    When specified, skips collection of scope utilization statistics (Get-DhcpServerv4ScopeStatistics).
    This significantly improves performance by avoiding expensive per-scope statistics calls.
    Scope configuration data (DNS settings, options, failover) will still be collected for validation.

    .PARAMETER Minimal
    When specified, collects only the minimum data required for validation.
    Focuses on lease duration, DNS configuration, and failover validation.
    This mode significantly improves performance by collecting only validation-critical data.

    .PARAMETER IncludeComponents
    Limits what components are gathered. Supported values:
    Servers, Scopes, ScopeStatistics, Failover, IPv6, Multicast, Reservations, Leases, Policies,
    Options, Classes, ServerSettings, NetworkBindings, AuditLogs, Databases, SecurityFilters,
    EnhancedAnalysis, OptionsAnalysis, Validation, TimingStatistics.

    .PARAMETER ExcludeComponents
    Excludes components from being gathered. Same accepted values as IncludeComponents.

    .PARAMETER IncludeServers
    Only analyze these DHCP servers (FQDN or short names). Applied to discovery and detailed processing.

    .PARAMETER ExcludeServers
    Exclude these DHCP servers from discovery/processing.

    .PARAMETER IncludeScopeId
    Only process these IPv4 scope IDs (e.g., 10.10.1.0). Applied per-server after scope discovery.

    .PARAMETER ExcludeScopeId
    Exclude these IPv4 scope IDs from processing.

    .EXAMPLE
    Get-WinADDHCPSummary

    Retrieves DHCP summary information from all DHCP servers in the current forest.

    .EXAMPLE
    Get-WinADDHCPSummary -Forest "example.com" -IncludeComponents Servers,Scopes,ScopeStatistics,Options,Validation

    Gathers a focused dataset (servers, scopes, utilization, options, and validation only) for the forest.

    .EXAMPLE
    Get-WinADDHCPSummary -IncludeServers dhcp01.example.com,dhcp02.example.com -Minimal -IncludeComponents Servers,Scopes,Failover,Validation

    Minimal, fast scan only for two servers; focuses on failover and core validation.

    .EXAMPLE
    Get-WinADDHCPSummary -ComputerName dhcp01.example.com -IncludeScopeId 10.10.1.0,10.10.2.0 -IncludeComponents Scopes,ScopeStatistics,Options,Reservations,Leases,Validation

    Deep-dive only two scope IDs on a specific server with full per-scope details.

    .EXAMPLE
    Get-WinADDHCPSummary -ExcludeComponents IPv6,Options,Classes,ScopeStatistics

    Excludes DHCPv6, options/classes, and scope utilization for a lighter, faster collection.

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
        [switch] $SkipScopeDetails,
        [switch] $TestMode,
        [switch] $Minimal,
        [switch] $ConsiderMissingFailoverCritical,
        [switch] $ConsiderDNSConfigCritical,
        [switch] $IncludeServerAvailabilityIssues,
        # New: Control what we scan/collect
        [ValidateSet('Servers','Scopes','ScopeStatistics','Failover','IPv6','Multicast','Reservations','Leases','Policies','Options','Classes','ServerSettings','NetworkBindings','AuditLogs','Databases','SecurityFilters','EnhancedAnalysis','OptionsAnalysis','Validation','TimingStatistics')]
        [string[]] $IncludeComponents,
        [ValidateSet('Servers','Scopes','ScopeStatistics','Failover','IPv6','Multicast','Reservations','Leases','Policies','Options','Classes','ServerSettings','NetworkBindings','AuditLogs','Databases','SecurityFilters','EnhancedAnalysis','OptionsAnalysis','Validation','TimingStatistics')]
        [string[]] $ExcludeComponents,
        # New: Control which servers/scopes are processed
        [alias('IncludeHost','IncludeDHCPServers')][string[]] $IncludeServers,
        [alias('ExcludeHost','ExcludeDHCPServers')][string[]] $ExcludeServers,
        [alias('IncludeScope','IncludeScopes')][string[]] $IncludeScopeId,
        [alias('ExcludeScope','ExcludeScopes')][string[]] $ExcludeScopeId
    )

    if ($Minimal) {
        Write-Verbose "Get-WinADDHCPSummary - Starting DHCP information gathering (Minimal Mode - Validation Only)"
        # In minimal mode, automatically enable SkipScopeDetails for performance
        # Gathering statistics for millions of addresses would be extremely slow
        $SkipScopeDetails = $true
        Write-Verbose "Get-WinADDHCPSummary - SkipScopeDetails enabled for minimal mode - address statistics not collected for performance"
    } else {
        Write-Verbose "Get-WinADDHCPSummary - Starting DHCP information gathering"
    }

    if ($TestMode) {
        Write-Verbose "Get-WinADDHCPSummary - Running in TEST MODE - using mock data for DHCP operations"
    }

    # Build effective component selection map (defaults depend on Minimal)
    $allComponents = @(
        'Servers','Scopes','ScopeStatistics','Failover','IPv6','Multicast','Reservations','Leases','Policies','Options','Classes','ServerSettings','NetworkBindings','AuditLogs','Databases','SecurityFilters','EnhancedAnalysis','OptionsAnalysis','Validation','TimingStatistics'
    )

    if ($null -eq $IncludeComponents -or $IncludeComponents.Count -eq 0) {
        if ($Minimal) {
            $effectiveComponents = @('Servers','Scopes','Failover','Validation','TimingStatistics')
        } else {
            $effectiveComponents = $allComponents
        }
    } else {
        $effectiveComponents = @($IncludeComponents)
    }
    if ($ExcludeComponents -and $ExcludeComponents.Count -gt 0) {
        $effectiveComponents = @($effectiveComponents | Where-Object { $_ -notin $ExcludeComponents })
    }

    $Components = @{}
    foreach ($c in $allComponents) { $Components[$c] = ($c -in $effectiveComponents) }

    # Initialize result structure
    $DHCPSummary = [ordered] @{
        Servers                   = [System.Collections.Generic.List[Object]]::new()
        Scopes                    = [System.Collections.Generic.List[Object]]::new()
        ScopesWithIssues          = [System.Collections.Generic.List[Object]]::new()
        IPv6Scopes                = [System.Collections.Generic.List[Object]]::new()
        IPv6ScopesWithIssues      = [System.Collections.Generic.List[Object]]::new()
        MulticastScopes           = [System.Collections.Generic.List[Object]]::new()
        Reservations              = [System.Collections.Generic.List[Object]]::new()
        Leases                    = [System.Collections.Generic.List[Object]]::new()
        Policies                  = [System.Collections.Generic.List[Object]]::new()
        SecurityFilters           = [System.Collections.Generic.List[Object]]::new()
        ServerSettings            = [System.Collections.Generic.List[Object]]::new()
        NetworkBindings           = [System.Collections.Generic.List[Object]]::new()
        AuditLogs                 = [System.Collections.Generic.List[Object]]::new()
        Databases                 = [System.Collections.Generic.List[Object]]::new()
        Options                   = [System.Collections.Generic.List[Object]]::new()
        Errors                    = [System.Collections.Generic.List[Object]]::new()
        Warnings                  = [System.Collections.Generic.List[Object]]::new()
        # Enhanced analysis collections
        ScopeConflicts            = [System.Collections.Generic.List[Object]]::new()
        PerformanceMetrics        = [System.Collections.Generic.List[Object]]::new()
        SecurityAnalysis          = [System.Collections.Generic.List[Object]]::new()
        BestPracticeViolations    = [System.Collections.Generic.List[Object]]::new()
        CapacityAnalysis          = [System.Collections.Generic.List[Object]]::new()
        NetworkDesignAnalysis     = [System.Collections.Generic.List[Object]]::new()
        BackupAnalysis            = [System.Collections.Generic.List[Object]]::new()
        ScopeRedundancyAnalysis   = [System.Collections.Generic.List[Object]]::new()
        ServerPerformanceAnalysis = [System.Collections.Generic.List[Object]]::new()
        ServerNetworkAnalysis     = [System.Collections.Generic.List[Object]]::new()
        # New safe, high-value collections
        DHCPOptions               = [System.Collections.Generic.List[Object]]::new()
        DHCPClasses               = [System.Collections.Generic.List[Object]]::new()
        Superscopes               = [System.Collections.Generic.List[Object]]::new()
        FailoverRelationships     = [System.Collections.Generic.List[Object]]::new()
        ServerStatistics          = [System.Collections.Generic.List[Object]]::new()
        OptionsAnalysis           = [System.Collections.Generic.List[Object]]::new()
        Statistics                = [ordered] @{}
        ValidationResults         = [ordered] @{}
        TimingStatistics          = [System.Collections.Generic.List[Object]]::new()
    }

    # Get DHCP servers from AD for discovery
    Write-Verbose "Get-WinADDHCPSummary - Discovering DHCP servers in forest"
    try {
        if ($TestMode) {
            $DHCPServersFromAD = Get-TestModeDHCPData -DataType 'DhcpServersInDC'
        } else {
            $DHCPServersFromAD = Get-DhcpServerInDC -ErrorAction Stop
        }
        Write-Verbose "Get-WinADDHCPSummary - Found $($DHCPServersFromAD.Count) DHCP servers in AD"

        # Apply include/exclude filters to discovered servers if requested
        if ($IncludeServers -and $IncludeServers.Count -gt 0) {
            $set = @{}; foreach ($n in $IncludeServers) { $set[$n.ToLower()] = $true }
            $DHCPServersFromAD = @($DHCPServersFromAD | Where-Object { $set.ContainsKey($_.DnsName.ToLower()) })
            Write-Verbose "Get-WinADDHCPSummary - After IncludeServers filter: $($DHCPServersFromAD.Count) servers"
        }
        if ($ExcludeServers -and $ExcludeServers.Count -gt 0) {
            $setX = @{}; foreach ($n in $ExcludeServers) { $setX[$n.ToLower()] = $true }
            $DHCPServersFromAD = @($DHCPServersFromAD | Where-Object { -not $setX.ContainsKey($_.DnsName.ToLower()) })
            Write-Verbose "Get-WinADDHCPSummary - After ExcludeServers filter: $($DHCPServersFromAD.Count) servers"
        }
    } catch {
        Add-DHCPError -Summary $DHCPSummary -ServerName 'AD Discovery' -Component 'DHCP Server Discovery' -Operation 'Get-DhcpServerInDC' -ErrorMessage $_.Exception.Message -Severity 'Error'
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
        if ($IncludeServers -and $IncludeServers.Count -gt 0) {
            $ServersToAnalyze = @($ServersToAnalyze | Where-Object { $_ -in $IncludeServers })
        }
        if ($ExcludeServers -and $ExcludeServers.Count -gt 0) {
            $ServersToAnalyze = @($ServersToAnalyze | Where-Object { $_ -notin $ExcludeServers })
        }
        Write-Verbose "Get-WinADDHCPSummary - Will perform detailed analysis on $($ServersToAnalyze.Count) specified servers"
    }

    # Create lookup for servers to analyze
    $ServersToAnalyzeSet = @{}
    foreach ($Server in $ServersToAnalyze) {
        $ServersToAnalyzeSet[$Server.ToLower()] = $true
    }

    if ($DHCPServersFromAD.Count -eq 0) {
        Add-DHCPError -Summary $DHCPSummary -ServerName 'AD Discovery' -Component 'DHCP Server Discovery' -Operation 'Server Count Check' -ErrorMessage 'No DHCP servers found in Active Directory' -Severity 'Warning'

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
            Summary     = [ordered] @{
                TotalCriticalIssues    = 0
                TotalUtilizationIssues = 0
                TotalWarningIssues     = 0
                TotalInfoIssues        = 0
                ScopesWithCritical     = 0
                ScopesWithUtilization  = 0
                ScopesWithWarnings     = 0
                ScopesWithInfo         = 0
            }
            Critical    = @()
            Utilization = @()
            Warning     = @()
            Info        = @()
        }

        return $DHCPSummary
    }

    # Get forest information for cross-referencing
    $ForestInformation = $null
    if ($Forest -or $IncludeDomains -or $ExcludeDomains -or $IncludeDomainControllers -or $ExcludeDomainControllers) {
        try {
            $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
        } catch {
            Add-DHCPError -Summary $DHCPSummary -ServerName 'Forest Information' -Component 'Forest Discovery' -Operation 'Get-WinADForestDetails' -ErrorMessage $_.Exception.Message -Severity 'Warning'
        }
    }

    # Process each DHCP server (all discovered servers)
    $TotalServers = $DHCPServersFromAD.Count
    $ProcessedServers = 0
    $ServersWithIssues = 0
    $TotalScopes = 0
    $ScopesWithIssues = 0

    # Track overall timing
    $OverallStartTime = Get-Date

    # Collect failover relationships upfront for all servers (once)
    $FailoverByServer = @{}
    if ($Components['Failover']) {
        foreach ($s in $DHCPServersFromAD) {
            Get-WinADDHCPFailoverRelationships -Computer $s.DnsName -DHCPSummary $DHCPSummary -TestMode:$TestMode
        }
        # Index failover relationships by server for fast lookup
        foreach ($rel in $DHCPSummary.FailoverRelationships) {
            if (-not $rel) { continue }
            $key = $rel.ServerName.ToLower()
            if (-not $FailoverByServer.ContainsKey($key)) {
                $FailoverByServer[$key] = New-Object System.Collections.Generic.List[object]
            }
            [void] $FailoverByServer[$key].Add($rel)
        }
    }

    foreach ($DHCPServer in $DHCPServersFromAD) {
        $Computer = $DHCPServer.DnsName
        $ProcessedServers++
        Write-Progress -Activity "Processing DHCP Servers" -Status "Processing $Computer ($ProcessedServers of $TotalServers)" -PercentComplete (($ProcessedServers / $TotalServers) * 100) -Id 1

        Write-Verbose "Get-WinADDHCPSummary - Processing DHCP server: $Computer"

        # Start server timing
        $ServerStartTime = Get-Date

        # Determine if this server should be analyzed in detail
        $ShouldAnalyze = $ServersToAnalyzeSet[$Computer.ToLower()] -eq $true

        # Reset per-server failover map
        $ServerFailoverMap = $null

        # Test connectivity and get server information only for servers to analyze
        if ($ShouldAnalyze) {
            # Get server validation info
            $ServerInfo = Get-WinADDHCPServerValidation -Computer $Computer -ForestInformation $ForestInformation -DHCPSummaryServers $DHCPSummary.Servers -TestMode:$TestMode

            # If DHCP service is not responding, mark as having issues and continue to next server
            if (-not $ServerInfo.DHCPResponding) {
                Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'DHCP Service Validation' -Operation 'Service Connectivity Test' -ErrorMessage "DHCP service not responding: $($ServerInfo.ErrorMessage)" -Severity 'Error'
                $ServersWithIssues++
                $DHCPSummary.Servers.Add($ServerInfo)
                continue
            }
        } else {
            # For non-analyzed servers, create basic server info
            $ServerInfo = [ordered] @{
                ServerName           = $Computer
                IsReachable          = $false
                PingSuccessful       = $null
                DNSResolvable        = $null
                DHCPResponding       = $null
                IsADDomainController = $false
                DHCPRole             = 'Unknown'
                Version              = $null
                Status               = 'Not Analyzed'
                ErrorMessage         = 'Server discovered but not selected for detailed analysis'
                IPAddress            = $null
                ResponseTimeMs       = $null
                ReverseDNSName       = $null
                ReverseDNSValid      = $null
                ScopeCount           = 0
                ActiveScopeCount     = 0
                InactiveScopeCount   = 0
                ScopesWithIssues     = 0
                TotalAddresses       = 0
                AddressesInUse       = 0
                AddressesFree        = 0
                PercentageInUse      = 0
                IsAuthorized         = $null
                AuthorizationStatus  = 'Unknown'
                Issues               = [System.Collections.Generic.List[string]]::new()
                HasIssues            = $false
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

            $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
            continue
        }

        # Get DHCP scopes (if requested)
        $Scopes = @()
        $ScopeCollectionStart = Get-Date
        if ($Components['Scopes']) {
            try {
                if ($TestMode) {
                    $Scopes = Get-TestModeDHCPData -DataType 'DhcpServerv4Scope' -ComputerName $Computer
                } else {
                    $Scopes = Get-DhcpServerv4Scope -ComputerName $Computer -ErrorAction Stop
                }
                # Apply Include/Exclude scope filters if provided
                if ($IncludeScopeId -and $IncludeScopeId.Count -gt 0) {
                    $setS = @{}; foreach ($sid in $IncludeScopeId) { $setS[[string]$sid] = $true }
                    $Scopes = @($Scopes | Where-Object { $setS.ContainsKey([string]$_.ScopeId) })
                }
                if ($ExcludeScopeId -and $ExcludeScopeId.Count -gt 0) {
                    $setSX = @{}; foreach ($sid in $ExcludeScopeId) { $setSX[[string]$sid] = $true }
                    $Scopes = @($Scopes | Where-Object { -not $setSX.ContainsKey([string]$_.ScopeId) })
                }

                $ScopeCount = if ($Scopes) { $Scopes.Count } else { 0 }

                # Debug: Check TimingStatistics state
                Write-Verbose "Get-WinADDHCPSummary - TimingStatistics type: $($DHCPSummary.TimingStatistics.GetType().FullName), Count: $($DHCPSummary.TimingStatistics.Count)"

                # Ensure TimingStatistics is properly initialized before adding timing info
                if ($null -eq $DHCPSummary.TimingStatistics) {
                    Write-Verbose "Get-WinADDHCPSummary - Reinitializing TimingStatistics for $Computer"
                    $DHCPSummary.TimingStatistics = [System.Collections.Generic.List[Object]]::new()
                }

                Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName $Computer -Operation 'Scope Discovery' -StartTime $ScopeCollectionStart -ItemCount $ScopeCount
                $ServerInfo.ScopeCount = $ScopeCount
                $TotalScopes += $ScopeCount

                $ActiveScopes = $Scopes | Where-Object { $_.State -eq 'Active' }
                $ServerInfo.ActiveScopeCount = if ($ActiveScopes) { $ActiveScopes.Count } else { 0 }
                $ServerInfo.InactiveScopeCount = $ScopeCount - $ServerInfo.ActiveScopeCount

                Write-Verbose "Get-WinADDHCPSummary - Found $ScopeCount scopes on $Computer"
            } catch {
                # Debug: Check TimingStatistics state in catch block
                Write-Verbose "Get-WinADDHCPSummary - (Error branch) TimingStatistics type: $($DHCPSummary.TimingStatistics.GetType().FullName), Count: $($DHCPSummary.TimingStatistics.Count)"

                # Ensure TimingStatistics is properly initialized before adding timing info
                if ($null -eq $DHCPSummary.TimingStatistics) {
                    Write-Verbose "Get-WinADDHCPSummary - (Error branch) Reinitializing TimingStatistics for $Computer"
                    $DHCPSummary.TimingStatistics = [System.Collections.Generic.List[Object]]::new()
                }

                Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName $Computer -Operation 'Scope Discovery' -StartTime $ScopeCollectionStart -ItemCount 0 -Success $false
                Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'DHCP Scope Discovery' -Operation 'Get-DhcpServerv4Scope' -ErrorMessage $_.Exception.Message -Severity 'Error'
                $ServerInfo.ErrorMessage = $_.Exception.Message
                $ServersWithIssues++
                $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
                continue
            }
        } else {
            $ServerInfo.ScopeCount = 0
            $ServerInfo.ActiveScopeCount = 0
            $ServerInfo.InactiveScopeCount = 0
        }

        # Process all scopes for configuration validation (always)
        # Only skip expensive statistics collection when SkipScopeDetails is enabled
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

        # Build failover map once per server (collect relationships, then map ScopeId->Partner)
        if (-not $ServerFailoverMap -and $Components['Failover']) {
            $ServerFailoverMap = @{}
            $key = $Computer.ToLower()
            if ($FailoverByServer.ContainsKey($key)) {
                foreach ($rel in $FailoverByServer[$key]) {
                    $scopeList = if ($rel.ScopeId -is [Array]) { $rel.ScopeId } else { @($rel.ScopeId) }
                    foreach ($sid in $scopeList) { if ($sid) { $ServerFailoverMap[[string]$sid] = $rel.PartnerServer } }
                }
            }
        }

        # Get scope configuration
        $ScopeObject = Get-WinADDHCPScopeConfiguration -Computer $Computer -Scope $Scope -DHCPSummaryErrors $DHCPSummary.Errors -TestMode:$TestMode -ServerFailoverMap $ServerFailoverMap

            # Get scope statistics
            $localSkip = $SkipScopeDetails -or (-not $Components['ScopeStatistics'])
            $ScopeStats = Get-WinADDHCPScopeStatistics -Computer $Computer -Scope $Scope -ScopeObject $ScopeObject -DHCPSummaryTimingStatistics $DHCPSummary.TimingStatistics -DHCPSummaryErrors $DHCPSummary.Errors -SkipScopeDetails:$localSkip -TestMode:$TestMode
            $ServerTotalAddresses += $ScopeStats.TotalAddresses
            $ServerAddressesInUse += $ScopeStats.AddressesInUse
            $ServerAddressesFree += $ScopeStats.AddressesFree

            # Validate scope configuration
            $HasIssues = Get-WinADDHCPScopeValidation -Scope $Scope -ScopeObject $ScopeObject
            if ($HasIssues) {
                $ScopeObject.HasIssues = $true
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

        # Add the successfully processed server to the collection
        $DHCPSummary.Servers.Add($ServerInfo)

        # Track server processing time
        Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName $Computer -Operation 'Server Total Processing' -StartTime $ServerStartTime -ItemCount $ServerInfo.ScopeCount

        Write-Verbose "Get-WinADDHCPSummary - Server $Computer processing completed: Scopes=$($ServerInfo.ScopeCount), Total Addresses=$($ServerInfo.TotalAddresses), Utilization=$($ServerInfo.PercentageInUse)%"

        # Get extended server-level information (skip in minimal mode)
        if (-not $Minimal) {
            # Only collect if any of the extended server components are requested
            if ($Components['AuditLogs'] -or $Components['Databases'] -or $Components['Options'] -or $Components['Classes'] -or $Components['ServerSettings'] -or $Components['NetworkBindings'] -or $Components['SecurityFilters'] -or $Components['IPv6'] -or $Components['Multicast']) {
                Get-WinADDHCPExtendedServerData -Computer $Computer -DHCPSummary $DHCPSummary -TestMode:$TestMode -Components $Components
            }
        }

        # Get scope-intensive extended information (only when scope details are not skipped and not in minimal mode)
        if (-not $SkipScopeDetails -and -not $Minimal) {
            if ($Components['Reservations'] -or $Components['Leases'] -or $Components['Options']) {
                Get-WinADDHCPExtendedScopeData -Computer $Computer -Scopes $Scopes -DHCPSummary $DHCPSummary -TestMode:$TestMode -Components $Components
            }
        }
    }

    # Analyze failover coverage and mismatches before computing validation results
    if ($Components['Failover']) {
        Get-WinADDHCPFailoverAnalysis -DHCPSummary $DHCPSummary
    }

    # Calculate overall statistics
    $DHCPSummary.Statistics = Get-WinADDHCPStatistics -DHCPSummary $DHCPSummary -TotalServers $TotalServers -ServersWithIssues $ServersWithIssues -TotalScopes $TotalScopes -ScopesWithIssues $ScopesWithIssues -SkipScopeDetails:$SkipScopeDetails

    # Categorize validation results (or keep an empty structure if excluded)
    if ($Components['Validation']) {
        $DHCPSummary.ValidationResults = Get-WinADDHCPValidationResults -DHCPSummary $DHCPSummary -SkipScopeDetails:$SkipScopeDetails -ConsiderMissingFailoverCritical:$ConsiderMissingFailoverCritical -ConsiderDNSConfigCritical:$ConsiderDNSConfigCritical -IncludeServerAvailabilityIssues:$IncludeServerAvailabilityIssues
    } else {
        $DHCPSummary.ValidationResults = [ordered] @{
            Summary     = [ordered] @{
                TotalCriticalIssues    = 0
                TotalUtilizationIssues = 0
                TotalWarningIssues     = 0
                TotalInfoIssues        = 0
                ScopesWithCritical     = 0
                ScopesWithUtilization  = 0
                ScopesWithWarnings     = 0
                ScopesWithInfo         = 0
            }
            CriticalIssues    = [ordered]@{}
            UtilizationIssues = [ordered]@{}
            WarningIssues     = [ordered]@{}
            InfoIssues        = [ordered]@{}
        }
    }

    # Enhanced Analysis (skip in minimal mode)
    if (-not $Minimal) {
        if ($Components['EnhancedAnalysis']) {
            Get-WinADDHCPEnhancedAnalysis -DHCPSummary $DHCPSummary
        } elseif ($Components['OptionsAnalysis']) {
            # Run only options analysis if requested explicitly
            Get-WinADDHCPOptionsAnalysis -DHCPSummary $DHCPSummary
        }
    }

    Write-Progress -Activity "Processing DHCP Servers" -Completed

    # Add overall timing summary with safety checks
    if ($OverallStartTime -and $DHCPSummary.TimingStatistics) {
        try {
            Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName 'Overall' -Operation 'Complete DHCP Discovery' -StartTime $OverallStartTime -ItemCount $ProcessedServers
        } catch {
            Write-Warning "Get-WinADDHCPSummary - Failed to add final timing statistic: $($_.Exception.Message)"
        }
    }

    Write-Verbose "Get-WinADDHCPSummary - DHCP information gathering completed"

    return $DHCPSummary
}
