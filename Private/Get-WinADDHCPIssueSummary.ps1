function Get-WinADDHCPIssueSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $DHCPSummary
    )

    function Get-Count {
        param([object] $Value)
        if ($null -eq $Value) { return 0 }
        return @($Value).Count
    }
    function Get-Int {
        param([object] $Value)
        if ($null -eq $Value) { return 0 }
        return [int]$Value
    }

    $v = $DHCPSummary.ValidationResults
    if (-not $v) {
        $v = [ordered]@{
            Summary           = [ordered]@{
                TotalCriticalIssues    = 0
                TotalWarningIssues     = 0
                TotalInfoIssues        = 0
                TotalUtilizationIssues = 0
            }
            CriticalIssues    = [ordered]@{}
            WarningIssues     = [ordered]@{}
            InfoIssues        = [ordered]@{}
            UtilizationIssues = [ordered]@{}
        }
    }

    $countsCritical = [ordered]@{
        PublicDNSWithUpdates     = (Get-Count $v.CriticalIssues.PublicDNSWithUpdates)
        DNSConfigurationProblems = (Get-Count $v.CriticalIssues.DNSConfigurationProblems)
        ServersOffline           = (Get-Count $v.CriticalIssues.ServersOffline)
        FailoverOnlyOnPrimary    = (Get-Count $v.CriticalIssues.FailoverOnlyOnPrimary)
        FailoverMissingOnBoth    = (Get-Count $v.CriticalIssues.FailoverMissingOnBoth)
    }
    $countsWarning = [ordered]@{
        MissingFailover         = (Get-Count $v.WarningIssues.MissingFailover)
        FailoverOnlyOnSecondary = (Get-Count $v.WarningIssues.FailoverOnlyOnSecondary)
        ExtendedLeaseDuration   = (Get-Count $v.WarningIssues.ExtendedLeaseDuration)
        DNSRecordManagement     = (Get-Count $v.WarningIssues.DNSRecordManagement)
    }
    $countsInfo = [ordered]@{
        MissingDomainName = (Get-Count $v.InfoIssues.MissingDomainName)
        InactiveScopes    = (Get-Count $v.InfoIssues.InactiveScopes)
    }
    $countsUtil = [ordered]@{
        HighUtilization     = (Get-Count $v.UtilizationIssues.HighUtilization)
        ModerateUtilization = (Get-Count $v.UtilizationIssues.ModerateUtilization)
    }

    $totalIssueInstances = 0
    foreach ($x in @($countsCritical.Values + $countsWarning.Values + $countsInfo.Values + $countsUtil.Values)) {
        $totalIssueInstances += [int]$x
    }

    $summary = [ordered]@{
        TotalCriticalIssues                = (Get-Int $v.Summary.TotalCriticalIssues)
        TotalWarningIssues                 = (Get-Int $v.Summary.TotalWarningIssues)
        TotalInfoIssues                    = (Get-Int $v.Summary.TotalInfoIssues)
        TotalUtilizationIssues             = (Get-Int $v.Summary.TotalUtilizationIssues)
        UniqueScopesWithIssues             = (Get-Count $DHCPSummary.ScopesWithIssues)
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
