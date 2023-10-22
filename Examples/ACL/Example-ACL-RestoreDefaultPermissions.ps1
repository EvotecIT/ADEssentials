Import-Module .\ADEssentials.psd1 -Force

$ObjectCheck = Get-ADObject -Id 'OU=_root,DC=ad,DC=evotec,DC=xyz' -Properties 'NtSecurityDescriptor', 'DistinguishedName'
$Object = Restore-ADACLDefault -Object $ObjectCheck -Verbose -WhatIf
$Object

$Object = Restore-ADACLDefault -Object 'OU=ITR01,DC=ad,DC=evotec,DC=xyz' -RemoveInheritedAccessRules -Verbose -WhatIf
$Object

$Object = Restore-ADACLDefault -Object 'CN=WO_SVC_Delete,CN=Managed Service Accounts,DC=ad,DC=evotec,DC=xyz' -RemoveInheritedAccessRules -Verbose -WhatIf
$Object
