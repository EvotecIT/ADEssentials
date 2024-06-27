Import-Module .\ADEssentials.psd1 -Force

# All Subnets
Get-WinADForestSubnet | Format-Table *

# All Subnets with test for overlap
Get-WinADForestSubnet -VerifyOverlap | Format-Table *