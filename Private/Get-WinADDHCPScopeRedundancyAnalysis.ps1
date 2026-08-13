function Get-WinADDHCPScopeRedundancyAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPScopeRedundancyAnalysis - Generating scope redundancy analysis"
    
    foreach ($Scope in $DHCPSummary.Scopes) {
        $failoverStatus = Get-DHCPFailoverScopeStatus -Scope $Scope
        $isActive = $Scope.State -eq 'Active'

        $redundancyStatus = switch ($failoverStatus) {
            'Configured' { 'Failover Configured' }
            'Unknown' { 'Failover Status Unknown' }
            'NotCollected' { 'Failover Not Collected' }
            default { if ($isActive) { 'No Failover - Risk' } else { 'No Failover - Inactive' } }
        }
        $riskLevel = switch ($failoverStatus) {
            'Configured' { 'Low' }
            'Unknown' { 'Unknown' }
            'NotCollected' { 'Unknown' }
            default {
                if ($isActive -and $Scope.PercentageInUse -gt 50) { 'High' }
                elseif ($isActive) { 'Medium' }
                else { 'Low' }
            }
        }
        $recommendation = switch ($failoverStatus) {
            'Configured' { if ($isActive) { 'Adequate' } else { 'Review Scope Status' } }
            'Unknown' { 'Resolve failover collection errors' }
            'NotCollected' { 'Collect failover data' }
            default { if ($isActive) { 'Configure Failover' } else { 'Review Scope Status' } }
        }

        $ScopeRedundancy = [PSCustomObject]@{
            'ScopeId'            = $Scope.ScopeId
            'ScopeName'          = $Scope.Name
            'ServerName'         = $Scope.ServerName
            'State'              = $Scope.State
            'UtilizationPercent' = $Scope.PercentageInUse
            'FailoverPartner'    = if ([string]::IsNullOrEmpty($Scope.FailoverPartner)) { 'None' } else { $Scope.FailoverPartner }
            'RedundancyStatus'   = $redundancyStatus
            'RiskLevel'          = $riskLevel
            'Recommendation'     = $recommendation
        }
        $DHCPSummary.ScopeRedundancyAnalysis.Add($ScopeRedundancy)
    }
}
