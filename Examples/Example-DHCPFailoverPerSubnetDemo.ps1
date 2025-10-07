<#
Demonstrates the improved failover analysis with:
- Multiple failover relationships between the same server pair (different names)
- Consolidated per-subnet issues view
- Detection of stale failover relationships (no subnets)
#>

Import-Module -Force (Join-Path $PSScriptRoot '..\ADEssentials.psd1')

$FilePath = Join-Path $env:TEMP "DHCP-Failover-PerSubnet-Demo.html"

$DHCP = Show-WinADDHCPSummary -TestMode -Minimal -Online -FilePath $FilePath -PassThru -Verbose

"Report saved to: $FilePath"
