function Get-WinADDHCPScopeRedundancyAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPScopeRedundancyAnalysis - Generating scope redundancy analysis"
    
    foreach ($Scope in $DHCPSummary.Scopes) {
        $failoverStatus = Get-DHCPFailoverScopeStatus -Scope $Scope
        $failoverVerified = Test-DHCPFailoverScopeVerified -Scope $Scope
        $isActive = $Scope.State -eq 'Active'

        $redundancyStatus = if (-not $failoverVerified) {
            switch ($failoverStatus) {
                'NotCollected' { 'Failover Not Collected' }
                'Configured' { 'Failover Evidence Unverified' }
                default { 'Failover Status Unknown' }
            }
        } else { switch ($failoverStatus) {
            'Configured' { 'Failover Configured' }
            'Unknown' { 'Failover Status Unknown' }
            'NotCollected' { 'Failover Not Collected' }
            default { if ($isActive) { 'No Failover - Risk' } else { 'No Failover - Inactive' } }
        } }
        $riskLevel = if (-not $failoverVerified) { 'Unknown' } else { switch ($failoverStatus) {
            'Configured' { 'Low' }
            'Unknown' { 'Unknown' }
            'NotCollected' { 'Unknown' }
            default {
                if ($isActive -and $Scope.PercentageInUse -gt 50) { 'High' }
                elseif ($isActive) { 'Medium' }
                else { 'Low' }
            }
        } }
        $recommendation = if (-not $failoverVerified) {
            if ($failoverStatus -eq 'NotCollected') { 'Collect failover data' } else { 'Resolve failover collection errors' }
        } else { switch ($failoverStatus) {
            'Configured' { if ($isActive) { 'Adequate' } else { 'Review Scope Status' } }
            'Unknown' { 'Resolve failover collection errors' }
            'NotCollected' { 'Collect failover data' }
            default { if ($isActive) { 'Configure Failover' } else { 'Review Scope Status' } }
        } }

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
