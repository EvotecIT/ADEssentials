Import-Module .\ADEssentials.psd1 -Force

$Users = Get-ADUser -Filter * -Properties EmailAddress, ProxyAddresses
$Output = foreach ($User in $Users) {
    Repair-WinADEmailAddress -ToEmail $User.EmailAddress -ADUser $User -Display -WhatIf
}
$Output | Format-Table