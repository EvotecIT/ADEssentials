function Get-FilteredACL {
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
        [System.DirectoryServices.ActiveDirectoryRights[]] $ExcludeActiveDirectoryRights,
        [Alias('InheritanceType', 'IncludeInheritanceType')][System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $IncludeActiveDirectorySecurityInheritance,
        [Alias('ExcludeInheritanceType')][System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $ExcludeActiveDirectorySecurityInheritance,
        [PSCustomObject] $PrincipalRequested,
        [switch] $Bundle
    )
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
    $ReturnObject['DistinguishedName' ] = $DistinguishedName
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