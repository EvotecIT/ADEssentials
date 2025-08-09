function Get-WinADDHCPServerPerformanceAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPServerPerformanceAnalysis - Generating server performance analysis"
    
    foreach ($Server in $DHCPSummary.Servers) {
        $ServerPerformance = [PSCustomObject]@{
            'ServerName'         = $Server.ServerName
            'Status'             = $Server.Status
            'TotalScopes'        = $Server.ScopeCount
            'ActiveScopes'       = $Server.ActiveScopeCount
            'ScopesWithIssues'   = $Server.ScopesWithIssues
            'TotalAddresses'     = $Server.TotalAddresses
            'AddressesInUse'     = $Server.AddressesInUse
            'UtilizationPercent' = $Server.PercentageInUse
            'PerformanceRating'  = if ($Server.Status -ne 'Online') { 'Offline' }
            elseif (-not $Server.DHCPResponding) { 'Service Failed' }
            elseif (-not $Server.DNSResolvable) { 'DNS Issues' }
            elseif (-not $Server.PingSuccessful) { 'Network Issues' }
            elseif ($Server.PercentageInUse -gt 95) { 'Critical' }
            elseif ($Server.PercentageInUse -gt 80) { 'High Risk' }
            elseif ($Server.PercentageInUse -gt 60) { 'Moderate' }
            elseif ($Server.PercentageInUse -lt 5 -and $Server.ScopeCount -gt 0) { 'Under-utilized' }
            else { 'Optimal' }
            'CapacityStatus'     = if ($Server.Status -ne 'Online') { 'Server Offline' }
            elseif (-not $Server.DHCPResponding) { 'Service Not Responding' }
            elseif (-not $Server.DNSResolvable) { 'DNS Resolution Failed' }
            elseif (-not $Server.PingSuccessful) { 'Network Unreachable' }
            elseif ($Server.PercentageInUse -gt 95) { 'Immediate Expansion Needed' }
            elseif ($Server.PercentageInUse -gt 80) { 'Plan Expansion' }
            elseif ($Server.PercentageInUse -lt 5 -and $Server.ScopeCount -gt 0) { 'Review Necessity' }
            else { 'Adequate' }
        }
        $DHCPSummary.ServerPerformanceAnalysis.Add($ServerPerformance)
    }
}