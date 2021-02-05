function Get-WinADACLConfiguration {
    <#
    .SYNOPSIS
    Gets permissions or owners from configuration partition

    .DESCRIPTION
    Gets permissions or owners from configuration partition for one or multiple types

    .PARAMETER ObjectType
    Gets permissions or owners from one or multiple types (and only that type). Possible choices are sites, subnets, interSiteTransport, siteLink, wellKnownSecurityPrincipals

    .PARAMETER ContainerType
    Gets permissions or owners from one or multiple types (including containers and anything below it). Possible choices are sites, subnets, interSiteTransport, siteLink, wellKnownSecurityPrincipals, services

    .PARAMETER Owner
    Queries for Owners, instead of permissions

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .EXAMPLE
    Get-WinADACLConfiguration -ObjectType 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals' | Format-Table

    .EXAMPLE
    Get-WinADACLConfiguration -ContainerType 'sites' -Owner | Format-Table

    .NOTES
    General notes
    #>
    [cmdletBinding(DefaultParameterSetName = 'ObjectType')]
    param(
        [parameter(ParameterSetName = 'ObjectType', Mandatory)][ValidateSet('sites', 'subnets', 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals')][string[]] $ObjectType,
        [parameter(ParameterSetName = 'FolderType', Mandatory)][ValidateSet('sites', 'subnets', 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals', 'services')][string[]] $ContainerType,
        [switch] $Owner,

        [string] $Forest,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
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