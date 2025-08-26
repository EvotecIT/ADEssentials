function Get-WinADDHCPScopeRedundancyAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPScopeRedundancyAnalysis - Generating scope redundancy analysis"
    
    foreach ($Scope in $DHCPSummary.Scopes) {
        $ScopeRedundancy = [PSCustomObject]@{
            'ScopeId'            = $Scope.ScopeId
            'ScopeName'          = $Scope.Name
            'ServerName'         = $Scope.ServerName
            'State'              = $Scope.State
            'UtilizationPercent' = $Scope.PercentageInUse
            'FailoverPartner'    = if ([string]::IsNullOrEmpty($Scope.FailoverPartner)) { 'None' } else { $Scope.FailoverPartner }
            'RedundancyStatus'   = if ([string]::IsNullOrEmpty($Scope.FailoverPartner)) {
                if ($Scope.State -eq 'Active') { 'No Failover - Risk' } else { 'No Failover - Inactive' }
            } else { 'Failover Configured' }
            'RiskLevel'          = if ([string]::IsNullOrEmpty($Scope.FailoverPartner) -and $Scope.State -eq 'Active' -and $Scope.PercentageInUse -gt 50) { 'High' }
            elseif ([string]::IsNullOrEmpty($Scope.FailoverPartner) -and $Scope.State -eq 'Active') { 'Medium' }
            else { 'Low' }
            'Recommendation'     = if ([string]::IsNullOrEmpty($Scope.FailoverPartner) -and $Scope.State -eq 'Active') { 'Configure Failover' }
            elseif ($Scope.State -ne 'Active') { 'Review Scope Status' }
            else { 'Adequate' }
        }
        $DHCPSummary.ScopeRedundancyAnalysis.Add($ScopeRedundancy)
    }
}