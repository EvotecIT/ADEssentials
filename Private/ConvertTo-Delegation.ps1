function ConvertTo-Delegation {
    <#
    .SYNOPSIS
    Converts delegation parameters into a custom object.

    .DESCRIPTION
    This function converts delegation parameters into a custom object based on the provided input. It allows for defining permissions in a structured manner for a given principal.

    .PARAMETER Principal
    Specifies the principal to which the delegation applies.

    .PARAMETER AccessRule
    Specifies the Active Directory rights to assign for the delegation.

    .PARAMETER AccessControlType
    Specifies the type of access control to be applied.

    .PARAMETER ObjectType
    Specifies the type of object being targeted for the delegation.

    .PARAMETER InheritedObjectType
    Specifies the type of inherited object for the delegation.

    .PARAMETER InheritanceType
    Specifies the type of inheritance to consider for the delegation.

    .PARAMETER OneLiner
    If specified, the output will be in a single line format.

    .EXAMPLE
    ConvertTo-Delegation -Principal "User1" -AccessRule "Read" -AccessControlType "Allow" -ObjectType "File" -InheritedObjectType "Folder" -InheritanceType "Descendents" -OneLiner

    Converts the delegation parameters into a custom object in a single line format.

    .NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
    [CmdletBinding()]
    param(
        [string] $Principal,
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [alias('ObjectTypeName')][string] $ObjectType,
        [alias('InheritedObjectTypeName')][string] $InheritedObjectType,
        [alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [switch] $OneLiner
    )
    if ($OneLiner) {
        [PSCustomObject] @{
            Principal               = $Principal
            ActiveDirectoryRights   = $AccessRule
            AccessControlType       = $AccessControlType
            ObjectTypeName          = $ObjectType
            InheritedObjectTypeName = $InheritedObjectType
            InheritanceType         = $InheritanceType
        }
    } else {
        [PSCustomObject] @{
            Principal   = $Principal
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

[scriptblock] $ConvertToDelegationAutocompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if (-not $Script:ADSchemaGuids) {
        Import-Module ActiveDirectory -Verbose:$false
        $Script:ADSchemaGuids = Convert-ADSchemaToGuid
    }
    $Script:ADSchemaGuids.Keys | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object { "'$($_)'" } #| Sort-Object
}

Register-ArgumentCompleter -CommandName ConvertTo-Delegation -ParameterName ObjectType -ScriptBlock $ConvertToDelegationAutocompleter
Register-ArgumentCompleter -CommandName ConvertTo-Delegation -ParameterName InheritedObjectType -ScriptBlock $ConvertToDelegationAutocompleter