# 3rd way ot removing an ACL entry

Clear-Host
Import-Module .\ADEssentials.psd1 -Force

$FindOU = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

# Get organizational unit
$OUs = Get-ADOrganizationalUnit -Properties CanonicalName -Identity $FindOU
# Get current permission
$MYACL = Get-ADACL -ADObject $OUs -Verbose -NotInherited -IncludeActiveDirectoryRights GenericAll -Bundle
$MYACL | Format-Table -AutoSize
$MYACL.ACLAccessRules | Format-Table

# Remove ACL entry as required
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessRule GenericAll -AccessControlType Deny
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Allow
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Deny