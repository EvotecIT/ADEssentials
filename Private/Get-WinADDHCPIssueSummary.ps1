function Get-WinADDHCPIssueSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $DHCPSummary
    )

    $v = $DHCPSummary.ValidationResults

    $countsCritical = [ordered]@{
        PublicDNSWithUpdates     = @($v.CriticalIssues.PublicDNSWithUpdates).Count
        DNSConfigurationProblems = @($v.CriticalIssues.DNSConfigurationProblems).Count
        ServersOffline           = @($v.CriticalIssues.ServersOffline).Count
        FailoverOnlyOnPrimary    = @($v.CriticalIssues.FailoverOnlyOnPrimary).Count
        FailoverMissingOnBoth    = @($v.CriticalIssues.FailoverMissingOnBoth).Count
    }
    $countsWarning = [ordered]@{
        MissingFailover         = @($v.WarningIssues.MissingFailover).Count
        FailoverOnlyOnSecondary = @($v.WarningIssues.FailoverOnlyOnSecondary).Count
        ExtendedLeaseDuration   = @($v.WarningIssues.ExtendedLeaseDuration).Count
        DNSRecordManagement     = @($v.WarningIssues.DNSRecordManagement).Count
    }
    $countsInfo = [ordered]@{
        MissingDomainName = @($v.InfoIssues.MissingDomainName).Count
        InactiveScopes    = @($v.InfoIssues.InactiveScopes).Count
    }
    $countsUtil = [ordered]@{
        HighUtilization     = @($v.UtilizationIssues.HighUtilization).Count
        ModerateUtilization = @($v.UtilizationIssues.ModerateUtilization).Count
    }

    $totalIssueInstances = 0
    foreach ($x in @($countsCritical.Values + $countsWarning.Values + $countsInfo.Values + $countsUtil.Values)) {
        $totalIssueInstances += [int]$x
    }

    $summary = [ordered]@{
        TotalCriticalIssues                = $v.Summary.TotalCriticalIssues
        TotalWarningIssues                 = $v.Summary.TotalWarningIssues
        TotalInfoIssues                    = $v.Summary.TotalInfoIssues
        TotalUtilizationIssues             = $v.Summary.TotalUtilizationIssues
        UniqueScopesWithIssues             = @($DHCPSummary.ScopesWithIssues).Count
        IssueCountsByCategory              = [ordered]@{
            Critical    = $countsCritical
            Warning     = $countsWarning
            Info        = $countsInfo
            Utilization = $countsUtil
        }
        TotalIssueInstances                = $totalIssueInstances
        ValidationPolicy                   = $DHCPSummary.ValidationPolicy
        Notes                              = @(
            'Counts by category are per-scope and may overlap; use UniqueScopesWithIssues for headline totals.'
        )
    }

    return $summary
}
