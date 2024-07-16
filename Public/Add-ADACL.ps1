function Add-ADACL {
    <#
    .SYNOPSIS
    Adds an access control entry (ACE) to one or more Active Directory objects or security principals.

    .DESCRIPTION
    The Add-ADACL function allows you to add an ACE to Active Directory objects or security principals. It provides flexibility to specify the object, ACL, principal, access rule, access control type, object type, inherited object type, inheritance type, and NT security descriptor.

    .PARAMETER ADObject
    Specifies the Active Directory object to which the ACE will be added.

    .PARAMETER ACL
    Specifies the access control list (ACL) to be added.

    .PARAMETER Principal
    Specifies the security principal to which the ACE applies.

    .PARAMETER AccessRule
    Specifies the access rights granted by the ACE.

    .PARAMETER AccessControlType
    Specifies whether the ACE allows or denies access.

    .PARAMETER ObjectType
    Specifies the type of object to which the ACE applies.

    .PARAMETER InheritedObjectType
    Specifies the type of inherited object to which the ACE applies.

    .PARAMETER InheritanceType
    Specifies the inheritance type for the ACE.

    .PARAMETER NTSecurityDescriptor
    Specifies the NT security descriptor for the ACE.

    .PARAMETER ActiveDirectoryAccessRule
    Specifies the Active Directory access rule to be added.

    .EXAMPLE
    Add-ADACL -ADObject 'CN=TestUser,OU=Users,DC=contoso,DC=com' -Principal 'Contoso\HRAdmin' -AccessRule 'Read' -AccessControlType 'Allow' -ObjectType 'User' -InheritedObjectType 'Group' -InheritanceType 'All' -NTSecurityDescriptor $NTSecurityDescriptor

    This example adds an ACE to the 'TestUser' object in the 'Users' OU, granting 'Read' access to the 'HRAdmin' security principal.

    .EXAMPLE
    Add-ADACL -ACL $ACL -Principal 'Contoso\FinanceAdmin' -AccessRule 'Write' -AccessControlType 'Allow' -ObjectType 'Group' -InheritedObjectType 'User' -InheritanceType 'None' -NTSecurityDescriptor $NTSecurityDescriptor

    This example adds an ACE from the specified ACL to the 'FinanceAdmin' security principal, granting 'Write' access.

    .NOTES
    Ensure that the necessary permissions are in place to modify the security settings of the specified objects or principals.
    #>
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
                ACL                  = $MYACL
                ADObject             = $Object
                Principal            = $Principal
                WhatIf               = $WhatIfPreference
                AccessRule           = $AccessRule
                AccessControlType    = $AccessControlType
                ObjectType           = $ObjectType
                InheritedObjectType  = $InheritedObjectType
                InheritanceType      = if ($InheritanceType) { $InheritanceType } else { $null }
                NTSecurityDescriptor = $MYACL.ACL
            }
            Add-PrivateACL @addPrivateACLSplat
        }
    } elseif ($PSBoundParameters.ContainsKey('ACL')) {
        foreach ($SubACL in $ACL) {
            $addPrivateACLSplat = @{
                ACL                  = $SubACL
                Principal            = $Principal
                WhatIf               = $WhatIfPreference
                AccessRule           = $AccessRule
                AccessControlType    = $AccessControlType
                ObjectType           = $ObjectType
                InheritedObjectType  = $InheritedObjectType
                InheritanceType      = if ($InheritanceType) { $InheritanceType } else { $null }
                NTSecurityDescriptor = $SubACL.ACL
            }
            Add-PrivateACL @addPrivateACLSplat
        }
    }
}