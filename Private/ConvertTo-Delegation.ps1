function ConvertTo-Delegation {
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