Import-Module .\ADEssentials.psd1 -Force

#Show-WinADDNSRecords -FilePath $PSScriptRoot\DNSRecords.html -Verbose
#Get-WinDNSRecords -IncludeZone 'ad.evotec.xyz' -IncludeDetails | Format-Table

Get-WinDNSZones | Format-Table