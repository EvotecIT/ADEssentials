function Remove-ADACL {
    <#
    .SYNOPSIS
    Removes an Access Control List (ACL) entry from an Active Directory object or an NTSecurityDescriptor.

    .DESCRIPTION
    This cmdlet is designed to remove a specific ACL entry from an Active Directory object or an NTSecurityDescriptor. It allows for granular control over the removal process by specifying the object, ACL, principal, access rule, access control type, and inheritance settings. Additionally, it provides options to include or exclude specific object types and their inherited types.

    .PARAMETER ADObject
    Specifies the Active Directory object from which to remove the ACL entry. This can be a single object or an array of objects.

    .PARAMETER ACL
    Specifies the ACL from which to remove the entry. This parameter is mandatory when using the ACL or NTSecurityDescriptor parameter sets.

    .PARAMETER Principal
    Specifies the principal (user, group, or computer) for whom the ACL entry is being removed.

    .PARAMETER AccessRule
    Specifies the access rule to remove. This can be a specific right or a combination of rights.

    .PARAMETER AccessControlType
    Specifies the type of access control to apply. The default is Allow.

    .PARAMETER IncludeObjectTypeName
    Specifies the object types to include in the removal process.

    .PARAMETER IncludeInheritedObjectTypeName
    Specifies the inherited object types to include in the removal process.

    .PARAMETER InheritanceType
    Specifies the inheritance type for the ACL entry.

    .PARAMETER Force
    Forces the removal of inherited ACL entries. By default, inherited entries are skipped.

    .EXAMPLE
    Remove-ADACL -ADObject "CN=User1,DC=example,DC=com" -Principal "CN=User2,DC=example,DC=com" -AccessRule "ReadProperty, WriteProperty" -AccessControlType Allow

    This example removes the ACL entry for User2 to read and write properties on User1's object in the example.com domain.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported.
    #>
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [parameter(ParameterSetName = 'ADObject')][alias('Identity')][Array] $ADObject,

        [parameter(ParameterSetName = 'NTSecurityDescriptor', Mandatory)]
        [parameter(ParameterSetName = 'ACL', Mandatory)]
        [Array] $ACL,

        [parameter(ParameterSetName = 'ACL', Mandatory)]
        [parameter(ParameterSetName = 'ADObject')]
        [string] $Principal,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [Alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [System.Security.AccessControl.AccessControlType] $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [Alias('ObjectTypeName', 'ObjectType')][string[]] $IncludeObjectTypeName,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [Alias('InheritedObjectTypeName', 'InheritedObjectType')][string[]] $IncludeInheritedObjectTypeName,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,

        [parameter(ParameterSetName = 'NTSecurityDescriptor')]
        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [switch] $Force,

        [parameter(ParameterSetName = 'NTSecurityDescriptor', Mandatory)]
        [alias('ActiveDirectorySecurity')][System.DirectoryServices.ActiveDirectorySecurity] $NTSecurityDescriptor
    )
    if (-not $Script:ForestDetails) {
        Write-Verbose "Remove-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }
    if ($PSBoundParameters.ContainsKey('ADObject')) {
        foreach ($Object in $ADObject) {
            $getADACLSplat = @{
                ADObject                                  = $Object
                Bundle                                    = $true
                Resolve                                   = $true
                IncludeActiveDirectoryRights              = $AccessRule
                Principal                                 = $Principal
                AccessControlType                         = $AccessControlType
                IncludeObjectTypeName                     = $IncludeObjectTypeName
                IncludeActiveDirectorySecurityInheritance = $InheritanceType
                IncludeInheritedObjectTypeName            = $IncludeInheritedObjectTypeName
            }
            Remove-EmptyValue -Hashtable $getADACLSplat
            $MYACL = Get-ADACL @getADACLSplat
            $removePrivateACLSplat = @{
                ACL    = $MYACL
                WhatIf = $WhatIfPreference
                Force  = $Force.IsPresent
            }
            Remove-EmptyValue -Hashtable $removePrivateACLSplat
            Remove-PrivateACL @removePrivateACLSplat
        }
    } elseif ($PSBoundParameters.ContainsKey('ACL') -and $PSBoundParameters.ContainsKey('ntSecurityDescriptor')) {
        foreach ($SubACL in $ACL) {
            $removePrivateACLSplat = @{
                ntSecurityDescriptor = $ntSecurityDescriptor
                ACL                  = $SubACL
                WhatIf               = $WhatIfPreference
                Force                = $Force.IsPresent
            }
            Remove-EmptyValue -Hashtable $removePrivateACLSplat
            Remove-PrivateACL @removePrivateACLSplat
        }
    } elseif ($PSBoundParameters.ContainsKey('ACL')) {
        foreach ($SubACL in $ACL) {
            $removePrivateACLSplat = @{
                ACL                            = $SubACL
                Principal                      = $Principal
                AccessRule                     = $AccessRule
                AccessControlType              = $AccessControlType
                IncludeObjectTypeName          = $IncludeObjectTypeName
                IncludeInheritedObjectTypeName = $IncludeInheritedObjectTypeName
                InheritanceType                = $InheritanceType
                WhatIf                         = $WhatIfPreference
                Force                          = $Force.IsPresent
            }
            Remove-EmptyValue -Hashtable $removePrivateACLSplat
            Remove-PrivateACL @removePrivateACLSplat
        }
    }
}