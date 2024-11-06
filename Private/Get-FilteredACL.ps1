function Get-FilteredACL {
    <#
    .SYNOPSIS
    Retrieves filtered Active Directory Access Control List (ACL) details based on specified criteria.

    .DESCRIPTION
    This function retrieves and filters Active Directory Access Control List (ACL) details based on the provided criteria. It allows for filtering by various parameters such as access control type, inheritance status, active directory rights, and more.

    .PARAMETER ACL
    Specifies the Active Directory Access Control List (ACL) to filter.

    .PARAMETER Resolve
    If specified, resolves the identity reference in the ACL.

    .PARAMETER Principal
    Specifies the principal to filter by.

    .PARAMETER Inherited
    If specified, includes only inherited ACLs.

    .PARAMETER NotInherited
    If specified, includes only non-inherited ACLs.

    .PARAMETER AccessControlType
    Specifies the type of access control to filter by.

    .PARAMETER IncludeObjectTypeName
    Specifies the object type names to include in the filter.

    .PARAMETER IncludeInheritedObjectTypeName
    Specifies the inherited object type names to include in the filter.

    .PARAMETER ExcludeObjectTypeName
    Specifies the object type names to exclude from the filter.

    .PARAMETER ExcludeInheritedObjectTypeName
    Specifies the inherited object type names to exclude from the filter.

    .PARAMETER IncludeActiveDirectoryRights
    Specifies the Active Directory rights to include in the filter.

    .PARAMETER IncludeActiveDirectoryRightsExactMatch
    Specifies the Active Directory rights to include in the filter as an exact match (all rights must be present).

    .PARAMETER ExcludeActiveDirectoryRights
    Specifies the Active Directory rights to exclude from the filter.

    .PARAMETER IncludeActiveDirectorySecurityInheritance
    Specifies the Active Directory security inheritance types to include in the filter.

    .PARAMETER ExcludeActiveDirectorySecurityInheritance
    Specifies the Active Directory security inheritance types to exclude from the filter.

    .PARAMETER PrincipalRequested
    Specifies the requested principal object.

    .PARAMETER Bundle
    If specified, bundles the filtered ACL details.

    .PARAMETER DistinguishedName
    Specifies the distinguished name of the ACL.
    This parameter is used only to display the distinguished name in the output.

    .PARAMETER SkipDistinguishedName
    If specified, skips the distinguished name in the output.

    .EXAMPLE
    Get-FilteredACL -ACL $ACL -Resolve -Principal "User1" -Inherited -AccessControlType "Allow" -IncludeObjectTypeName "File" -ExcludeInheritedObjectTypeName "Folder" -IncludeActiveDirectoryRights "Read" -ExcludeActiveDirectoryRights "Write" -IncludeActiveDirectorySecurityInheritance "Descendents" -ExcludeActiveDirectorySecurityInheritance "SelfAndChildren" -PrincipalRequested $PrincipalRequested -Bundle
    Retrieves and filters Active Directory Access Control List (ACL) details based on the specified criteria.

    .NOTES
    Additional information about the function.
    #>
    [cmdletBinding()]
    param(
        [System.DirectoryServices.ActiveDirectoryAccessRule] $ACL,
        [alias('ResolveTypes')][switch] $Resolve,
        [string] $Principal,
        [switch] $Inherited,
        [switch] $NotInherited,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [Alias('ObjectTypeName')][string[]] $IncludeObjectTypeName,
        [Alias('InheritedObjectTypeName')][string[]] $IncludeInheritedObjectTypeName,
        [string[]] $ExcludeObjectTypeName,
        [string[]] $ExcludeInheritedObjectTypeName,
        [Alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights[]] $IncludeActiveDirectoryRights,
        [System.DirectoryServices.ActiveDirectoryRights[]] $IncludeActiveDirectoryRightsExactMatch,
        [System.DirectoryServices.ActiveDirectoryRights[]] $ExcludeActiveDirectoryRights,
        [Alias('InheritanceType', 'IncludeInheritanceType')][System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $IncludeActiveDirectorySecurityInheritance,
        [Alias('ExcludeInheritanceType')][System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $ExcludeActiveDirectorySecurityInheritance,
        [PSCustomObject] $PrincipalRequested,
        [switch] $Bundle,
        [string] $DistinguishedName,
        [switch] $SkipDistinguishedName
    )
    # Let's make sure we have all the required data
    if (-not $Script:ForestGUIDs) {
        Write-Verbose "Get-ADACL - Gathering Forest GUIDS"
        $Script:ForestGUIDs = Get-WinADForestGUIDs
    }
    if (-not $Script:ForestDetails) {
        Write-Verbose "Get-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }
    [Array] $ADRights = $ACL.ActiveDirectoryRights -split ', '
    if ($AccessControlType) {
        if ($ACL.AccessControlType -ne $AccessControlType) {
            continue
        }
    }
    if ($Inherited) {
        if ($ACL.IsInherited -eq $false) {
            # if it's not inherited and we require inherited lets continue
            continue
        }
    }
    if ($NotInherited) {
        if ($ACL.IsInherited -eq $true) {
            continue
        }
    }
    if ($IncludeActiveDirectoryRightsExactMatch) {
        # We expect all rights to be found in the ACL (could be more rights than specified, but all of them have to be there)
        [Array] $FoundIncludeList = foreach ($Right in $IncludeActiveDirectoryRightsExactMatch) {
            if ($ADRights -eq $Right) {
                $true
            }
        }
        if ($FoundIncludeList.Count -ne $IncludeActiveDirectoryRightsExactMatch.Count) {
            continue
        }
    }
    if ($IncludeActiveDirectoryRights) {
        $FoundInclude = $false
        foreach ($Right in $ADRights) {
            if ($IncludeActiveDirectoryRights -contains $Right) {
                $FoundInclude = $true
                break
            }
        }
        if (-not $FoundInclude) {
            continue
        }
    }
    if ($ExcludeActiveDirectoryRights) {
        foreach ($Right in $ADRights) {
            $FoundExclusion = $false
            if ($ExcludeActiveDirectoryRights -contains $Right) {
                $FoundExclusion = $true
                break
            }
            if ($FoundExclusion) {
                continue
            }
        }
    }
    if ($IncludeActiveDirectorySecurityInheritance) {
        if ($IncludeActiveDirectorySecurityInheritance -notcontains $ACL.InheritanceType) {
            continue
        }
    }
    if ($ExcludeActiveDirectorySecurityInheritance) {
        if ($ExcludeActiveDirectorySecurityInheritance -contains $ACL.InheritanceType) {
            continue
        }
    }
    $IdentityReference = $ACL.IdentityReference.Value


    $ReturnObject = [ordered] @{ }
    if (-not $SkipDistinguishedName) {
        $ReturnObject['DistinguishedName' ] = $DistinguishedName
    }
    if ($CanonicalName) {
        $ReturnObject['CanonicalName'] = $CanonicalName
    }
    if ($ObjectClass) {
        $ReturnObject['ObjectClass'] = $ObjectClass
    }
    $ReturnObject['AccessControlType'] = $ACL.AccessControlType
    $ReturnObject['Principal'] = $IdentityReference
    if ($Resolve) {
        $IdentityResolve = Get-WinADObject -Identity $IdentityReference -AddType -Verbose:$false -Cache
        if (-not $IdentityResolve) {
            #Write-Verbose "Get-ADACL - Reverting to Convert-Identity for $IdentityReference"
            $ConvertIdentity = Convert-Identity -Identity $IdentityReference -Verbose:$false
            $ReturnObject['PrincipalType'] = $ConvertIdentity.Type
            # it's not really foreignSecurityPrincipal but can't tell what it is...  # https://superuser.com/questions/1067246/is-nt-authority-system-a-user-or-a-group
            $ReturnObject['PrincipalObjectType'] = 'foreignSecurityPrincipal'
            $ReturnObject['PrincipalObjectDomain'] = $ConvertIdentity.DomainName
            $ReturnObject['PrincipalObjectSid'] = $ConvertIdentity.SID
        } else {
            if ($ReturnObject['Principal']) {
                $ReturnObject['Principal'] = $IdentityResolve.Name
            }
            $ReturnObject['PrincipalType'] = $IdentityResolve.Type
            $ReturnObject['PrincipalObjectType'] = $IdentityResolve.ObjectClass
            $ReturnObject['PrincipalObjectDomain' ] = $IdentityResolve.DomainName
            $ReturnObject['PrincipalObjectSid'] = $IdentityResolve.ObjectSID
        }
        if (-not $ReturnObject['PrincipalObjectDomain']) {
            $ReturnObject['PrincipalObjectDomain'] = ConvertFrom-DistinguishedName -DistinguishedName $DistinguishedName -ToDomainCN
        }

        # We compare principal to real principal based on Resolve, we compare both PrincipalName and SID to cover our ground
        if ($PrincipalRequested -and $PrincipalRequested.SID -ne $ReturnObject['PrincipalObjectSid']) {
            continue
        }
    } else {
        # We compare principal to principal as returned without resolve
        if ($Principal -and $Principal -ne $IdentityReference) {
            continue
        }
    }

    $ReturnObject['ObjectTypeName'] = $Script:ForestGUIDs["$($ACL.objectType)"]
    $ReturnObject['InheritedObjectTypeName'] = $Script:ForestGUIDs["$($ACL.inheritedObjectType)"]
    if ($IncludeObjectTypeName) {
        if ($IncludeObjectTypeName -notcontains $ReturnObject['ObjectTypeName']) {
            continue
        }
    }
    if ($IncludeInheritedObjectTypeName) {
        if ($IncludeInheritedObjectTypeName -notcontains $ReturnObject['InheritedObjectTypeName']) {
            continue
        }
    }
    if ($ExcludeObjectTypeName) {
        if ($ExcludeObjectTypeName -contains $ReturnObject['ObjectTypeName']) {
            continue
        }
    }
    if ($ExcludeInheritedObjectTypeName) {
        if ($ExcludeInheritedObjectTypeName -contains $ReturnObject['InheritedObjectTypeName']) {
            continue
        }
    }
    if ($ADRightsAsArray) {
        $ReturnObject['ActiveDirectoryRights'] = $ADRights
    } else {
        $ReturnObject['ActiveDirectoryRights'] = $ACL.ActiveDirectoryRights
    }
    $ReturnObject['InheritanceType'] = $ACL.InheritanceType
    $ReturnObject['IsInherited'] = $ACL.IsInherited

    if ($Extended) {
        $ReturnObject['ObjectType'] = $ACL.ObjectType
        $ReturnObject['InheritedObjectType'] = $ACL.InheritedObjectType
        $ReturnObject['ObjectFlags'] = $ACL.ObjectFlags
        $ReturnObject['InheritanceFlags'] = $ACL.InheritanceFlags
        $ReturnObject['PropagationFlags'] = $ACL.PropagationFlags
    }
    if ($Bundle) {
        $ReturnObject['Bundle'] = $ACL
    }
    [PSCustomObject] $ReturnObject
}