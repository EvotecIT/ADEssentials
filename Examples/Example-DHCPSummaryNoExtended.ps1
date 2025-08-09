# Example showing that Extended mode is now the default behavior
# The Extended parameter has been removed - all comprehensive data is collected by default
# Use -SkipScopeDetails if you want to skip expensive scope statistics for performance

Import-Module ADEssentials -Force

# Example 1: Get comprehensive DHCP data (previously required -Extended)
# This now collects all data including options, classes, policies, etc. by default
$DHCPData = Get-WinADDHCPSummary -TestMode

Write-Host "=== Comprehensive DHCP Data Collection (Default Behavior) ===" -ForegroundColor Cyan
Write-Host "Total Servers: $($DHCPData.Servers.Count)"
Write-Host "Total Scopes: $($DHCPData.Scopes.Count)"
Write-Host "DHCP Options Collected: $($DHCPData.DHCPOptions.Count)"
Write-Host "DHCP Classes Collected: $($DHCPData.DHCPClasses.Count)"
Write-Host "Total Addresses: $($DHCPData.Statistics.TotalAddresses)"
Write-Host ""

# Example 2: Performance mode - skip scope details for faster execution
$DHCPDataFast = Get-WinADDHCPSummary -TestMode -SkipScopeDetails

Write-Host "=== Performance Mode (SkipScopeDetails) ===" -ForegroundColor Yellow
Write-Host "Total Servers: $($DHCPDataFast.Servers.Count)"
Write-Host "Total Scopes: $($DHCPDataFast.Scopes.Count)"
Write-Host "DHCP Options Collected: $($DHCPDataFast.DHCPOptions.Count) (still collected)"
Write-Host "DHCP Classes Collected: $($DHCPDataFast.DHCPClasses.Count) (still collected)"
Write-Host "Total Addresses: $($DHCPDataFast.Statistics.TotalAddresses) (skipped - will be 0)"
Write-Host ""

# Example 3: Generate HTML Report with all data
Write-Host "=== HTML Report Generation ===" -ForegroundColor Green
Show-WinADDHCPSummary -TestMode -FilePath "$env:TEMP\DHCP-Report.html" -Online

Write-Host ""
Write-Host "Summary of Changes:" -ForegroundColor Magenta
Write-Host "- Extended parameter has been REMOVED"
Write-Host "- All extended data (options, classes, policies) is now collected by DEFAULT"
Write-Host "- Use -SkipScopeDetails for performance optimization when scope statistics aren't needed"
Write-Host "- This simplifies usage - you get comprehensive data without extra parameters"