function Get-WinADDHCPSecurityAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPSecurityAnalysis - Performing enhanced security analysis"
    
    foreach ($Server in $DHCPSummary.Servers) {
        $SecurityIssues = [PSCustomObject]@{
            ServerName              = $Server.ServerName
            IsAuthorized            = $Server.IsAuthorized
            AuthorizationStatus     = $Server.AuthorizationStatus
            AuditLoggingEnabled     = $null
            ServiceAccount          = $null
            SecurityRiskLevel       = 'Low'
            SecurityRecommendations = [System.Collections.Generic.List[string]]::new()
        }

        # Determine security risk level based on issues
        if ($Server.Issues | Where-Object { $_ -like "*not authorized*" }) {
            $SecurityIssues.SecurityRiskLevel = 'Critical'
            $SecurityIssues.SecurityRecommendations.Add("Authorize DHCP server in Active Directory immediately")
        }
        if ($Server.Issues | Where-Object { $_ -like "*audit*" }) {
            $SecurityIssues.SecurityRiskLevel = if ($SecurityIssues.SecurityRiskLevel -eq 'Critical') { 'Critical' } else { 'High' }
            $SecurityIssues.SecurityRecommendations.Add("Enable DHCP audit logging for security monitoring")
        }
        if ($Server.Issues | Where-Object { $_ -like "*LocalSystem*" }) {
            $SecurityIssues.SecurityRiskLevel = if ($SecurityIssues.SecurityRiskLevel -eq 'Critical') { 'Critical' } else { 'Medium' }
            $SecurityIssues.SecurityRecommendations.Add("Configure dedicated service account for DHCP service")
        }

        $DHCPSummary.SecurityAnalysis.Add($SecurityIssues)
    }
}