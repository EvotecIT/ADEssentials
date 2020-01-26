function Get-ADACL {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][Array] $ADObject,
        [string] $Domain = $Env:USERDNSDOMAIN,
        # [Microsoft.ActiveDirectory.Management.ADDomainController] $Server,
        [Object] $Server,
        [string] $ForestName,
        [switch] $Extended
    )
    Begin {
        if (-not $Script:ForestGUIDs) {
            Write-Verbose "Get-ADACL - Gathering Forest GUIDS"
            $Script:ForestGUIDs = Get-WinADForestGUIDs
        }
        if (-not $Script:ForestCache) {
            Write-Verbose "Get-ADACL - Building Cache"
            $Script:ForestCache = Get-WinADCache -ByNetBiosName
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            #if ($Object -is [string]) {

            #} else {

            #}

            $DNConverted = (ConvertFrom-DistinguishedName -DistinguishedName $Object -ToDC) -replace '=' -replace ','
            if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                Write-Verbose "Get-ADACL - Enabling PSDrives for $Object"
                New-ADForestDrives -ForestName $ForestName #-ObjectDN $Object
                if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                    Write-Warning "Get-ADACL - Drive $DNConverted not mapped. Terminating..."
                    return
                }
            }
            Write-Verbose "Get-ADACL - Getting ACL from $Object"
            try {
                $PathACL = "$DNConverted`:\$($Object)"
                $ACLs = Get-Acl -Path $PathACL | Select-Object -ExpandProperty Access
            } catch {
                Write-Warning "Get-ADACL - Path $PathACL - Error: $($_.Exception.Message)"
            }
            foreach ($ACL in $ACLs) {
                if ($ACL.IdentityReference -like '*\*') {
                    if ( $Script:ForestCache ) {
                        $TemporaryIdentity = $Script:ForestCache["$($ACL.IdentityReference)"]
                        $IdentityReferenceType = $TemporaryIdentity.ObjectClass
                        $IdentityReference = $ACL.IdentityReference.Value
                    } else {
                        $IdentityReferenceType = ''
                        $IdentityReference = $ACL.IdentityReference.Value
                    }
                } elseif ($ACL.IdentityReference -like '*-*-*-*') {
                    $ConvertedSID = ConvertFrom-SID -sid $ACL.IdentityReference
                    if ($Script:ForestCache) {
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

                #$Rights = try {
                #    $Script:Rights["$($ACL.ActiveDirectoryRights)"]["$($ACL.ObjectFlags)"]
                #} catch {
                #    "$($ACL.ActiveDirectoryRights) /$($ACL.ObjectFlags) "
                #}

                $ReturnObject = [ordered] @{
                    'DistinguishedName'       = $Object
                    'AccessControlType'       = $ACL.AccessControlType
                    #'Rights'                  = $Rights
                    'Principal'               = $IdentityReference
                    'PrincipalType'           = $IdentityReferenceType
                    'ObjectTypeName'          = $Script:ForestGUIDs["$($ACL.objectType)"]
                    'InheritedObjectTypeName' = $Script:ForestGUIDs["$($ACL.inheritedObjectType)"]
                    'ActiveDirectoryRights'   = $ACL.ActiveDirectoryRights
                    'InheritanceType'         = $ACL.InheritanceType
                    'IsInherited'             = $ACL.IsInherited
                }
                if ($Extended) {
                    $ReturnObject['ObjectType'] = $ACL.ObjectType
                    $ReturnObject['InheritedObjectType'] = $ACL.InheritedObjectType
                    $ReturnObject['ObjectFlags'] = $ACL.ObjectFlags
                    $ReturnObject['InheritanceFlags'] = $ACL.InheritanceFlags
                    $ReturnObject['PropagationFlags'] = $ACL.PropagationFlags
                }
                [PSCustomObject] $ReturnObject

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
    }
    End {

    }
}