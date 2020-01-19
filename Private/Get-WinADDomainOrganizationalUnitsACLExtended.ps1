function Get-WinADDomainOrganizationalUnitsACLExtended {
    [cmdletbinding()]
    param(
        [Array] $DomainOrganizationalUnitsClean,
        [string] $Domain = $Env:USERDNSDOMAIN,
        [string] $NetBiosName,
        [string] $RootDomainNamingContext,
        [System.Collections.IDictionary] $GUID,
        [System.Collections.IDictionary] $ForestObjectsCache,
        $Server
    )
    if (-not $GUID) {
        $GUID = @{ }
    }
    if (-not $ForestObjectsCache) {
        $ForestObjectsCache = @{ }
    }
    $OUs = @(
        #@{ Name = 'Root'; Value = $RootDomainNamingContext }
        foreach ($OU in $DomainOrganizationalUnitsClean) {
            @{ Name = 'Organizational Unit'; Value = $OU.DistinguishedName }
        }
    )
    if ($Server) {
        $null = New-PSDrive -Name $NetBiosName -Root '' -PsProvider ActiveDirectory -Server $Server
    } else {
        $null = New-PSDrive -Name $NetBiosName -Root '' -PsProvider ActiveDirectory -Server $Domain
    }
    foreach ($OU in $OUs) {

        $ACLs = Get-Acl -Path "$NetBiosName`:\$($OU.Value)" | Select-Object -ExpandProperty Access
        foreach ($ACL in $ACLs) {
            if ($ACL.IdentityReference -like '*\*') {
                $TemporaryIdentity = $ForestObjectsCache["$($ACL.IdentityReference)"]
                $IdentityReferenceType = $TemporaryIdentity.ObjectClass
                $IdentityReference = $ACL.IdentityReference.Value
            } elseif ($ACL.IdentityReference -like '*-*-*-*') {
                $ConvertedSID = ConvertFrom-SID -sid $ACL.IdentityReference
                $TemporaryIdentity = $ForestObjectsCache["$($ConvertedSID.Name)"]
                $IdentityReferenceType = $TemporaryIdentity.ObjectClass
                $IdentityReference = $ConvertedSID.Name
            } else {
                $IdentityReference = $ACL.IdentityReference
                $IdentityReferenceType = 'Unknown'
            }
            [PSCustomObject] @{
                'Distinguished Name'        = $OU.Value
                'Type'                      = $OU.Name
                'AccessControlType'         = $ACL.AccessControlType
                'Rights'                    = $Global:Rights["$($ACL.ActiveDirectoryRights)"]["$($ACL.ObjectFlags)"]
                'ObjectType Name'           = $GUID["$($ACL.objectType)"]
                'Inherited ObjectType Name' = $GUID["$($ACL.inheritedObjectType)"]
                'ActiveDirectoryRights'     = $ACL.ActiveDirectoryRights
                'InheritanceType'           = $ACL.InheritanceType
                #'ObjectType'                = $ACL.ObjectType
                #'InheritedObjectType'       = $ACL.InheritedObjectType
                'ObjectFlags'               = $ACL.ObjectFlags
                'IdentityReference'         = $IdentityReference
                'IdentityReferenceType'     = $IdentityReferenceType
                'IsInherited'               = $ACL.IsInherited
                'InheritanceFlags'          = $ACL.InheritanceFlags
                'PropagationFlags'          = $ACL.PropagationFlags

            }
        }
    }
}