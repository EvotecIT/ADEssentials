function Add-ADACL {
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [parameter(Mandatory, ParameterSetName = 'ActiveDirectoryAccessRule')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')][alias('Identity')][string] $ADObject,

        [Parameter(Mandatory, ParameterSetName = 'ACL')][Array] $ACL,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [string] $Principal,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [System.Security.AccessControl.AccessControlType] $AccessControlType,

        [Parameter(ParameterSetName = 'ACL')]
        [Parameter(ParameterSetName = 'ADObject')]
        [alias('ObjectTypeName')][string] $ObjectType,

        [Parameter(ParameterSetName = 'ACL')]
        [Parameter(ParameterSetName = 'ADObject')]
        [alias('InheritedObjectTypeName')][string] $InheritedObjectType,

        [Parameter(ParameterSetName = 'ACL')]
        [Parameter(ParameterSetName = 'ADObject')]
        [alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,

        [parameter(ParameterSetName = 'ADObject', Mandatory = $false)]
        [parameter(ParameterSetName = 'ACL', Mandatory = $false)]
        [parameter(ParameterSetName = 'ActiveDirectoryAccessRule', Mandatory = $false)]
        [alias('ActiveDirectorySecurity')][System.DirectoryServices.ActiveDirectorySecurity] $NTSecurityDescriptor,

        [parameter(ParameterSetName = 'ActiveDirectoryAccessRule', Mandatory = $true)]
        [System.DirectoryServices.ActiveDirectoryAccessRule] $ActiveDirectoryAccessRule
    )
    if (-not $Script:ForestDetails) {
        Write-Verbose "Add-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }


    if ($PSBoundParameters.ContainsKey('ActiveDirectoryAccessRule')) {
        if (-not $ntSecurityDescriptor) {
            $ntSecurityDescriptor = Get-PrivateACL -ADObject $ADObject
        }
        if (-not $NTSecurityDescriptor) {
            Write-Warning -Message "Add-ADACL - No NTSecurityDescriptor provided and ADObject not found"
            return
        }
        $addPrivateACLSplat = @{
            ActiveDirectoryAccessRule = $ActiveDirectoryAccessRule
            ADObject                  = $ADObject
            ntSecurityDescriptor      = $ntSecurityDescriptor
            WhatIf                    = $WhatIfPreference
        }
        Add-PrivateACL @addPrivateACLSplat
    } elseif ($PSBoundParameters.ContainsKey('NTSecurityDescriptor')) {
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