Import-Module .\ADEssentials.psd1 -Force

Get-WinDNSRecords -Verbose -IncludeDetails | Format-Table
Get-WinDNSRecords -Prettify -IncludeDetails | Format-Table

Get-WinDNSIPAddresses | Format-Table *
Get-WinDNSIPAddresses -Prettify | Format-Table *
Get-WinDNSIPAddresses -Prettify -IncludeDetails -IncludeDNSRecords | Format-Table *