Import-Module .\ADEssentials.psd1 -Force

#$Test = Get-ADUser 'przemyslaw.klys' -Properties ProxyAddresses, EmailAddress
#Get-WinADProxyAddresses -ADUser $Test -RemovePrefix | Format-Table

# Get a user
$User = Get-ADUser 'testing1' -Properties ProxyAddresses, EmailAddress
# You can optionally verify how it looks like or what is set
#Get-WinADProxyAddresses -ADUser $User | Format-Table
# Fix primary email address - it will be added to primary email field + proxy address as primary, existing addresses will be rearanged
Repair-WinADEmailAddress -ADUser $User -ToEmail 'testing2@evotec.be' -Display -WhatIf | Format-Table