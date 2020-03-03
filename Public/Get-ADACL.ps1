function Get-ADACL {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][Array] $ADObject,
        [string] $Domain = $Env:USERDNSDOMAIN,
        # [Microsoft.ActiveDirectory.Management.ADDomainController] $Server,
        [Object] $Server,
        [string] $ForestName,
        [switch] $Extended,
        [switch] $ResolveTypes,
        [switch] $Inherited,
        [switch] $NotInherited,
        [System.DirectoryServices.ActiveDirectoryRights[]] $IncludeActiveDirectoryRights,
        [System.DirectoryServices.ActiveDirectoryRights[]] $ExcludeActiveDirectoryRights,
        [System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $IncludeActiveDirectorySecurityInheritance,
        [System.DirectoryServices.ActiveDirectorySecurityInheritance[]] $ExcludeActiveDirectorySecurityInheritance
    )
    Begin {
        if (-not $Script:ForestGUIDs) {
            Write-Verbose "Get-ADACL - Gathering Forest GUIDS"
            $Script:ForestGUIDs = Get-WinADForestGUIDs
        }
        if ($ResolveTypes) {
            if (-not $Script:ForestCache) {
                Write-Verbose "Get-ADACL - Building Cache"
                $Script:ForestCache = Get-WinADCache -ByNetBiosName
            }
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
                [string] $DistinguishedName = $Object.DistinguishedName
                [string] $CanonicalName = $Object.CanonicalName
            } elseif ($Object -is [string]) {
                [string] $DistinguishedName = $Object
                [string] $CanonicalName = ''
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
                $ACLs = Get-Acl -Path $PathACL -ErrorAction Stop | Select-Object -ExpandProperty Access
            } catch {
                Write-Warning "Get-ADACL - Path $PathACL - Error: $($_.Exception.Message)"
            }
            foreach ($ACL in $ACLs) {
                [Array] $ADRights = $ACL.ActiveDirectoryRights -split ', '
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

                if ($ACL.IdentityReference -like '*\*') {
                    if ($ResolveTypes -and $Script:ForestCache ) {
                        $TemporaryIdentity = $Script:ForestCache["$($ACL.IdentityReference)"]
                        $IdentityReferenceType = $TemporaryIdentity.ObjectClass
                        $IdentityReference = $ACL.IdentityReference.Value
                    } else {
                        $IdentityReferenceType = ''
                        $IdentityReference = $ACL.IdentityReference.Value
                    }
                } elseif ($ACL.IdentityReference -like '*-*-*-*') {
                    $ConvertedSID = ConvertFrom-SID -sid $ACL.IdentityReference
                    if ($ResolveTypes -and $Script:ForestCache) {
                        $TemporaryIdentity = $Script:ForestCache["$($ConvertedSID.Name)"]
                        $IdentityReferenceType = $TemporaryIdentity.ObjectClass
                    } else {
                        $IdentityReferenceType = ''
                    }
                    $IdentityReference = $ConvertedSID.Name
                } else {
                    $IdentityReference = $ACL.IdentityReference
                    $IdentityReferenceType = 'Unknown'
                }
                $ReturnObject = [ordered] @{ }
                $ReturnObject['DistinguishedName' ] = $DistinguishedName
                if ($CanonicalName) {
                    $ReturnObject['CanonicalName'] = $CanonicalName
                }
                $ReturnObject['AccessControlType'] = $ACL.AccessControlType
                $ReturnObject['Principal'] = $IdentityReference
                if ($ResolveTypes) {
                    $ReturnObject['PrincipalType'] = $IdentityReferenceType
                }
                $ReturnObject['ObjectTypeName'] = $Script:ForestGUIDs["$($ACL.objectType)"]
                $ReturnObject['InheritedObjectTypeName'] = $Script:ForestGUIDs["$($ACL.inheritedObjectType)"]
                $ReturnObject['ActiveDirectoryRights'] = $ACL.ActiveDirectoryRights
                $ReturnObject['InheritanceType'] = $ACL.InheritanceType
                $ReturnObject['IsInherited'] = $ACL.IsInherited

                if ($Extended) {
                    $ReturnObject['ObjectType'] = $ACL.ObjectType
                    $ReturnObject['InheritedObjectType'] = $ACL.InheritedObjectType
                    $ReturnObject['ObjectFlags'] = $ACL.ObjectFlags
                    $ReturnObject['InheritanceFlags'] = $ACL.InheritanceFlags
                    $ReturnObject['PropagationFlags'] = $ACL.PropagationFlags
                }
                [PSCustomObject] $ReturnObject
            }
            <#
                [PSCustomObject] @{
                    Type          = $ACL.AccessControlType
                    Principal     = $IdentityReference
                    Access        = ''
                    InheritedFrom = ''
                    AppliesTo     = ''
                }
                #>
        }
    }

    End {

    }
}