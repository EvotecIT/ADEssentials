Import-Module .\ADEssentials.psd1 -Force

#Get-WinDNSRecords -Verbose -IncludeDetails | Format-Table
#Get-WinDNSRecords -Prettify -IncludeDetails | Format-Table

#Get-WinDNSIPAddresses | Format-Table *
#Get-WinDNSIPAddresses -Prettify | Format-Table *
#Get-WinDNSIPAddresses -Prettify -IncludeDetails -IncludeDNSRecords | Format-Table *


#$Zones = Get-DnsServerZone -ComputerName AD1
#$Zones | Format-Table *

Get-DnsServerZoneAging -Name 'ad.evotec.xyz' -ComputerName AD1
Get-DnsServerZoneAging -Name 'ad.evotec.xyz' -ComputerName AD2