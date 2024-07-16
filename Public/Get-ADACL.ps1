function Get-ADACL {
    <#
    .SYNOPSIS
    Retrieves and filters access control list (ACL) information for Active Directory objects.

    .DESCRIPTION
    This function retrieves and filters access control list (ACL) information for specified Active Directory objects. It allows for detailed filtering based on various criteria such as principal, access control type, object type, inheritance type, and more.

    .PARAMETER ADObject
    Specifies the Active Directory object or objects to retrieve ACL information from.

    .PARAMETER Extended
    Indicates whether to retrieve extended ACL information.

    .PARAMETER ResolveTypes
    Indicates whether to resolve principal types for ACL filtering.

    .PARAMETER Principal
    Specifies the principal to filter ACL information for.

    .PARAMETER Inherited
    Indicates to include only inherited ACLs.

    .PARAMETER NotInherited
    Indicates to include only non-inherited ACLs.

    .PARAMETER Bundle
    Indicates whether to bundle ACL information for each object.

    .PARAMETER AccessControlType
    Specifies the access control type to filter ACL information for.

    .PARAMETER IncludeObjectTypeName
    Specifies the object types to include in ACL filtering.

    .PARAMETER IncludeInheritedObjectTypeName
    Specifies the inherited object types to include in ACL filtering.

    .PARAMETER ExcludeObjectTypeName
    Specifies the object types to exclude in ACL filtering.

    .PARAMETER ExcludeInheritedObjectTypeName
    Specifies the inherited object types to exclude in ACL filtering.

    .PARAMETER IncludeActiveDirectoryRights
    Specifies the Active Directory rights to include in ACL filtering.

    .PARAMETER ExcludeActiveDirectoryRights
    Specifies the Active Directory rights to exclude in ACL filtering.

    .PARAMETER IncludeActiveDirectorySecurityInheritance
    Specifies the inheritance types to include in ACL filtering.

    .PARAMETER ExcludeActiveDirectorySecurityInheritance
    Specifies the inheritance types to exclude in ACL filtering.

    .PARAMETER ADRightsAsArray
    Indicates to return Active Directory rights as an array.

    .EXAMPLE
    Get-ADACL -ADObject 'CN=Users,DC=contoso,DC=com' -ResolveTypes -Principal 'Domain Admins' -Bundle

    Retrieves and bundles ACL information for the 'Domain Admins' principal in the 'Users' container.

    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Identity')][Array] $ADObject,
        [switch] $Extended,
        [alias('ResolveTypes')][switch] $Resolve,
        [string] $Principal,
        [switch] $Inherited,
        [switch] $NotInherited,
        [switch] $Bundle,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [Alias('ObjectTypeName')][string[]] $IncludeObjectTypeName,
        [Alias('InheritedObjectTypeName')][string[]] $IncludeInheritedObjectTypeName,
        [string[]] $ExcludeObjectTypeName,
        [string[]] $ExcludeInheritedObjectTypeName,
        [Alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights[]] $IncludeActiveDirectoryRights,
        [System.DirectoryServices.ActiveDirectoryRights[]] $ExcludeActiveDirectoryRights,
        [Alias('InheritanceType', 'IncludeInheritanceType')][System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $IncludeActiveDirectorySecurityInheritance,
        [Alias('ExcludeInheritanceType')][System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $ExcludeActiveDirectorySecurityInheritance,
        [switch] $ADRightsAsArray
    )
    Begin {
        if (-not $Script:ForestGUIDs) {
            Write-Verbose "Get-ADACL - Gathering Forest GUIDS"
            $Script:ForestGUIDs = Get-WinADForestGUIDs
        }
        if (-not $Script:ForestDetails) {
            Write-Verbose "Get-ADACL - Gathering Forest Details"
            $Script:ForestDetails = Get-WinADForestDetails
        }
        if ($Principal -and $Resolve) {
            $PrincipalRequested = Convert-Identity -Identity $Principal -Verbose:$false
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            $ADObjectData = $null
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
                # if object already has proper security descriptor we don't need to do additional querying
                if ($Object.ntSecurityDescriptor) {
                    $ADObjectData = $Object
                }
                [string] $DistinguishedName = $Object.DistinguishedName
                [string] $CanonicalName = $Object.CanonicalName
                if ($CanonicalName) {
                    $CanonicalName = $CanonicalName.TrimEnd('/')
                }
                [string] $ObjectClass = $Object.ObjectClass
            } elseif ($Object -is [string]) {
                [string] $DistinguishedName = $Object
                [string] $CanonicalName = ''
                [string] $ObjectClass = ''
            } else {
                Write-Warning "Get-ADACL - Object not recognized. Skipping..."
                continue
            }
            if (-not $ADObjectData) {
                $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $DistinguishedName
                $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]
                try {
                    $ADObjectData = Get-ADObject -Identity $DistinguishedName -Properties ntSecurityDescriptor, CanonicalName -ErrorAction Stop -Server $QueryServer
                    # Since we already request an object we might as well use the data and overwrite it if people use the string
                    $ObjectClass = $ADObjectData.ObjectClass
                    $CanonicalName = $ADObjectData.CanonicalName
                    # Real ACL
                    $ACLs = $ADObjectData.ntSecurityDescriptor
                } catch {
                    Write-Warning "Get-ADACL - Path $PathACL - Error: $($_.Exception.Message)"
                    continue
                }
            } else {
                # Real ACL
                $ACLs = $ADObjectData.ntSecurityDescriptor
            }
            $AccessObjects = foreach ($ACL in $ACLs.Access) {
                $SplatFilteredACL = @{
                    ACL                                       = $ACL
                    Resolve                                   = $Resolve
                    Principal                                 = $Principal
                    Inherited                                 = $Inherited
                    NotInherited                              = $NotInherited
                    AccessControlType                         = $AccessControlType
                    IncludeObjectTypeName                     = $IncludeObjectTypeName
                    IncludeInheritedObjectTypeName            = $IncludeInheritedObjectTypeName
                    ExcludeObjectTypeName                     = $ExcludeObjectTypeName
                    ExcludeInheritedObjectTypeName            = $ExcludeInheritedObjectTypeName
                    IncludeActiveDirectoryRights              = $IncludeActiveDirectoryRights
                    ExcludeActiveDirectoryRights              = $ExcludeActiveDirectoryRights
                    IncludeActiveDirectorySecurityInheritance = $IncludeActiveDirectorySecurityInheritance
                    ExcludeActiveDirectorySecurityInheritance = $ExcludeActiveDirectorySecurityInheritance
                    PrincipalRequested                        = $PrincipalRequested
                    Bundle                                    = $Bundle
                }
                Remove-EmptyValue -Hashtable $SplatFilteredACL
                Get-FilteredACL @SplatFilteredACL
            }
            if ($Bundle) {
                if ($Object.CanonicalName) {
                    $CanonicalName = $Object.CanonicalName
                } else {
                    $CanonicalName = ConvertFrom-DistinguishedName -DistinguishedName $DistinguishedName -ToCanonicalName
                }
                [PSCustomObject] @{
                    DistinguishedName = $DistinguishedName
                    CanonicalName     = $CanonicalName
                    ACL               = $ACLs
                    ACLAccessRules    = $AccessObjects
                    Path              = $PathACL
                }
            } else {
                $AccessObjects
            }
        }
    }
    End {}
}