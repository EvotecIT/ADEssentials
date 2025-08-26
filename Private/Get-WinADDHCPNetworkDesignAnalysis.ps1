function Get-WinADDHCPNetworkDesignAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPNetworkDesignAnalysis - Analyzing network design"
    
    $NetworkDesign = [PSCustomObject]@{
        TotalNetworkSegments       = ($DHCPSummary.Scopes | Group-Object { [System.Net.IPAddress]::Parse($_.ScopeId).GetAddressBytes()[0..2] -join '.' }).Count
        ScopeOverlaps              = [System.Collections.Generic.List[string]]::new()
        DesignRecommendations      = [System.Collections.Generic.List[string]]::new()
        RedundancyAnalysis         = [System.Collections.Generic.List[string]]::new()
        ScopeOverlapsCount         = 0
        RedundancyIssuesCount      = 0
        DesignRecommendationsCount = 0
    }

    # Check for potential scope overlaps (simplified check)
    $ScopeRanges = $DHCPSummary.Scopes | Where-Object { $_.State -eq 'Active' }
    for ($i = 0; $i -lt $ScopeRanges.Count; $i++) {
        for ($j = $i + 1; $j -lt $ScopeRanges.Count; $j++) {
            $Scope1 = $ScopeRanges[$i]
            $Scope2 = $ScopeRanges[$j]
            if ($Scope1.ScopeId -eq $Scope2.ScopeId -and $Scope1.ServerName -ne $Scope2.ServerName) {
                $NetworkDesign.ScopeOverlaps.Add("Scope $($Scope1.ScopeId) exists on multiple servers: $($Scope1.ServerName), $($Scope2.ServerName)")
            }
        }
    }

    # Analyze redundancy
    $ServersPerScope = $DHCPSummary.Scopes | Where-Object { $_.State -eq 'Active' } | Group-Object ScopeId
    $SingleServerScopes = ($ServersPerScope | Where-Object { $_.Count -eq 1 }).Count
    if ($SingleServerScopes -gt 0) {
        $NetworkDesign.RedundancyAnalysis.Add("$SingleServerScopes scope(s) have no redundancy (single server)")
        $NetworkDesign.DesignRecommendations.Add("Implement DHCP failover for high availability")
    }

    # Update count properties
    $NetworkDesign.ScopeOverlapsCount = $NetworkDesign.ScopeOverlaps.Count
    $NetworkDesign.RedundancyIssuesCount = $NetworkDesign.RedundancyAnalysis.Count
    $NetworkDesign.DesignRecommendationsCount = $NetworkDesign.DesignRecommendations.Count

    $DHCPSummary.NetworkDesignAnalysis.Add($NetworkDesign)
}