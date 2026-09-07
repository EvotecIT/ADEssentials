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
    $FailoverMissingOnOnePartner = [System.Collections.Generic.List[Object]]::new()
    $FailoverMissingOnBoth = [System.Collections.Generic.List[Object]]::new()
    $FailoverUnverified = [System.Collections.Generic.List[Object]]::new()
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
            if ($Issue -like "*UpdateDnsRRForOlderClients*" -or $Issue -like "*DeleteDnsRROnLeaseExpiry*" -or $Issue -like "*DisableDnsPtrRRUpdate*" -or $Issue -like "*PTR registration disabled*") {
                if ($DNSRecordManagement -notcontains $Scope) { $DNSRecordManagement.Add($Scope) }
            }
            if ($Issue -like "*Domain name option*") {
                if ($MissingDomainName -notcontains $Scope) { $MissingDomainName.Add($Scope) }
            }
        }
    }

    # Failover mismatches from precomputed analysis
    if ($DHCPSummary.FailoverAnalysis) {
        $onlyOnPartnerA = if ($DHCPSummary.FailoverAnalysis.Contains('OnlyOnPartnerA')) { $DHCPSummary.FailoverAnalysis.OnlyOnPartnerA } else { $DHCPSummary.FailoverAnalysis.OnlyOnPrimary }
        $onlyOnPartnerB = if ($DHCPSummary.FailoverAnalysis.Contains('OnlyOnPartnerB')) { $DHCPSummary.FailoverAnalysis.OnlyOnPartnerB } else { $DHCPSummary.FailoverAnalysis.OnlyOnSecondary }
        if ($onlyOnPartnerA) {
            foreach ($i in $onlyOnPartnerA) {
                $FailoverMissingOnOnePartner.Add($i)
            }
        }
        if ($onlyOnPartnerB) {
            foreach ($i in $onlyOnPartnerB) {
                $FailoverMissingOnOnePartner.Add($i)
            }
        }
        if ($DHCPSummary.FailoverAnalysis.MissingOnBoth)   { foreach ($i in $DHCPSummary.FailoverAnalysis.MissingOnBoth)   { $FailoverMissingOnBoth.Add($i) } }
        if ($DHCPSummary.FailoverAnalysis.UnverifiedScopes) {
            foreach ($i in $DHCPSummary.FailoverAnalysis.UnverifiedScopes) {
                $partners = @($i.PartnerA, $i.PartnerB) | Where-Object { $_ } | ForEach-Object {
                    Resolve-DHCPServerName -Name $_ -DHCPSummary $DHCPSummary
                }
                $matchingScopes = @($DHCPSummary.Scopes | Where-Object {
                    if ([string]$_.ScopeId -ne [string]$i.ScopeId) { return $false }
                    $scopeServer = Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPSummary
                    return ($partners.Count -eq 0 -or $scopeServer -in $partners)
                })
                if ($matchingScopes.Count -gt 0 -and @($matchingScopes | Where-Object State -eq 'Active').Count -eq 0) {
                    continue
                }
                $FailoverUnverified.Add($i)
            }
        }
    }

    # Canonical pair evidence is more specific than the per-server symptom.
    # Suppress duplicate "not configured" rows for scopes already classified
    # as missing from one or both partner relationship lists.
    $CanonicalFailoverScopeKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($item in @($FailoverMissingOnOnePartner; $FailoverMissingOnBoth; $FailoverUnverified)) {
        foreach ($partner in @($item.PartnerA, $item.PartnerB)) {
            $canonicalPartner = Resolve-DHCPServerName -Name $partner -DHCPSummary $DHCPSummary
            if ($canonicalPartner) {
                $null = $CanonicalFailoverScopeKeys.Add("$canonicalPartner|$($item.ScopeId)")
            }
        }
    }
    if ($CanonicalFailoverScopeKeys.Count -gt 0) {
        $UnpairedMissingFailover = [System.Collections.Generic.List[Object]]::new()
        foreach ($item in $MissingFailover) {
            $canonicalServer = Resolve-DHCPServerName -Name $item.ServerName -DHCPSummary $DHCPSummary
            if (-not $CanonicalFailoverScopeKeys.Contains("$canonicalServer|$($item.ScopeId)")) {
                $UnpairedMissingFailover.Add($item)
            }
        }
        $MissingFailover = $UnpairedMissingFailover
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

    # Apply severity policies to the evidence itself before exposing any buckets.
    # This keeps the rendered rows, totals, and unique-scope counts in agreement.
    $CriticalMissingFailover = [System.Collections.Generic.List[Object]]::new()
    $WarningMissingFailover = [System.Collections.Generic.List[Object]]::new()
    if ($ConsiderMissingFailoverCritical) {
        foreach ($item in $MissingFailover) { $CriticalMissingFailover.Add($item) }
    } else {
        foreach ($item in $MissingFailover) { $WarningMissingFailover.Add($item) }
    }

    $CriticalDNSConfigurationProblems = [System.Collections.Generic.List[Object]]::new()
    $WarningDNSRecordManagement = [System.Collections.Generic.List[Object]]::new()
    $InfoMissingDomainName = [System.Collections.Generic.List[Object]]::new()
    if ($ConsiderDNSConfigCritical) {
        $seenDNSScopes = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($item in @($DNSRecordManagement; $MissingDomainName)) {
            $id = "$($item.ServerName)|$($item.ScopeId)"
            if ($seenDNSScopes.Add($id)) {
                $CriticalDNSConfigurationProblems.Add($item)
            }
        }
    } else {
        foreach ($item in $DNSRecordManagement) { $WarningDNSRecordManagement.Add($item) }
        foreach ($item in $MissingDomainName) { $InfoMissingDomainName.Add($item) }
    }

    # Build result structure
    $ValidationResults = [ordered] @{
        CriticalIssues    = [ordered] @{
            PublicDNSWithUpdates     = $PublicDNSWithUpdates
            DNSConfigurationProblems = $CriticalDNSConfigurationProblems
            ServersOffline           = $ServersOffline
            ServersDNSFailed         = $ServersDNSFailed
            ServersPingFailed        = $ServersPingFailed
            ServersDHCPNotResponding = $ServersDHCPNotResponding
            MissingFailover           = $CriticalMissingFailover
            FailoverMissingOnOnePartner = $FailoverMissingOnOnePartner
            FailoverMissingOnBoth       = $FailoverMissingOnBoth
        }
        UtilizationIssues = [ordered] @{
            HighUtilization     = $HighUtilization
            ModerateUtilization = $ModerateUtilization
        }
        WarningIssues     = [ordered] @{
            MissingFailover       = $WarningMissingFailover
            FailoverUnverified    = $FailoverUnverified
            ExtendedLeaseDuration = $ExtendedLeaseDuration
            DNSRecordManagement   = $WarningDNSRecordManagement
        }
        InfoIssues        = [ordered] @{
            MissingDomainName = $InfoMissingDomainName
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
            UniqueScopesWithIssues = 0
        }
    }

    # Counters
    $ValidationResults.Summary.TotalCriticalIssues = (
        $ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count +
        $ValidationResults.CriticalIssues.DNSConfigurationProblems.Count +
        $ValidationResults.CriticalIssues.ServersOffline.Count +
        $ValidationResults.CriticalIssues.MissingFailover.Count +
        $ValidationResults.CriticalIssues.FailoverMissingOnOnePartner.Count +
        $ValidationResults.CriticalIssues.FailoverMissingOnBoth.Count
    )

    $ValidationResults.Summary.TotalUtilizationIssues = ($HighUtilization.Count + $ModerateUtilization.Count)

    $ValidationResults.Summary.TotalWarningIssues = (
        $ValidationResults.WarningIssues.MissingFailover.Count +
        $ValidationResults.WarningIssues.FailoverUnverified.Count +
        $ExtendedLeaseDuration.Count +
        $ValidationResults.WarningIssues.DNSRecordManagement.Count
    )

    $ValidationResults.Summary.TotalInfoIssues = ($ValidationResults.InfoIssues.MissingDomainName.Count + $InactiveScopes.Count)

    # Unique scope counters
    $CriticalScopes = @(
        $ValidationResults.CriticalIssues.PublicDNSWithUpdates;
        $ValidationResults.CriticalIssues.DNSConfigurationProblems;
        $ValidationResults.CriticalIssues.MissingFailover;
        $ValidationResults.CriticalIssues.FailoverMissingOnOnePartner;
        $ValidationResults.CriticalIssues.FailoverMissingOnBoth
    )
    $ValidationResults.Summary.ScopesWithCritical = @($CriticalScopes | Sort-Object -Property ScopeId -Unique).Count

    $UtilizationScopes = @($HighUtilization; $ModerateUtilization)
    $ValidationResults.Summary.ScopesWithUtilization = @($UtilizationScopes | Sort-Object -Property ScopeId -Unique).Count

    $WarningScopes = @(
        $ValidationResults.WarningIssues.MissingFailover
        $ValidationResults.WarningIssues.FailoverUnverified
        $ExtendedLeaseDuration
        $ValidationResults.WarningIssues.DNSRecordManagement
    )
    $ValidationResults.Summary.ScopesWithWarnings = @($WarningScopes | Sort-Object -Property ScopeId -Unique).Count

    $InfoScopes = @($ValidationResults.InfoIssues.MissingDomainName; $InactiveScopes)
    $ValidationResults.Summary.ScopesWithInfo = @($InfoScopes | Sort-Object -Property ScopeId -Unique).Count

    $AllIssueScopes = @($CriticalScopes; $UtilizationScopes; $WarningScopes; $InfoScopes)
    $ValidationResults.Summary.UniqueScopesWithIssues = @($AllIssueScopes | Where-Object ScopeId | Sort-Object -Property ScopeId -Unique).Count

    return $ValidationResults
}
