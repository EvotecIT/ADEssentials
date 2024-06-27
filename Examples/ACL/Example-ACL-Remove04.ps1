# 2nd way ot removing an ACL entry

Clear-Host
Import-Module .\ADEssentials.psd1 -Force

$FindOU = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

Add-ADACL -Verbose -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -AccessRule GenericAll -AccessControlType Allow
Add-ADACL -Verbose -ADObject $FindOU -Principal 'przemyslaw.klys' -AccessRule GenericAll -AccessControlType Allow

# Remove ACL entry as required
Remove-ADACL -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessRule GenericAll -AccessControlType Deny
Remove-ADACL -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Allow
Remove-ADACL -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Deny