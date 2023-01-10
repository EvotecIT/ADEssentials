function New-ADACLObject {
    <#
    .SYNOPSIS
    Define ACL permissions to be applied during Set-ADACLObject and in DelegationModel PowerShell Module

    .DESCRIPTION
    Define ACL permissions to be applied during Set-ADACLObject and in DelegationModel PowerShell Module

    .PARAMETER Principal
    Principal to apply permissions to

    .PARAMETER SimplifiedDelegation
    An experimental parameter that allows to choose predefined set of permissions instead of defining multiple rules to cover a single instance.

    .PARAMETER AccessRule
    Access rule to apply. Choices are:
    - AccessSystemSecurity - 16777216 - The right to get or set the SACL in the object security descriptor.
    - CreateChild - 1 - The right to create children of the object.
    - Delete - 65536 - The right to delete the object.
    - DeleteChild - 2 - The right to delete children of the object.
    - DeleteTree - 64 - The right to delete all children of this object, regardless of the permissions of the children.
    - ExtendedRight - 256 A customized control access right. For a list of possible extended rights, see the Extended Rights article. For more information about extended rights, see the Control Access Rights article.
    - GenericAll - 983551 The right to create or delete children, delete a subtree, read and write properties, examine children and the object itself, add and remove the object from the directory, and read or write with an extended right.
    - GenericExecute - 131076 The right to read permissions on, and list the contents of, a container object.
    - GenericRead - 131220 The right to read permissions on this object, read all the properties on this object, list this object name when the parent container is listed, and list the contents of this object if it is a container.
    - GenericWrite - 131112 The right to read permissions on this object, write all the properties on this object, and perform all validated writes to this object.
    - ListChildren - 4 The right to list children of this object. For more information about this right, see the Controlling Object Visibility article.
    - ListObject -128 - The right to list a particular object. For more information about this right, see the Controlling Object Visibility article.
    - ReadControl - 131072 - The right to read data from the security descriptor of the object, not including the data in the SACL.
    - ReadProperty - 16 - The right to read properties of the object.
    - Self -8 - The right to perform an operation that is controlled by a validated write access right.
    - Synchronize -1048576 - The right to use the object for synchronization. This right enables a thread to wait until that object is in the signaled state.
    - WriteDacl - 262144 - The right to modify the DACL in the object security descriptor.
    - WriteOwner - 524288 - The right to assume ownership of the object. The user must be an object trustee. The user cannot transfer the ownership to other users.
    - WriteProperty -32 - The right to write properties of the object

    .PARAMETER AccessControlType
    Access control type to apply. Choices are:
    - Allow - 0 - The access control entry (ACE) allows the specified access.
    - Deny - 1 - The ACE denies the specified access.

    .PARAMETER ObjectType
    A list of schema properties to choose from.

    .PARAMETER InheritedObjectType
    A list of schema properties to choose from.

    .PARAMETER InheritanceType
    Inheritance type to apply. Choices are:
    - All - 3 - The ACE applies to the object and all its children.
    - Descendents - 2 - The ACE applies to the object and its immediate children.
    - SelfAndChildren - 1 - The ACE applies to the object and its immediate children.
    - None - 0 - The ACE applies only to the object.

    .PARAMETER OneLiner
    Return permissions as one liner. If used with Simplified Delegation multiple objects could be retured.

    .PARAMETER Force
    Forces refresh of the cache for user/groups. It's useful to run as a first query, especially if one created groups just before running the function

    .EXAMPLE
     New-ADACLObject -Principal 'przemyslaw.klys' -AccessControlType Allow -ObjectType All -InheritedObjectTypeName 'All' -AccessRule GenericAll -InheritanceType None

    .NOTES
    General notes
    #>
    [cmdletBinding(DefaultParameterSetName = 'Standard')]
    param(
        [parameter(Mandatory, ParameterSetName = 'Simplified')]
        [parameter(Mandatory, ParameterSetName = 'Standard')][string] $Principal,

        [parameter(Mandatory, ParameterSetName = 'Simplified')]
        [string] $SimplifiedDelegation,
        [parameter(Mandatory, ParameterSetName = 'Standard')][alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [parameter(Mandatory, ParameterSetName = 'Simplified')]
        [parameter(Mandatory, ParameterSetName = 'Standard')][System.Security.AccessControl.AccessControlType] $AccessControlType,
        [parameter(Mandatory, ParameterSetName = 'Standard')][alias('ObjectTypeName')][string] $ObjectType,
        [parameter(Mandatory, ParameterSetName = 'Standard')][alias('InheritedObjectTypeName')][string] $InheritedObjectType,
        [parameter(Mandatory, ParameterSetName = 'Simplified')]
        [parameter(Mandatory, ParameterSetName = 'Standard')][alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [parameter(ParameterSetName = 'Simplified')]
        [parameter(ParameterSetName = 'Standard')][switch] $OneLiner,
        [parameter(ParameterSetName = 'Simplified')]
        [parameter(ParameterSetName = 'Standard')][switch] $Force
    )

    $ConvertedIdentity = Convert-Identity -Identity $Principal -Verbose:$false -Force:$Force.IsPresent
    if ($ConvertedIdentity.Error) {
        Write-Warning -Message "New-ADACLObject - Converting identity $($Principal) failed with $($ConvertedIdentity.Error). Be warned."
    }
    $ConvertedPrincipal = ($ConvertedIdentity).Name

    if ($SimplifiedDelegation) {
        ConvertFrom-SimplifiedDelegation -Principal $ConvertedPrincipal -SimplifiedDelegation $SimplifiedDelegation -OneLiner:$OneLiner.IsPresent -AccessControlType $AccessControlType -InheritanceType $InheritanceType
    } else {
        ConvertTo-Delegation -AccessControlType $AccessControlType -InheritanceType $InheritanceType -Principal $ConvertedPrincipal -AccessRule $AccessRule -ObjectType $ObjectType -InheritedObjectType $InheritedObjectType -OneLiner:$OneLiner.IsPresent
    }
}

[scriptblock] $ADACLObjectAutoCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if (-not $Script:ADSchemaGuids) {
        Import-Module ActiveDirectory -Verbose:$false
        $Script:ADSchemaGuids = Convert-ADSchemaToGuid
    }
    $Script:ADSchemaGuids.Keys | Sort-Object | Where-Object { $_ -like "*$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName New-ADACLObject -ParameterName ObjectType -ScriptBlock $ADACLObjectAutoCompleter
Register-ArgumentCompleter -CommandName New-ADACLObject -ParameterName InheritedObjectType -ScriptBlock $ADACLObjectAutoCompleter

[scriptblock] $ADACLSimplifiedDelegationDefinition = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $Script:SimplifiedDelegationDefinitionList | Sort-Object | Where-Object { $_ -like "*$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName New-ADACLObject -ParameterName SimplifiedDelegation -ScriptBlock $ADACLSimplifiedDelegationDefinition