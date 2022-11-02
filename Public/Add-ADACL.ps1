function Add-ADACL {
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ADObject')][alias('Identity')][string] $ADObject,

        [Parameter(Mandatory, ParameterSetName = 'ACL')][Array] $ACL,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [string] $Principal,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [System.Security.AccessControl.AccessControlType] $AccessControlType,

        [Parameter(ParameterSetName = 'ACL')]
        [Parameter(ParameterSetName = 'ADObject')]
        [string] $ObjectType,

        [Parameter(ParameterSetName = 'ACL')]
        [Parameter(ParameterSetName = 'ADObject')]
        [string] $InheritedObjectType,

        [Parameter(ParameterSetName = 'ACL')]
        [Parameter(ParameterSetName = 'ADObject')]
        [System.DirectoryServices.ActiveDirectorySecurityInheritance] $InheritanceType,

        [parameter(ParameterSetName = 'ADObject', Mandatory = $false)]
        [parameter(ParameterSetName = 'ACL', Mandatory = $false)]
        [alias('ActiveDirectorySecurity')][System.DirectoryServices.ActiveDirectorySecurity] $NTSecurityDescriptor
    )
    if (-not $Script:ForestDetails) {
        Write-Verbose "Add-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }
    if ($PSBoundParameters.ContainsKey('NTSecurityDescriptor')) {
        $addPrivateACLSplat = @{
            ntSecurityDescriptor = $ntSecurityDescriptor
            ADObject             = $ADObject
            Principal            = $Principal
            WhatIf               = $WhatIfPreference
            AccessRule           = $AccessRule
            AccessControlType    = $AccessControlType
            ObjectType           = $ObjectType
            InheritedObjectType  = $InheritedObjectType
            InheritanceType      = if ($InheritanceType) { $InheritanceType } else { $null }
        }
        Add-PrivateACL @addPrivateACLSplat
    } elseif ($PSBoundParameters.ContainsKey('ADObject')) {
        foreach ($Object in $ADObject) {
            $MYACL = Get-ADACL -ADObject $Object -Verbose -NotInherited -Bundle
            $addPrivateACLSplat = @{
                ACL                 = $MYACL
                ADObject            = $Object
                Principal           = $Principal
                WhatIf              = $WhatIfPreference
                AccessRule          = $AccessRule
                AccessControlType   = $AccessControlType
                ObjectType          = $ObjectType
                InheritedObjectType = $InheritedObjectType
                InheritanceType     = if ($InheritanceType) { $InheritanceType } else { $null }
            }
            Add-PrivateACL @addPrivateACLSplat
        }
    } elseif ($PSBoundParameters.ContainsKey('ACL')) {
        foreach ($SubACL in $ACL) {
            $addPrivateACLSplat = @{
                ACL                 = $SubACL
                Principal           = $Principal
                WhatIf              = $WhatIfPreference
                AccessRule          = $AccessRule
                AccessControlType   = $AccessControlType
                ObjectType          = $ObjectType
                InheritedObjectType = $InheritedObjectType
                InheritanceType     = if ($InheritanceType) { $InheritanceType } else { $null }
            }
            Add-PrivateACL @addPrivateACLSplat
        }
    }
}