# Example script demonstrating the new DHCP functions in ADEssentials
# This script shows how to use the DHCP functions to analyze your DHCP infrastructure

# Import the ADEssentials module (assuming it's installed)
Import-Module .\..\ADEssentials.psd1 -Force

# Example 1: Basic DHCP server discovery
Write-Host "=== Basic DHCP Server Discovery ===" -ForegroundColor Green
$DHCPServers = Get-WinADDHCP -TestConnectivity -Verbose
$DHCPServers | Format-Table DNSName, IPAddress, IsDC, IsReachable, DHCPVersion, ConnectivityStatus -AutoSize

# Example 2: Get comprehensive DHCP summary
Write-Host "`n=== Comprehensive DHCP Summary ===" -ForegroundColor Green
$DHCPSummary = Get-WinADDHCPSummary -Extended -Verbose

# Display statistics
Write-Host "DHCP Infrastructure Statistics:" -ForegroundColor Yellow
Write-Host "  Total Servers: $($DHCPSummary.Statistics.TotalServers)"
Write-Host "  Servers Online: $($DHCPSummary.Statistics.ServersOnline)"
Write-Host "  Servers with Issues: $($DHCPSummary.Statistics.ServersWithIssues)"
Write-Host "  Total Scopes: $($DHCPSummary.Statistics.TotalScopes)"
Write-Host "  Scopes with Issues: $($DHCPSummary.Statistics.ScopesWithIssues)"
Write-Host "  Overall Utilization: $($DHCPSummary.Statistics.OverallPercentageInUse)%"

# Show servers with issues
if ($DHCPSummary.Statistics.ServersWithIssues -gt 0) {
    Write-Host "`nServers with Issues:" -ForegroundColor Red
    $DHCPSummary.Servers | Where-Object { $_.ScopesWithIssues -gt 0 -or $_.Status -ne 'Online' } |
    Format-Table ServerName, Status, ScopesWithIssues, ErrorMessage -AutoSize
}

# Show scopes with issues
if ($DHCPSummary.Statistics.ScopesWithIssues -gt 0) {
    Write-Host "`nScopes with Configuration Issues:" -ForegroundColor Red
    $DHCPSummary.ScopesWithIssues |
    Select-Object ServerName, ScopeId, Name, State, LeaseDurationHours, PercentageInUse, @{
        Name       = 'Issues'
        Expression = { $_.Issues -join '; ' }
    } | Format-Table -AutoSize
}

# Show high utilization scopes
$HighUtilizationScopes = $DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -gt 75 -and $_.State -eq 'Active' }
if ($HighUtilizationScopes.Count -gt 0) {
    Write-Host "`nHigh Utilization Scopes (>75%):" -ForegroundColor Yellow
    $HighUtilizationScopes |
    Select-Object ServerName, ScopeId, Name, PercentageInUse, AddressesInUse, AddressesFree |
    Sort-Object PercentageInUse -Descending |
    Format-Table -AutoSize
}

# Example 3: Generate HTML report
Write-Host "`n=== Generating HTML Report ===" -ForegroundColor Green
$ReportPath = "$env:TEMP\DHCP_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

# Generate the report (will open in browser by default)
Show-WinADDHCPSummary -FilePath $ReportPath -PassThru

Write-Host "HTML Report generated: $ReportPath" -ForegroundColor Green

# Example 4: Specific server analysis
Write-Host "`n=== Specific Server Analysis ===" -ForegroundColor Green
$SpecificServer = "dhcp01.yourdomain.com"  # Replace with your DHCP server name

# Check if the server exists in our data
$ServerData = $DHCPSummary.Servers | Where-Object { $_.ServerName -eq $SpecificServer }
if ($ServerData) {
    Write-Host "Analysis for server: $SpecificServer" -ForegroundColor Yellow
    Write-Host "  Status: $($ServerData.Status)"
    Write-Host "  Total Scopes: $($ServerData.ScopeCount)"
    Write-Host "  Active Scopes: $($ServerData.ActiveScopeCount)"
    Write-Host "  Scopes with Issues: $($ServerData.ScopesWithIssues)"
    Write-Host "  Total Addresses: $($ServerData.TotalAddresses)"
    Write-Host "  Utilization: $($ServerData.PercentageInUse)%"

    # Show scopes for this server
    $ServerScopes = $DHCPSummary.Scopes | Where-Object { $_.ServerName -eq $SpecificServer }
    Write-Host "`n  Scopes on $SpecificServer`:"
    $ServerScopes | Format-Table ScopeId, Name, State, PercentageInUse, LeaseDurationHours, HasIssues -AutoSize
} else {
    Write-Host "Server $SpecificServer not found in DHCP data" -ForegroundColor Red
}

# Example 5: Export to CSV for further analysis
Write-Host "`n=== Exporting Data to CSV ===" -ForegroundColor Green
$ExportPath = "$env:TEMP\DHCP_Analysis_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Export servers
$DHCPSummary.Servers | Export-Csv "$ExportPath`_Servers.csv" -NoTypeInformation
Write-Host "Servers exported to: $ExportPath`_Servers.csv"

# Export scopes
$DHCPSummary.Scopes | Export-Csv "$ExportPath`_Scopes.csv" -NoTypeInformation
Write-Host "Scopes exported to: $ExportPath`_Scopes.csv"

# Export scopes with issues
if ($DHCPSummary.ScopesWithIssues.Count -gt 0) {
    $DHCPSummary.ScopesWithIssues | Export-Csv "$ExportPath`_ScopesWithIssues.csv" -NoTypeInformation
    Write-Host "Scopes with issues exported to: $ExportPath`_ScopesWithIssues.csv"
}

# Example 7: Run the comprehensive health check using the public function
Write-Host "`n=== DHCP Health Check (Using Public Function) ===" -ForegroundColor Green
Invoke-WinADDHCPHealthCheck

# You can also run it quietly and process results programmatically
Write-Host "`n=== Programmatic Health Check ===" -ForegroundColor Green
$QuietHealthCheck = Invoke-WinADDHCPHealthCheck -Quiet

if ($QuietHealthCheck.HealthScore -lt 80) {
    Write-Host "⚠️ DHCP infrastructure needs attention (Score: $($QuietHealthCheck.HealthScore))" -ForegroundColor Yellow
} else {
    Write-Host "✅ DHCP infrastructure is healthy (Score: $($QuietHealthCheck.HealthScore))" -ForegroundColor Green
}

# Example 8: Health check with specific parameters
Write-Host "`n=== Targeted Health Check ===" -ForegroundColor Green
# Uncomment and modify the line below for specific server checks:
# $TargetedHealthCheck = Invoke-WinADDHCPHealthCheck -ComputerName "dhcp01.domain.com", "dhcp02.domain.com" -Quiet

Write-Host "`nDHCP Analysis Complete!" -ForegroundColor Green
Write-Host "Use the following commands for more detailed analysis:" -ForegroundColor Cyan
Write-Host "  Get-WinADDHCP -TestConnectivity" -ForegroundColor White
Write-Host "  Get-WinADDHCPSummary -Extended" -ForegroundColor White
Write-Host "  Invoke-WinADDHCPHealthCheck" -ForegroundColor White
Write-Host "  Show-WinADDHCPSummary -FilePath 'C:\Reports\DHCP.html'" -ForegroundColor White
