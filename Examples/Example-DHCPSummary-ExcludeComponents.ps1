Import-Module .\ADEssentials.psd1 -Force

# Purpose: Generate a lighter report by excluding components you don't care about
# - Hides Options & Classes and Utilization (scope statistics) in the UI automatically

$Report = Join-Path $PSScriptRoot "Reports/DHCP_Lightweight_$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')).html"

$show = @{
    ExcludeComponents = @(
        'IPv6',            # skip DHCPv6
        'Options','Classes',# skip options and classes
        'ScopeStatistics'   # skip address utilization collection
    )
    IncludeTabs  = @('Overview','ValidationIssues','Infrastructure','Failover')
    FilePath     = $Report
    Online       = $true
    HideHTML     = $false
    PassThru     = $true
    Verbose      = $true
}

$data = Show-WinADDHCPSummary @show
Write-Host "Report: $Report" -ForegroundColor Cyan
Write-Host "Servers: $($data.Statistics.TotalServers); Scopes: $($data.Statistics.TotalScopes)" -ForegroundColor Gray

