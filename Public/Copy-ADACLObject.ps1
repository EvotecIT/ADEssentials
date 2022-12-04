function Copy-ADACLObject {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Identity')][string] $ADObject,
        [string[]] $Principal,
        [switch] $Exportable
    )

    $ACLOutput = Get-ADACL -ADObject $ADObject -Bundle
    foreach ($ACL in $ACLOutput.ACLAccessRules) {
        if ($Principal) {
            if ($ACL.Principal -notin $Principal) {
                continue
            }
        }
        if (-not $Exportable) {
            [ordered] @{
                #ADObject                = $ADObject
                #AccessControlType       = $ACL.AccessControlType       #  Deny
                Principal                 = $ACL.Principal               # : Everyone
                #ObjectTypeName          = $ACL.ObjectTypeName          # : All
                #InheritedObjectTypeName = $ACL.InheritedObjectTypeName # : All
                #ActiveDirectoryRights   = $ACL.ActiveDirectoryRights   # : DeleteChild
                #InheritanceType         = $ACL.InheritanceType         # : None
                #IsInherited               = $ACL.IsInherited             # : False
                ActiveDirectoryAccessRule = $ACL.Bundle
            }
        } else {
            [ordered] @{
                #ADObject                = $ADObject
                AccessControlType       = $ACL.AccessControlType       #  Deny
                Principal               = $ACL.Principal               # : Everyone
                ObjectTypeName          = $ACL.ObjectTypeName          # : All
                InheritedObjectTypeName = $ACL.InheritedObjectTypeName # : All
                ActiveDirectoryRights   = $ACL.ActiveDirectoryRights   # : DeleteChild
                InheritanceType         = $ACL.InheritanceType         # : None
                #IsInherited               = $ACL.IsInherited             # : False
                #ActiveDirectoryAccessRule = $ACL.Bundle
            }
        }
    }
}