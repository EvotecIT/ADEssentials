function Get-WinADDHCPValidationResults {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary,
        [switch] $SkipScopeDetails,
        [switch] $ConsiderMissingFailoverCritical,
        [switch] $ConsiderDNSConfigCritical,
        [switch] $IncludeServerAvailabilityIssues
    )

    Write-Verbose "Get-WinADDHCPValidationResults - Categorizing validation results"

    # Initialize validation collections
    $PublicDNSWithUpdates = [System.Collections.Generic.List[Object]]::new()
    $HighUtilization = [System.Collections.Generic.List[Object]]::new()
    $ServersOffline = [System.Collections.Generic.List[Object]]::new()
    $ServersDNSFailed = [System.Collections.Generic.List[Object]]::new()
    $ServersPingFailed = [System.Collections.Generic.List[Object]]::new()
    $ServersDHCPNotResponding = [System.Collections.Generic.List[Object]]::new()
    $MissingFailover = [System.Collections.Generic.List[Object]]::new()
    $FailoverOnlyOnPrimary = [System.Collections.Generic.List[Object]]::new()
    $FailoverOnlyOnSecondary = [System.Collections.Generic.List[Object]]::new()
    $FailoverMissingOnBoth = [System.Collections.Generic.List[Object]]::new()
    $ExtendedLeaseDuration = [System.Collections.Generic.List[Object]]::new()
    $ModerateUtilization = [System.Collections.Generic.List[Object]]::new()
    $DNSRecordManagement = [System.Collections.Generic.List[Object]]::new()
    $MissingDomainName = [System.Collections.Generic.List[Object]]::new()
    $InactiveScopes = [System.Collections.Generic.List[Object]]::new()

    # Server availability categorization
    foreach ($Server in $DHCPSummary.Servers) {
        switch ($Server.Status) {
            'DNS resolution failed'             { $ServersDNSFailed.Add($Server) }
            'DNS OK but unreachable'            { $ServersPingFailed.Add($Server) }
            'Reachable but DHCP not responding' { $ServersDHCPNotResponding.Add($Server) }
        }
    }
    if ($IncludeServerAvailabilityIssues) {
        foreach ($s in $ServersDNSFailed) { $ServersOffline.Add($s) }
        foreach ($s in $ServersPingFailed) { $ServersOffline.Add($s) }
        foreach ($s in $ServersDHCPNotResponding) { $ServersOffline.Add($s) }
    }

    # Scope issues categorization
    foreach ($Scope in $DHCPSummary.ScopesWithIssues) {
        foreach ($Issue in $Scope.Issues) {
            if ($Issue -like "*public DNS servers*" -or $Issue -like "*non-private DNS servers*") {
                if ($PublicDNSWithUpdates -notcontains $Scope) { $PublicDNSWithUpdates.Add($Scope) }
            }
            if ($Issue -like "*Failover not configured*") {
                if ($MissingFailover -notcontains $Scope) { $MissingFailover.Add($Scope) }
            }
            if ($Issue -like "*exceeds 48 hours*") {
                if ($ExtendedLeaseDuration -notcontains $Scope) { $ExtendedLeaseDuration.Add($Scope) }
            }
            if ($Issue -like "*UpdateDnsRRForOlderClients*" -or $Issue -like "*DeleteDnsRROnLeaseExpiry*") {
                if ($DNSRecordManagement -notcontains $Scope) { $DNSRecordManagement.Add($Scope) }
            }
            if ($Issue -like "*Domain name option*") {
                if ($MissingDomainName -notcontains $Scope) { $MissingDomainName.Add($Scope) }
            }
        }
    }

    # Failover mismatches from precomputed analysis
    if ($DHCPSummary.FailoverAnalysis) {
        if ($DHCPSummary.FailoverAnalysis.OnlyOnPrimary)   { foreach ($i in $DHCPSummary.FailoverAnalysis.OnlyOnPrimary)   { $FailoverOnlyOnPrimary.Add($i) } }
        if ($DHCPSummary.FailoverAnalysis.OnlyOnSecondary) { foreach ($i in $DHCPSummary.FailoverAnalysis.OnlyOnSecondary) { $FailoverOnlyOnSecondary.Add($i) } }
        if ($DHCPSummary.FailoverAnalysis.MissingOnBoth)   { foreach ($i in $DHCPSummary.FailoverAnalysis.MissingOnBoth)   { $FailoverMissingOnBoth.Add($i) } }
    }

    # Inactive scopes
    foreach ($Scope in $DHCPSummary.Scopes) { if ($Scope.State -eq 'Inactive') { $InactiveScopes.Add($Scope) } }

    # Utilization checks
    if (-not $SkipScopeDetails) {
        foreach ($Scope in $DHCPSummary.Scopes) {
            if ($Scope.State -eq 'Active') {
                if ($Scope.PercentageInUse -gt 90) { $HighUtilization.Add($Scope) }
                elseif ($Scope.PercentageInUse -gt 75) { $ModerateUtilization.Add($Scope) }
            }
        }
    } else {
        Write-Verbose "Get-WinADDHCPValidationResults - Utilization validations skipped due to SkipScopeDetails parameter"
    }

    # Build result structure
    $ValidationResults = [ordered] @{
        CriticalIssues    = [ordered] @{
            PublicDNSWithUpdates     = $PublicDNSWithUpdates
            DNSConfigurationProblems = @()
            ServersOffline           = $ServersOffline
            ServersDNSFailed         = $ServersDNSFailed
            ServersPingFailed        = $ServersPingFailed
            ServersDHCPNotResponding = $ServersDHCPNotResponding
            # Reclassified failover risks per request
            FailoverOnlyOnPrimary    = $FailoverOnlyOnPrimary      # "missing on secondary" => critical
            FailoverMissingOnBoth    = $FailoverMissingOnBoth      # "missing on both" => critical
        }
        UtilizationIssues = [ordered] @{
            HighUtilization     = $HighUtilization
            ModerateUtilization = $ModerateUtilization
        }
        WarningIssues     = [ordered] @{
            MissingFailover         = $MissingFailover
            # Keep as warning: "missing on primary" => present only on secondary
            FailoverOnlyOnSecondary = $FailoverOnlyOnSecondary
            ExtendedLeaseDuration   = $ExtendedLeaseDuration
            DNSRecordManagement     = $DNSRecordManagement
        }
        InfoIssues        = [ordered] @{
            MissingDomainName = $MissingDomainName
            InactiveScopes    = $InactiveScopes
        }
        Summary           = [ordered] @{
            TotalCriticalIssues    = 0
            TotalUtilizationIssues = 0
            TotalWarningIssues     = 0
            TotalInfoIssues        = 0
            ScopesWithCritical     = 0
            ScopesWithUtilization  = 0
            ScopesWithWarnings     = 0
            ScopesWithInfo         = 0
        }
    }

    # Escalate DNS config issues to critical when requested (readable & efficient)
    if ($ConsiderDNSConfigCritical) {
        # Aggregate
        $dnsAgg = New-Object 'System.Collections.Generic.List[object]'
        if ($PublicDNSWithUpdates -and $PublicDNSWithUpdates.Count -gt 0) { [void] $dnsAgg.AddRange($PublicDNSWithUpdates) }
        if ($DNSRecordManagement   -and $DNSRecordManagement.Count   -gt 0) { [void] $dnsAgg.AddRange($DNSRecordManagement) }
        if ($MissingDomainName     -and $MissingDomainName.Count     -gt 0) { [void] $dnsAgg.AddRange($MissingDomainName) }

        # Deduplicate by (ServerName|ScopeId)
        $seen = @{}
        $dnsUnique = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in $dnsAgg) {
            $id = "$($item.ServerName)|$($item.ScopeId)"
            if (-not $seen.ContainsKey($id)) {
                $seen[$id] = $true
                [void] $dnsUnique.Add($item)
            }
        }

        $ValidationResults.CriticalIssues.DNSConfigurationProblems = $dnsUnique
        # Prevent double-counting when summarizing
        $DNSRecordManagement = [System.Collections.Generic.List[Object]]::new()
        $MissingDomainName   = [System.Collections.Generic.List[Object]]::new()
    }

    # Counters
    $ValidationResults.Summary.TotalCriticalIssues = (
        $ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count +
        $ValidationResults.CriticalIssues.DNSConfigurationProblems.Count +
        $ValidationResults.CriticalIssues.ServersOffline.Count +
        $ValidationResults.CriticalIssues.FailoverOnlyOnPrimary.Count +
        $ValidationResults.CriticalIssues.FailoverMissingOnBoth.Count +
        $(if ($ConsiderMissingFailoverCritical) { $MissingFailover.Count } else { 0 })
    )

    $ValidationResults.Summary.TotalUtilizationIssues = ($HighUtilization.Count + $ModerateUtilization.Count)

    $ValidationResults.Summary.TotalWarningIssues = (
        $(if ($ConsiderMissingFailoverCritical) { 0 } else { $MissingFailover.Count }) +
        $FailoverOnlyOnSecondary.Count +
        $ExtendedLeaseDuration.Count +
        $DNSRecordManagement.Count
    )

    $ValidationResults.Summary.TotalInfoIssues = ($MissingDomainName.Count + $InactiveScopes.Count)

    # Unique scope counters
    $CriticalScopes = @(
        $ValidationResults.CriticalIssues.PublicDNSWithUpdates;
        $ValidationResults.CriticalIssues.DNSConfigurationProblems;
        $ValidationResults.CriticalIssues.FailoverOnlyOnPrimary;
        $ValidationResults.CriticalIssues.FailoverMissingOnBoth
    )
    $ValidationResults.Summary.ScopesWithCritical = ($CriticalScopes | Sort-Object -Property ScopeId -Unique).Count

    $UtilizationScopes = @($HighUtilization; $ModerateUtilization)
    $ValidationResults.Summary.ScopesWithUtilization = ($UtilizationScopes | Sort-Object -Property ScopeId -Unique).Count

    $WarningScopes = @(
        $(if ($ConsiderMissingFailoverCritical) { @() } else { $MissingFailover })
        $FailoverOnlyOnSecondary
        $ExtendedLeaseDuration
        $DNSRecordManagement
    )
    $ValidationResults.Summary.ScopesWithWarnings = ($WarningScopes | Sort-Object -Property ScopeId -Unique).Count

    $InfoScopes = @($MissingDomainName; $InactiveScopes)
    $ValidationResults.Summary.ScopesWithInfo = ($InfoScopes | Sort-Object -Property ScopeId -Unique).Count

    return $ValidationResults
}
