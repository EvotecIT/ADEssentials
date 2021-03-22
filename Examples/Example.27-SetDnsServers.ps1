Import-Module .\ADEssentials.psd1 -Force

# Manually defined
$Computers = 'AD1', 'AD2', 'ADCS'

# From OU
$Computers = (Get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' -SearchBase 'OU=ITR02,DC=ad,DC=evotec,DC=xyz' -Properties dNSHostName).DNSHostName
$ApprovedList = '192.168.240.189', '192.168.240.192'
#Get-DNSServerIP -ComputerName $Computers -ApprovedList $ApprovedList | Format-Table *


# From given list
$Computers = 'AD1.AD.EVOTEC.XYZ', 'AD2.AD.EVOTEC.XYZ', 'ADRODC.AD.EVOTEC.PL'
$ApprovedList = '192.168.240.189', '192.168.240.192'

#Get-DNSServerIP -ComputerName $Computers | Format-Table *


# Fix
$Computers = 'AD1.AD.EVOTEC.XYZ', 'AD2.AD.EVOTEC.XYZ'
$DnsIpAddress = '192.168.240.189', '192.168.240.192', '192.168.240.236', '127.0.0.1'

Set-DnsServerIP -ComputerName $Computers -DnsIpAddress $DnsIpAddress -WhatIf | Format-Table *