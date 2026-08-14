Import-Module .\ADEssentials.psd1 -Force

# Generate a minimal validation report using TestMode to showcase
# enhanced failover mismatch detection (missing on one partner or both partners)
$null = Show-WinADDHCPSummary -Minimal -TestMode -Verbose -FilePath "$PSScriptRoot\Reports\DHCPFailoverMismatches.html" -HideHTML

Write-Host "Test report generated: $PSScriptRoot\Reports\DHCPFailoverMismatches.html"
