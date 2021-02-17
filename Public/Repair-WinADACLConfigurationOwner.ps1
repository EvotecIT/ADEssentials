function Repair-WinADACLConfigurationOwner {
    <#
    .SYNOPSIS
    Fixes all owners of certain object type (site,subnet,sitelink,interSiteTransport,wellKnownSecurityPrincipal) to be Enterprise Admins

    .DESCRIPTION
    Fixes all owners of certain object type (site,subnet,sitelink,interSiteTransport,wellKnownSecurityPrincipal) to be Enterprise Admins

    .PARAMETER ObjectType
    Gets owners from one or multiple types (and only that type). Possible choices are sites, subnets, interSiteTransport, siteLink, wellKnownSecurityPrincipals

    .PARAMETER ContainerType
    Gets owners from one or multiple types (including containers and anything below it). Possible choices are sites, subnets, interSiteTransport, siteLink, wellKnownSecurityPrincipals, services

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .PARAMETER LimitProcessing
    Provide limit of objects that will be fixed in a single run

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [cmdletBinding(DefaultParameterSetName = 'ObjectType', SupportsShouldProcess)]
    param(
        [parameter(ParameterSetName = 'ObjectType', Mandatory)][ValidateSet('site', 'subnet', 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipal')][string[]] $ObjectType,
        [parameter(ParameterSetName = 'FolderType', Mandatory)][ValidateSet('site', 'subnet', 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipal', 'service')][string[]] $ContainerType,

        [string] $Forest,
        [System.Collections.IDictionary] $ExtendedForestInformation,

        [int] $LimitProcessing = [int32]::MaxValue
    )

    $ADAdministrativeGroups = Get-ADADministrativeGroups -Type DomainAdmins, EnterpriseAdmins -Forest $Forest -ExtendedForestInformation $ForestInformation

    $getWinADACLConfigurationSplat = @{
        ContainerType             = $ContainerType
        ObjectType                = $ObjectType
        Owner                     = $true
        Forest                    = $Forest
        ExtendedForestInformation = $ExtendedForestInformation
    }
    Remove-EmptyValue -Hashtable $getWinADACLConfigurationSplat

    Get-WinADACLConfiguration @getWinADACLConfigurationSplat | Where-Object {
        if ($_.OwnerType -ne 'Administrative' -and $_.OwnerType -ne 'WellKnownAdministrative') {
            $_
        }
    } | Select-Object -First $LimitProcessing | ForEach-Object {
        $ADObject = $_
        $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $_.DistinguishedName
        $EnterpriseAdmin = $ADAdministrativeGroups[$DomainName]['EnterpriseAdmins']
        Set-ADACLOwner -ADObject $ADObject.DistinguishedName -Principal $EnterpriseAdmin
    }
}