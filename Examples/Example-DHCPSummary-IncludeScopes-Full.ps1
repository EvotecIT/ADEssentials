Import-Module .\ADEssentials.psd1 -Force

# Purpose: Deep-dive a few specific scopes (by ScopeId) with full per-scope details
# Replace scope IDs and server with values from your environment
$TargetServer = 'dhcp01.contoso.com'
$ScopesToCheck = @('10.10.1.0','10.10.2.0')

$Report = Join-Path $PSScriptRoot "Reports/DHCP_ScopesDeepDive_$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')).html"

$get = @{
    ComputerName     = $TargetServer
    IncludeScopeId   = $ScopesToCheck
    IncludeComponents= @(
        'Scopes','ScopeStatistics','Options','Reservations','Leases','Validation'
    )
    # Important: do NOT use -Minimal here (we want details)
    Verbose          = $true
}

$data = Get-WinADDHCPSummary @get

$show = @{
    FilePath  = $Report
    Online    = $true
    HideHTML  = $false
    PassThru  = $true
    Verbose   = $true
}

$null = Show-WinADDHCPSummary @show -ComputerName $TargetServer -IncludeScopeId $ScopesToCheck -IncludeComponents $get.IncludeComponents

Write-Host "Report: $Report" -ForegroundColor Cyan
Write-Host "Included scopes: $($ScopesToCheck -join ', ')" -ForegroundColor Gray

