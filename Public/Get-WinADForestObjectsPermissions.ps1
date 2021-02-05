function Get-WinADForestObjectsPermissions {
    [cmdletBinding()]
    param(
        [parameter(ParameterSetName = 'ObjectType')][ValidateSet('sites', 'subnets', 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals')][string[]] $ObjectType,
        [parameter(ParameterSetName = 'FolderType')][ValidateSet('sites', 'subnets', 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals', 'services')][string[]] $ContainerType,
        [switch] $Owner
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $ForestDN = ConvertTo-DistinguishedName -ToDomain -CanonicalName $ForestInformation.Forest.Name

    if ($ObjectType) {
        if ($ObjectType -contains 'sites') {
            $getADObjectSplat = @{
                Server      = $QueryServer
                LDAPFilter  = '(objectClass=site)'
                SearchBase  = "CN=Sites,CN=Configuration,$($($ForestDN))"
                SearchScope = 'OneLevel'
                Properties  = 'Name', 'CanonicalName', 'DistinguishedName', 'WhenCreated', 'WhenChanged', 'ObjectClass', 'ProtectedFromAccidentalDeletion', 'siteobjectbl', 'gplink', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'Site' -Owner:$Owner
        }
        if ($ObjectType -contains 'subnets') {
            $getADObjectSplat = @{
                Server      = $QueryServer
                LDAPFilter  = '(objectClass=subnet)'
                SearchBase  = "CN=Subnets,CN=Sites,CN=Configuration,$($($ForestDN))"
                SearchScope = 'OneLevel'
                Properties  = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'Subnet' -Owner:$Owner
        }
        if ($ObjectType -contains 'interSiteTransport') {
            $getADObjectSplat = @{
                Server      = $QueryServer
                LDAPFilter  = '(objectClass=interSiteTransport)'
                SearchBase  = "CN=Inter-Site Transports,CN=Sites,CN=Configuration,$($($ForestDN))"
                SearchScope = 'OneLevel'
                Properties  = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'InterSiteTransport' -Owner:$Owner
        }
        if ($ObjectType -contains 'siteLink') {
            $getADObjectSplat = @{
                Server      = $QueryServer
                LDAPFilter  = '(objectClass=siteLink)'
                SearchBase  = "CN=Inter-Site Transports,CN=Sites,CN=Configuration,$($($ForestDN))"
                SearchScope = 'OneLevel'
                Properties  = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'Site' -Owner:$Owner
        }
        if ($ObjectType -contains 'wellKnownSecurityPrincipals') {
            $getADObjectSplat = @{
                Server      = $QueryServer
                LDAPFilter  = '(objectClass=foreignSecurityPrincipal)'
                SearchBase  = "CN=WellKnown Security Principals,CN=Configuration,$($($ForestDN))"
                SearchScope = 'OneLevel'
                Properties  = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'WellKnownSecurityPrincipals' -Owner:$Owner
        }
    } else {
        if ($ContainerType -contains 'sites') {
            $getADObjectSplat = @{
                Server     = $QueryServer
                #LDAPFilter  = '(objectClass=site)'
                Filter     = "*"
                SearchBase = "CN=Sites,CN=Configuration,$($($ForestDN))"
                #SearchScope = 'OneLevel'
                Properties = 'Name', 'CanonicalName', 'DistinguishedName', 'WhenCreated', 'WhenChanged', 'ObjectClass', 'ProtectedFromAccidentalDeletion', 'siteobjectbl', 'gplink', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'Site' -FilterOut -Owner:$Owner
        }
        if ($ContainerType -contains 'subnets') {
            $getADObjectSplat = @{
                Server     = $QueryServer
                #LDAPFilter  = '(objectClass=subnet)'
                Filter     = "*"
                SearchBase = "CN=Subnets,CN=Sites,CN=Configuration,$($($ForestDN))"
                #SearchScope = 'OneLevel'
                Properties = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'Subnet' -Owner:$Owner
        }
        if ($ContainerType -contains 'interSiteTransport') {
            $getADObjectSplat = @{
                Server     = $QueryServer
                #LDAPFilter  = '(objectClass=interSiteTransport)'
                Filter     = '*'
                SearchBase = "CN=Inter-Site Transports,CN=Sites,CN=Configuration,$($($ForestDN))"
                #SearchScope = 'OneLevel'
                Properties = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'InterSiteTransport' -Owner:$Owner
        }
        if ($ContainerType -contains 'siteLink') {
            $getADObjectSplat = @{
                Server     = $QueryServer
                Filter     = '*'
                #LDAPFilter  = '(objectClass=siteLink)'
                SearchBase = "CN=Inter-Site Transports,CN=Sites,CN=Configuration,$($($ForestDN))"
                #SearchScope = 'OneLevel'
                Properties = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'Site' -Owner:$Owner
        }
        if ($ContainerType -contains 'services') {
            $getADObjectSplat = @{
                Server     = $QueryServer
                #LDAPFilter  = '(objectClass=foreignSecurityPrincipal)'
                Filter     = '*'
                SearchBase = "CN=Services,CN=Configuration,$($($ForestDN))"
                #SearchScope = 'OneLevel'
                Properties = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'service' -Owner:$Owner
        }
        if ($ContainerType -contains 'wellKnownSecurityPrincipals') {
            $getADObjectSplat = @{
                Server     = $QueryServer
                #LDAPFilter  = '(objectClass=foreignSecurityPrincipal)'
                Filter     = '*'
                SearchBase = "CN=WellKnown Security Principals,CN=Configuration,$($($ForestDN))"
                #SearchScope = 'OneLevel'
                Properties = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
            }
            Get-ADConfigurationPermission -ADObjectSplat $getADObjectSplat -ObjectType 'WellKnownSecurityPrincipals' -Owner:$Owner
        }
    }
}