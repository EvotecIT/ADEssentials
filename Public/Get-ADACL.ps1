function Get-ADACL {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)][Array] $ADObject,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [Object] $Server,
        [string] $ForestName,
        [switch] $Extended,
        [switch] $ResolveTypes,
        [switch] $Inherited,
        [switch] $NotInherited,
        [switch] $Bundle,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [string[]] $IncludeObjectTypeName,
        [string[]] $IncludeInheritedObjectTypeName,
        [string[]] $ExcludeObjectTypeName,
        [string[]] $ExcludeInheritedObjectTypeName,
        [System.DirectoryServices.ActiveDirectoryRights[]] $IncludeActiveDirectoryRights,
        [System.DirectoryServices.ActiveDirectoryRights[]] $ExcludeActiveDirectoryRights,
        [System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $IncludeActiveDirectorySecurityInheritance,
        [System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $ExcludeActiveDirectorySecurityInheritance,
        [switch] $ADRightsAsArray
    )
    Begin {
        if (-not $Script:ForestGUIDs) {
            Write-Verbose "Get-ADACL - Gathering Forest GUIDS"
            $Script:ForestGUIDs = Get-WinADForestGUIDs
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
                [string] $DistinguishedName = $Object.DistinguishedName
                [string] $CanonicalName = $Object.CanonicalName
                [string] $ObjectClass = $Object.ObjectClass
            } elseif ($Object -is [string]) {
                [string] $DistinguishedName = $Object
                [string] $CanonicalName = ''
                [string] $ObjectClass = ''
            } else {
                Write-Warning "Get-ADACL - Object not recognized. Skipping..."
                continue
            }
            $DNConverted = (ConvertFrom-DistinguishedName -DistinguishedName $DistinguishedName -ToDC) -replace '=' -replace ','
            if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                Write-Verbose "Get-ADACL - Enabling PSDrives for $DistinguishedName to $DNConverted"
                New-ADForestDrives -ForestName $ForestName #-ObjectDN $Object
                if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                    Write-Warning "Get-ADACL - Drive $DNConverted not mapped. Terminating..."
                    return
                }
            }
            Write-Verbose "Get-ADACL - Getting ACL from $DistinguishedName"
            try {
                $PathACL = "$DNConverted`:\$($DistinguishedName)"
                $ACLs = Get-Acl -Path $PathACL -ErrorAction Stop
            } catch {
                Write-Warning "Get-ADACL - Path $PathACL - Error: $($_.Exception.Message)"
            }
            $AccessObjects = foreach ($ACL in $ACLs.Access) {
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
                if ($ResolveTypes) {
                    $IdentityResolve = Get-WinADObject -Identity $IdentityReference
                    $ReturnObject['PrincipalType'] = $IdentityResolve.Type
                    $ReturnObject['PrincipalObjectType'] = $IdentityResolve.ObjectClass
                    $ReturnObject['PrincipalObjectDomain' ] = $IdentityResolve.DomainName
                    $ReturnObject['PrincipalObjectSid'] = $IdentityResolve.ObjectSID
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
            if ($Bundle) {
                [PSCustomObject] @{
                    DistinguishedName = $DistinguishedName
                    CanonicalName     = $Object.CanonicalName
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