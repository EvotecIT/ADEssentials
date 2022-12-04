function New-ADACLObject {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)]
        [alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [parameter(Mandatory)]
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [parameter(Mandatory)]
        [alias('ObjectTypeName')][string] $ObjectType,
        [parameter(Mandatory)]
        [alias('InheritedObjectTypeName')][string] $InheritedObjectType,
        [parameter(Mandatory)]
        [alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType
    )

    [ordered] @{
        'ActiveDirectoryRights'   = $AccessRule
        'AccessControlType'       = $AccessControlType
        'ObjectTypeName'          = $ObjectType
        'InheritedObjectTypeName' = $InheritedObjectType
        'InheritanceType'         = $InheritanceType
    }
}