Import-Module .\ADEssentials.psd1 -Force

Get-WinADSiteLinks | Format-Table

Get-WinADSiteLinks -Forest 'test.evotec.pl' | Format-Table