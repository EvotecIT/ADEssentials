Import-Module .\ADEssentials.psd1 -Force

$Objects = Get-WinADBrokenProtectedFromDeletion -Verbose -Type Computer -LimitProcessing 3 -ReturnBrokenOnly
$Objects | Format-Table -AutoSize *

Get-WinADBrokenProtectedFromDeletion -ReturnBrokenOnly -DistinguishedName @(
    'CN=Test1,OU=Protected,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'

    'CN=EX2016X1,OU=Disabled,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
) | Format-Table
return

#Repair-WinADBrokenProtectedFromDeletion -Type All -LimitProcessing 5 -Verbose -WhatIf

Invoke-ADEssentials -Type BrokenProtectedFromDeletion #-Verbose