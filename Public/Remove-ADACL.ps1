function Remove-ADACL {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER ADObject
    Parameter description

    .PARAMETER ACL
    Parameter description

    .PARAMETER Principal
    Parameter description

    .PARAMETER AccessRule
    Parameter description

    .PARAMETER AccessControlType
    Parameter description

    .PARAMETER IncludeObjectTypeName
    Parameter description

    .PARAMETER IncludeInheritedObjectTypeName
    Parameter description

    .PARAMETER InheritanceType
    Parameter description

    .PARAMETER Force
    Breaks inheritance on the ACL when the rule has IsInherited set to $true. By default it will skip inherited rules

    .EXAMPLE
    An example

    .NOTES
    General notes
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
        [Alias('ObjectTypeName')][string[]] $IncludeObjectTypeName,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [Alias('InheritedObjectTypeName')][string[]] $IncludeInheritedObjectTypeName,

        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [System.DirectoryServices.ActiveDirectorySecurityInheritance] $InheritanceType,

        [parameter(ParameterSetName = 'NTSecurityDescriptor')]
        [parameter(ParameterSetName = 'ACL')]
        [parameter(ParameterSetName = 'ADObject')]
        [switch] $Force,

        [alias('ActiveDirectorySecurity')][parameter(ParameterSetName = 'NTSecurityDescriptor', Mandatory)][System.DirectoryServices.ActiveDirectorySecurity] $NTSecurityDescriptor
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