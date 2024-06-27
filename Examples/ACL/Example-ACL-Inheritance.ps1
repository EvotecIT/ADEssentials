Clear-Host
Import-Module .\ADEssentials.psd1 -Force

$FindOU = 'OU=Accounts01,OU=ITR02,DC=ad,DC=evotec,DC=xyz'

# One way to enable/disable
#Set-ADACLInheritance -ADObject $FindOU -Inheritance 'Disabled' -WhatIf
# only to enable - underneath
#Enable-ADACLInheritance -ADObject $FindOU #-WhatIf
# only to disable - underneath it's just Set-ADACLInheritance -Inheritance 'Disabled'


#Disable-ADACLInheritance -ADObject $FindOU -Verbose -RemoveInheritedAccessRules

Get-ADACL -ADObject $FindOU | Format-TAble -AutoSize
Add-ADACL -ADObject $FindOU -Principal "EVOTEC\przemyslaw.klys" -Verbose -AccessRule GenericAll -AccessControlType Allow -ObjectType Computer
Get-ADACL -ADObject $FindOU | Format-TAble -AutoSize
Remove-ADACL -ADObject $FindOU -Principal "EVOTEC\przemyslaw.klys" -Verbose -AccessRule GenericAll