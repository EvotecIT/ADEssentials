function Copy-ADACLObject {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Identity')][string] $ADObject,
        [alias('Principal')][string[]] $IncludePrincipal,
        [string[]] $ExcludePrincipal,
        [switch] $Exportable
    )

    $ACLOutput = Get-ADACL -ADObject $ADObject -Bundle
    foreach ($ACL in $ACLOutput.ACLAccessRules) {
        if ($IncludePrincipal) {
            if ($ACL.Principal -notin $IncludePrincipal) {
                continue
            }
        }
        if ($ExcludePrincipal) {
            if ($ACL.Principal -in $ExcludePrincipal) {
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