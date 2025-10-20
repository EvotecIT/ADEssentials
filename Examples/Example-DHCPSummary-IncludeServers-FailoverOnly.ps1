Import-Module .\ADEssentials.psd1 -Force

# Purpose: Only analyze failover health for a targeted server set, fast/minimal scan
# Adjust the server list to your environment
$Servers = @('dhcp01.contoso.com','dhcp02.contoso.com')

$Report = Join-Path $PSScriptRoot "Reports/DHCP_FailoverOnly_$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')).html"

$show = @{
    Minimal            = $true                 # keeps it fast; forces SkipScopeDetails
    IncludeServers     = $Servers              # limit to specific DHCP servers
    IncludeComponents  = @(
        'Servers','Scopes','Failover','Validation','TimingStatistics'
    )                                         # explicit for readability (matches Minimal defaults)
    FilePath           = $Report
    Online             = $true
    HideHTML           = $false
    PassThru           = $true
    Verbose            = $true
}

$data = Show-WinADDHCPSummary @show
Write-Host "Report: $Report" -ForegroundColor Cyan
Write-Host "Failover-only issues: $($data.FailoverAnalysis.PerSubnetIssues.Count)" -ForegroundColor Yellow

