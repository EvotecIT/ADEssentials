Import-Module .\ADEssentials.psd1 -Force

$FindOU = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

Remove-ADACL -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Deny
Add-ADACL -Verbose -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -AccessRule GenericAll -AccessControlType Allow

return
$OUs = Get-ADOrganizationalUnit -Properties CanonicalName -Identity $FindOU
$MYACL = Get-ADACL -ADObject $OUs -Verbose -NotInherited -IncludeActiveDirectoryRights GenericAll -Bundle
$MYACL | Format-Table -AutoSize
$MYACL.ACLAccessRules | Format-Table


#Remove-ADACL -ACL $MYACL -Principal 'EVOTEC\GDS-TestGroup1' -AccessRule ExtendedRight #-WhatIf
#Add-ADACL -ACL $MYACL -Principal 'EVOTEC\GDS-TestGroup1' -AccessRule ExtendedRight -AccessControlType Allow -Verbose #-WhatIf
#Add-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -AccessRule GenericAll -AccessControlType Allow -Verbose

#$MYACL = Get-ADACL -ADObject $OUs -Verbose -NotInherited -IncludeActiveDirectoryRights GenericAll -Bundle
#$MYACL | Format-Table -AutoSize
#$MYACL.ACLAccessRules | Format-Table
#Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessRule ExtendedRight -AccessControlType Allow
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessRule GenericAll -AccessControlType Deny
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Allow
Remove-ADACL -ACL $MYACL -Principal 'mmmm@ad.evotec.pl' -Verbose -AccessControlType Deny
<#
$ByIdentity = $true
$Remove = $false
$RemoveRights = $true
$Principal = 'EVOTEC\GDS-TestGroup1'
$AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
$Rules = @(
    # [System.Enum]::GetValues([System.DirectoryServices.ActiveDirectoryRights])

    CreateChild
    DeleteChild
    ListChildren
    Self
    ReadProperty
    WriteProperty
    DeleteTree
    ListObject
    ExtendeRdight
    Delete
    ReadControl
    GenericExecute
    GenericWrite
    GenericRead
    WriteDacl
    WriteOwner
    GenericAll
    Synchronize
    AccessSystemSecurity

    [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight
)

foreach ($SubACL in $MYACL) {
    $OutputRequiresCommit = foreach ($AccessRule in $SubACL.ACLAccessRules) {
        if ($ByIdentity) {
            if ($AccessRule.Principal -eq $Principal) {
                #$AccessRule
                [System.Security.Principal.IdentityReference] $Identity = $AccessRule.Bundle.IdentityReference

                if ($Remove) {
                Write-Host "Remove-ADACL - Removing access for $($AccessRule.Principal) / $($AccessRule.ActiveDirectoryRights)"
                try {
                    $SubACL.ACL.RemoveAccess($Identity, $AccessControlType)
                    $true
                } catch {
                    $false
                }
                }
                if ($RemoveRights) {
                    foreach ($Rule in $Rules) {
                        $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
                        Write-Host "Remove-ADACL - Removing access for $($AccessRuleToRemove.IdentityReference) / $($AccessRuleToRemove.ActiveDirectoryRights)"
                        $SubACL.ACL.RemoveAccessRule($AccessRuleToRemove)
                    }
                }
            }
        }
    }
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Host "Remove-ADACL - Saving permissions for $($SubACL.Path)"
        #Set-Acl -Path $SubACL.Path -AclObject $SubACL.ACL -ErrorAction Stop -WhatIf:$false
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Remove-ADACL - Skipping saving permissions for $($SubACL.Path) due to errors."
    }
}
#>


<#
System.DirectoryServices.ActiveDirectoryAccessRule new(System.Security.Principal.IdentityReference identity, System.DirectoryServices.ActiveDirectoryRights adRights, System.Security.AccessControl.AccessControlType type)
System.DirectoryServices.ActiveDirectoryAccessRule new(System.Security.Principal.IdentityReference identity, System.DirectoryServices.ActiveDirectoryRights adRights, System.Security.AccessControl.AccessControlType type, guid objectType)
System.DirectoryServices.ActiveDirectoryAccessRule new(System.Security.Principal.IdentityReference identity, System.DirectoryServices.ActiveDirectoryRights adRights, System.Security.AccessControl.AccessControlType type, System.DirectoryServices.ActiveDirectorySecurityInheritance inheritanceType)
System.DirectoryServices.ActiveDirectoryAccessRule new(System.Security.Principal.IdentityReference identity, System.DirectoryServices.ActiveDirectoryRights adRights, System.Security.AccessControl.AccessControlType type, guid objectType, System.DirectoryServices.ActiveDirectorySecurityInheritance inheritanceType)
System.DirectoryServices.ActiveDirectoryAccessRule new(System.Security.Principal.IdentityReference identity, System.DirectoryServices.ActiveDirectoryRights adRights, System.Security.AccessControl.AccessControlType type, System.DirectoryServices.ActiveDirectorySecurityInheritance inheritanceType, guid inheritedObjectType)
System.DirectoryServices.ActiveDirectoryAccessRule new(System.Security.Principal.IdentityReference identity, System.DirectoryServices.ActiveDirectoryRights adRights, System.Security.AccessControl.AccessControlType type, guid objectType, System.DirectoryServices.ActiveDirectorySecurityInheritance inheritanceType, guid inheritedObjectType)

#>