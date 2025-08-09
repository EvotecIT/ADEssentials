function Get-WinADDHCPPerformanceMetrics {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPPerformanceMetrics - Calculating performance metrics"
    
    $OverallPerformance = [PSCustomObject]@{
        TotalServers                    = $DHCPSummary.Statistics.TotalServers
        TotalScopes                     = $DHCPSummary.Statistics.TotalScopes
        AverageUtilization              = if ($DHCPSummary.Statistics.TotalScopes -gt 0) {
            [Math]::Round(($DHCPSummary.Servers | ForEach-Object { $_.PercentageInUse } | Measure-Object -Average).Average, 2)
        } else { 0 }
        HighUtilizationScopes           = ($DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -gt 80 }).Count
        CriticalUtilizationScopes       = ($DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -gt 95 }).Count
        UnderUtilizedScopes             = ($DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -lt 5 -and $_.State -eq 'Active' }).Count
        CapacityPlanningRecommendations = [System.Collections.Generic.List[string]]::new()
    }

    if ($OverallPerformance.CriticalUtilizationScopes -gt 0) {
        $OverallPerformance.CapacityPlanningRecommendations.Add("$($OverallPerformance.CriticalUtilizationScopes) scope(s) require immediate expansion")
    }
    if ($OverallPerformance.HighUtilizationScopes -gt 0) {
        $OverallPerformance.CapacityPlanningRecommendations.Add("$($OverallPerformance.HighUtilizationScopes) scope(s) need expansion planning")
    }
    if ($OverallPerformance.UnderUtilizedScopes -gt 0) {
        $OverallPerformance.CapacityPlanningRecommendations.Add("$($OverallPerformance.UnderUtilizedScopes) scope(s) are underutilized and may need review")
    }

    $DHCPSummary.PerformanceMetrics.Add($OverallPerformance)
}