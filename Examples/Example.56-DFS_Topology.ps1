Import-Module .\ADEssentials.psd1 -Force

Get-WinADDFSTopology -Type All | Format-Table