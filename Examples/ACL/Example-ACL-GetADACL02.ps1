Import-Module .\ADEssentials.psd1 -Force

$DN = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

Get-ADACL -ADObject $DN | Format-Table *
Get-ADACL -ADObject 'OU=Test \+ Test2,DC=ad,DC=evotec,DC=xyz' -Resolve | Format-Table *