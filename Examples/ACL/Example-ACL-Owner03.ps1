Import-Module .\ADEssentials.psd1 -Force

$DN = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

Get-ADACLOwner -ADObject $DN | Format-Table *
Set-ADACLOwner -ADObject $DN -Principal 'przemyslaw.klys' -Verbose -WhatIf
Set-ADACLOwner -ADObject $DN -Principal 'Domain Admins' -Verbose -WhatIf