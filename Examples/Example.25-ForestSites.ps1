Import-Module .\ADEssentials.psd1 -Force

Get-WinADForestSites -Verbose | Format-Table *