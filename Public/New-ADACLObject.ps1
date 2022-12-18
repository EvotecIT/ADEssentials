function New-ADACLObject {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][string] $Principal,
        [parameter(Mandatory)][alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [parameter(Mandatory)][System.Security.AccessControl.AccessControlType] $AccessControlType,
        [parameter(Mandatory)][alias('ObjectTypeName')][string] $ObjectType,
        [parameter(Mandatory)][alias('InheritedObjectTypeName')][string] $InheritedObjectType,
        [parameter(Mandatory)][alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [switch] $OneLiner
    )

    $ConvertedIdentity = Convert-Identity -Identity $Principal -Verbose:$false
    if ($ConvertedIdentity.Error) {
        Write-Warning -Message "New-ADACLObject - Converting identity $($Principal) failed with $($ConvertedIdentity.Error). Be warned."
    }
    $ConvertedPrincipal = ($ConvertedIdentity).Name
    if ($OneLiner) {
        [PSCustomObject] @{
            Principal               = $ConvertedPrincipal
            ActiveDirectoryRights   = $AccessRule
            AccessControlType       = $AccessControlType
            ObjectTypeName          = $ObjectType
            InheritedObjectTypeName = $InheritedObjectType
            InheritanceType         = $InheritanceType
        }
    } else {
        [PSCustomObject] @{
            Principal   = $ConvertedPrincipal
            Permissions = [PSCustomObject] @{
                'ActiveDirectoryRights'   = $AccessRule
                'AccessControlType'       = $AccessControlType
                'ObjectTypeName'          = $ObjectType
                'InheritedObjectTypeName' = $InheritedObjectType
                'InheritanceType'         = $InheritanceType
            }
        }
    }
}