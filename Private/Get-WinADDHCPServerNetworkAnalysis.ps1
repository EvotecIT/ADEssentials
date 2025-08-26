function Get-WinADDHCPServerNetworkAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPServerNetworkAnalysis - Generating server network analysis"
    
    foreach ($Server in $DHCPSummary.Servers) {
        $RedundancyNotes = @()
        if ($Server.IsADDomainController) {
            $RedundancyNotes += "Domain Controller"
        }
        if ($Server.ScopeCount -gt 10) {
            $RedundancyNotes += "High scope count - consider load balancing"
        }

        $ServerNetwork = [PSCustomObject]@{
            'ServerName'         = $Server.ServerName
            'IPAddress'          = $Server.IPAddress
            'Status'             = $Server.Status
            'IsDomainController' = $Server.IsADDomainController
            'TotalScopes'        = $Server.ScopeCount
            'ActiveScopes'       = $Server.ActiveScopeCount
            'InactiveScopes'     = $Server.InactiveScopeCount
            'DNSResolvable'      = $Server.DNSResolvable
            'ReverseDNSValid'    = $Server.ReverseDNSValid
            'NetworkHealth'      = if (-not $Server.PingSuccessful) { 'Network Issues' }
            elseif (-not $Server.DNSResolvable) { 'DNS Issues' }
            elseif (-not $Server.DHCPResponding) { 'DHCP Service Issues' }
            else { 'Healthy' }
            'DesignNotes'        = if ($RedundancyNotes.Count -gt 0) { $RedundancyNotes -join ', ' } else { 'Standard Configuration' }
        }
        $DHCPSummary.ServerNetworkAnalysis.Add($ServerNetwork)
    }
}