function ConvertFrom-SimplifiedDelegation {
    <#
    .SYNOPSIS
    Experimental way to define permissions that are prepopulated

    .DESCRIPTION
    Experimental way to define permissions that are prepopulated

    .PARAMETER Principal
    Principal to apply the permission to

    .PARAMETER SimplifiedDelegation
    Simplified delegation to apply

    .PARAMETER AccessControlType
    Access control type

    .PARAMETER InheritanceType
    Inheritance type, if not specified, it will be set to Descendents

    .PARAMETER OneLiner
    If specified, the output will be in one line, rather than a multilevel object

    .EXAMPLE
    ConvertFrom-SimplifiedDelegation -Principal $ConvertedPrincipal -SimplifiedDelegation $SimplifiedDelegation -OneLiner:$OneLiner.IsPresent -AccessControlType $AccessControlType -InheritanceType $InheritanceType

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $Principal,
        [string[]] $SimplifiedDelegation,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [switch] $OneLiner
    )
    # Remember to change SimplifiedDelegationDefinitionList below!!!

    $Script:SimplifiedDelegationDefinition = [ordered] @{
        ComputerDomainJoin   = @(
            # allows only to join computers to domain, but not rejoin or move
            if (-not $InheritanceType) {
                $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents
            }
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'CreateChild' -InheritanceType $InheritanceType -InheritedObjectType 'Computer' -OneLiner:$OneLiner
        )
        ComputerDomainReJoin = @(
            # allows to join computers to domain, but also rejoin them on demand
            if (-not $InheritanceType) {
                $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents
            }
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'CreateChild', 'DeleteChild' -InheritanceType $InheritanceType -InheritedObjectType 'Computer' -OneLiner:$OneLiner
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'ExtendedRight' -ObjectType 'Reset Password' -InheritanceType $InheritanceType -InheritedObjectType 'Computer' -OneLiner:$OneLiner
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'ExtendedRight' -ObjectType 'Account Restrictions' -InheritanceType $InheritanceType -InheritedObjectType 'Computer' -OneLiner:$OneLiner
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'ExtendedRight' -ObjectType 'Validated write to DNS host name' -InheritanceType $InheritanceType -InheritedObjectType 'Computer' -OneLiner:$OneLiner
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'ExtendedRight' -ObjectType 'Validated write to service principal name' -InheritanceType $InheritanceType -InheritedObjectType 'Computer' -OneLiner:$OneLiner
        )
        FullControl          = @(
            if (-not $InheritanceType) {
                $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
            }
            ConvertTo-Delegation -ConvertedPrincipal $Principal -AccessControlType $AccessControlType -AccessRule 'GenericAll' -InheritanceType $InheritanceType -OneLiner:$OneLiner
        )
    }

    foreach ($Simple in $SimplifiedDelegation) {
        $Script:SimplifiedDelegationDefinition[$Simple]
    }
}

$Script:SimplifiedDelegationDefinitionList = @(
    'ComputerDomainJoin'
    'ComputerDomainReJoin'
    'FullControl'
)

[scriptblock] $ConvertSimplifiedDelegationDefinition = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $Script:SimplifiedDelegationDefinitionList | Sort-Object | Where-Object { $_ -like "*$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName ConvertFrom-SimplifiedDelegation -ParameterName SimplifiedDelegation -ScriptBlock $ConvertSimplifiedDelegationDefinition
