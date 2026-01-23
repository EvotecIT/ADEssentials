function Get-WinADDHCPIssueSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $DHCPSummary
    )

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
        PublicDNSWithUpdates     = (Get-ADEssentialsDHCPSummaryCount $v.CriticalIssues.PublicDNSWithUpdates)
        DNSConfigurationProblems = (Get-ADEssentialsDHCPSummaryCount $v.CriticalIssues.DNSConfigurationProblems)
        ServersOffline           = (Get-ADEssentialsDHCPSummaryCount $v.CriticalIssues.ServersOffline)
        FailoverOnlyOnPrimary    = (Get-ADEssentialsDHCPSummaryCount $v.CriticalIssues.FailoverOnlyOnPrimary)
        FailoverMissingOnBoth    = (Get-ADEssentialsDHCPSummaryCount $v.CriticalIssues.FailoverMissingOnBoth)
    }
    $countsWarning = [ordered]@{
        MissingFailover         = (Get-ADEssentialsDHCPSummaryCount $v.WarningIssues.MissingFailover)
        FailoverOnlyOnSecondary = (Get-ADEssentialsDHCPSummaryCount $v.WarningIssues.FailoverOnlyOnSecondary)
        ExtendedLeaseDuration   = (Get-ADEssentialsDHCPSummaryCount $v.WarningIssues.ExtendedLeaseDuration)
        DNSRecordManagement     = (Get-ADEssentialsDHCPSummaryCount $v.WarningIssues.DNSRecordManagement)
    }
    $countsInfo = [ordered]@{
        MissingDomainName = (Get-ADEssentialsDHCPSummaryCount $v.InfoIssues.MissingDomainName)
        InactiveScopes    = (Get-ADEssentialsDHCPSummaryCount $v.InfoIssues.InactiveScopes)
    }
    $countsUtil = [ordered]@{
        HighUtilization     = (Get-ADEssentialsDHCPSummaryCount $v.UtilizationIssues.HighUtilization)
        ModerateUtilization = (Get-ADEssentialsDHCPSummaryCount $v.UtilizationIssues.ModerateUtilization)
    }

    $totalIssueInstances = 0
    foreach ($x in @($countsCritical.Values + $countsWarning.Values + $countsInfo.Values + $countsUtil.Values)) {
        $totalIssueInstances += [int]$x
    }

    $summary = [ordered]@{
        TotalCriticalIssues                = (Get-ADEssentialsDHCPSummaryInt $v.Summary.TotalCriticalIssues)
        TotalWarningIssues                 = (Get-ADEssentialsDHCPSummaryInt $v.Summary.TotalWarningIssues)
        TotalInfoIssues                    = (Get-ADEssentialsDHCPSummaryInt $v.Summary.TotalInfoIssues)
        TotalUtilizationIssues             = (Get-ADEssentialsDHCPSummaryInt $v.Summary.TotalUtilizationIssues)
        UniqueScopesWithIssues             = (Get-ADEssentialsDHCPSummaryCount $DHCPSummary.ScopesWithIssues)
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
