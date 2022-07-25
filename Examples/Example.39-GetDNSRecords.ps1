Import-Module .\ADEssentials.psd1 -Force

Get-WinDNSRecords -Verbose | Format-Table