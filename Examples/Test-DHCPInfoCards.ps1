#requires -Module ADEssentials, PSWriteHTML

<#
.SYNOPSIS
    Test script for DHCP tabbed interface and info cards implementation.

.DESCRIPTION
    This script tests the new tabbed interface with info cards functionality in the DHCP reporting system.
    It generates a sample report to verify the visual enhancements and navigation improvements are working properly.
#>

param(
    [string]$FilePath = "$env:TEMP\DHCP_TabbedReport_Test.html",
    [string[]]$ComputerName = @('DC01.contoso.com', 'DC02.contoso.com')
)

try {
    Write-Host "🔍 Testing DHCP Tabbed Interface Implementation..." -ForegroundColor Green

    # Generate DHCP summary with tabbed interface
    $DHCPSummary = Get-WinADDHCPSummary -ComputerName $ComputerName -Verbose

    if ($DHCPSummary) {
        Write-Host "📊 Generating HTML report with tabbed interface and info cards..." -ForegroundColor Yellow

        Show-WinADDHCPSummary -DHCPData $DHCPSummary -FilePath $FilePath -Online

        Write-Host "✅ Tabbed report generated successfully!" -ForegroundColor Green
        Write-Host "📁 File location: $FilePath" -ForegroundColor Cyan

        # Show summary statistics
        Write-Host "`n📈 Report Statistics:" -ForegroundColor Magenta
        Write-Host "   • Servers: $($DHCPSummary.Statistics.TotalServers)" -ForegroundColor White
        Write-Host "   • Scopes: $($DHCPSummary.Statistics.TotalScopes)" -ForegroundColor White
        Write-Host "   • Addresses: $($DHCPSummary.Statistics.TotalAddresses.ToString('N0'))" -ForegroundColor White
        Write-Host "   • Utilization: $($DHCPSummary.Statistics.OverallPercentageInUse)%" -ForegroundColor White

        # Show tab organization
        Write-Host "`n🗂️ Report Organization:" -ForegroundColor Cyan
        Write-Host "   📋 Overview: Summary, info cards, charts, and recommendations" -ForegroundColor White
        Write-Host "   🖥️ Infrastructure: Detailed server and scope tables" -ForegroundColor White
        Write-Host "   ⚠️ Validation Issues: All configuration problems and capacity concerns" -ForegroundColor White
        Write-Host "   ⚙️ Configuration: Audit logs, database settings, and best practices" -ForegroundColor White

        # Open report if requested
        $Response = Read-Host "`nOpen the HTML report to test the tabbed interface? (Y/N)"
        if ($Response -eq 'Y' -or $Response -eq 'y') {
            Start-Process $FilePath
            Write-Host "🌐 Report opened in your default browser. Test the tab navigation!" -ForegroundColor Green
        }
    } else {
        Write-Warning "No DHCP data available for testing"
    }
} catch {
    Write-Error "Failed to test DHCP tabbed interface: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
