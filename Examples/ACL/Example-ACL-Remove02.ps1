Import-Module .\ADEssentials.psd1 -Force

$FindOU = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

$OUs = Get-ADOrganizationalUnit -Properties CanonicalName -Identity $FindOU
$MYACL = Get-ADACL -ADObject $OUs -Verbose -NotInherited -IncludeActiveDirectoryRights GenericAll -Bundle
$MYACL | Format-Table -AutoSize
$MYACL.ACLAccessRules | Format-Table

Remove-ADACL -ACL $MYACL -Principal 'EVOTEC\GDS-TestGroup1' -AccessRule ExtendedRight #-WhatIf
Add-ADACL -ACL $MYACL -Principal 'EVOTEC\GDS-TestGroup1' -AccessRule ExtendedRight -AccessControlType Allow -Verbose #-WhatIf
Add-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -AccessRule GenericAll -AccessControlType Allow -Verbose

$MYACL = Get-ADACL -ADObject $OUs -Verbose -NotInherited -IncludeActiveDirectoryRights GenericAll -Bundle
$MYACL | Format-Table -AutoSize
$MYACL.ACLAccessRules | Format-Table

Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessRule ExtendedRight -AccessControlType Allow
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessRule GenericAll -AccessControlType Deny
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Allow
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Deny