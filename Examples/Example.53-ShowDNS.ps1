Import-Module .\ADEssentials.psd1 -Force

Show-WinADDNSRecords -FilePath $PSScriptRoot\Reports\DNSRecords.html -Verbose -TabPerZone