#requires -Module ADEssentials, PSWriteHTML

<#
.SYNOPSIS
    Test script for enhanced DHCP analysis with comprehensive data collection.

.DESCRIPTION
    This script demonstrates the enhanced DHCP analysis capabilities including:
    - IPv6 scope analysis
    - Multicast scope monitoring
    - Security filter validation
    - DHCP policy analysis
    - Static reservation management
    - Network binding configuration
    - Active lease monitoring
    - Comprehensive option analysis

.NOTES
    This version showcases the enhanced data gathering capabilities added to Get-WinADDHCPSummary.
#>

param(
    [string]$FilePath = "$env:TEMP\DHCP_Enhanced_Analysis.html",
    [string[]]$ComputerName = @(),
    [switch]$Extended
)

try {
    Write-Host "🚀 Testing Enhanced DHCP Analysis Implementation..." -ForegroundColor Green

    # Generate comprehensive DHCP analysis
    $Params = @{
        Extended = $true  # Enable extended analysis by default
        Verbose = $true
    }

    if ($ComputerName.Count -gt 0) {
        $Params.ComputerName = $ComputerName
    }

    $DHCPSummary = Get-WinADDHCPSummary @Params

    if ($DHCPSummary) {
        Write-Host "📊 Generating enhanced HTML report..." -ForegroundColor Yellow

        Show-WinADDHCPSummary -DHCPData $DHCPSummary -FilePath $FilePath -Online

        Write-Host "✅ Enhanced DHCP analysis report generated successfully!" -ForegroundColor Green
        Write-Host "📁 File location: $FilePath" -ForegroundColor Cyan

        # Show comprehensive statistics
        Write-Host "`n📈 Comprehensive Statistics:" -ForegroundColor Magenta
        Write-Host "   🖥️  IPv4 Infrastructure:" -ForegroundColor Yellow
        Write-Host "      • Servers: $($DHCPSummary.Statistics.TotalServers) (Online: $($DHCPSummary.Statistics.ServersOnline))" -ForegroundColor White
        Write-Host "      • IPv4 Scopes: $($DHCPSummary.Statistics.TotalScopes) (Active: $($DHCPSummary.Statistics.ScopesActive))" -ForegroundColor White
        Write-Host "      • Addresses: $($DHCPSummary.Statistics.TotalAddresses.ToString('N0')) ($($DHCPSummary.Statistics.OverallPercentageInUse)% utilized)" -ForegroundColor White

        if ($Extended) {
            Write-Host "   🌐 IPv6 & Advanced Features:" -ForegroundColor Yellow
            Write-Host "      • IPv6 Scopes: $($DHCPSummary.Statistics.TotalIPv6Scopes)" -ForegroundColor White
            Write-Host "      • Multicast Scopes: $($DHCPSummary.Statistics.TotalMulticastScopes)" -ForegroundColor White
            Write-Host "      • Static Reservations: $($DHCPSummary.Statistics.TotalReservations)" -ForegroundColor White
            Write-Host "      • DHCP Policies: $($DHCPSummary.Statistics.TotalPolicies)" -ForegroundColor White
            Write-Host "      • Security Filters: $($DHCPSummary.Statistics.TotalSecurityFilters)" -ForegroundColor White
            Write-Host "      • Network Bindings: $($DHCPSummary.Statistics.TotalNetworkBindings)" -ForegroundColor White
            Write-Host "      • DHCP Options: $($DHCPSummary.Statistics.TotalOptions)" -ForegroundColor White

            Write-Host "   🔒 Security & Configuration:" -ForegroundColor Yellow
            Write-Host "      • Servers with Filtering: $($DHCPSummary.Statistics.ServersWithFiltering)" -ForegroundColor White
            Write-Host "      • Servers with Policies: $($DHCPSummary.Statistics.ServersWithPolicies)" -ForegroundColor White
        }

        # Show data collection details
        Write-Host "`n📋 Data Collection Results:" -ForegroundColor Cyan
        Write-Host "   📊 Basic Data:" -ForegroundColor White
        Write-Host "      • Servers analyzed: $($DHCPSummary.Servers.Count)" -ForegroundColor Gray
        Write-Host "      • IPv4 scopes: $($DHCPSummary.Scopes.Count)" -ForegroundColor Gray
        Write-Host "      • Scopes with issues: $($DHCPSummary.ScopesWithIssues.Count)" -ForegroundColor Gray

        if ($Extended) {
            Write-Host "   🔍 Extended Data (Enhanced Features):" -ForegroundColor White
            Write-Host "      • IPv6 scopes: $($DHCPSummary.IPv6Scopes.Count)" -ForegroundColor Gray
            Write-Host "      • IPv6 scopes with issues: $($DHCPSummary.IPv6ScopesWithIssues.Count)" -ForegroundColor Gray
            Write-Host "      • Multicast scopes: $($DHCPSummary.MulticastScopes.Count)" -ForegroundColor Gray
            Write-Host "      • Static reservations: $($DHCPSummary.Reservations.Count)" -ForegroundColor Gray
            Write-Host "      • Active leases (high-util scopes): $($DHCPSummary.Leases.Count)" -ForegroundColor Gray
            Write-Host "      • DHCP policies: $($DHCPSummary.Policies.Count)" -ForegroundColor Gray
            Write-Host "      • Security filters: $($DHCPSummary.SecurityFilters.Count)" -ForegroundColor Gray
            Write-Host "      • Server settings: $($DHCPSummary.ServerSettings.Count)" -ForegroundColor Gray
            Write-Host "      • Network bindings: $($DHCPSummary.NetworkBindings.Count)" -ForegroundColor Gray
            Write-Host "      • DHCP options: $($DHCPSummary.Options.Count)" -ForegroundColor Gray
            Write-Host "      • Audit logs: $($DHCPSummary.AuditLogs.Count)" -ForegroundColor Gray
            Write-Host "      • Database configs: $($DHCPSummary.Databases.Count)" -ForegroundColor Gray
        }

        # Show enhancement highlights
        Write-Host "`n🎯 Enhanced Analysis Features:" -ForegroundColor Magenta
        Write-Host "   ✅ IPv6 Support: Complete IPv6 scope analysis and validation" -ForegroundColor Green
        Write-Host "   ✅ Security Analysis: MAC filtering, policies, and authorization" -ForegroundColor Green
        Write-Host "   ✅ Multicast Support: Multicast scope monitoring and statistics" -ForegroundColor Green
        Write-Host "   ✅ Advanced Config: Network bindings, server settings, DNS credentials" -ForegroundColor Green
        Write-Host "   ✅ Reservation Management: Static IP reservation tracking" -ForegroundColor Green
        Write-Host "   ✅ Policy Analysis: DHCP policy configuration and processing order" -ForegroundColor Green
        Write-Host "   ✅ Lease Monitoring: Active lease analysis for high-utilization scopes" -ForegroundColor Green
        Write-Host "   ✅ Option Analysis: Comprehensive DHCP option validation" -ForegroundColor Green

        # Show report organization
        Write-Host "`n🗂️ Enhanced Report Organization:" -ForegroundColor Cyan
        Write-Host "   📋 Overview: Enhanced with IPv6, multicast, and security statistics" -ForegroundColor White
        Write-Host "   🖥️ Infrastructure: IPv6 scopes, multicast, security filters, policies, reservations" -ForegroundColor White
        Write-Host "   ⚠️ Validation Issues: IPv6 validation, security concerns, policy issues" -ForegroundColor White
        Write-Host "   ⚙️ Configuration: Enhanced with network bindings, server settings" -ForegroundColor White

        if (-not $Extended) {
            Write-Host "`n💡 Tip: Use -Extended parameter for comprehensive analysis including:" -ForegroundColor Yellow
            Write-Host "   • IPv6 scope analysis • Multicast monitoring • Security validation" -ForegroundColor Gray
            Write-Host "   • Policy analysis • Reservation tracking • Advanced configuration" -ForegroundColor Gray
        }

        # Open report if requested
        $Response = Read-Host "`nOpen the enhanced HTML report? (Y/N)"
        if ($Response -eq 'Y' -or $Response -eq 'y') {
            Start-Process $FilePath
            Write-Host "🌐 Enhanced DHCP analysis report opened in your default browser!" -ForegroundColor Green
            Write-Host "🔍 Explore the new IPv6, security, and advanced configuration sections!" -ForegroundColor Cyan
        }
    } else {
        Write-Warning "No DHCP data available for enhanced analysis"
    }
} catch {
    Write-Error "Failed to perform enhanced DHCP analysis: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
