function Set-WinADForestACLOwner {
    <#
    .SYNOPSIS
    Replaces the owner of the ACLs on all the objects (to Domain Admins) in the forest (or specific domain) that are not Administrative or WellKnownAdministrative.

    .DESCRIPTION
    Replaces the owner of the ACLs on all the objects (to Domain Admins) in the forest (or specific domain) that are not Administrative or WellKnownAdministrative.

    .PARAMETER IncludeOwnerType
    Defines which object owners are to be included in the replacement. Options are: 'WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown'

    .PARAMETER ExcludeOwnerType
    Defines which object owners are to be included in the replacement. Options are: 'WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown'

    .PARAMETER LimitProcessing
    Parameter description

    .PARAMETER Principal
    Defines the principal to be used as the new owner. By default those are Domain Admins for all objects. If you want to use a different principal, you can specify it here. Not really useful as the idea is to always have Domain Admins as object owners.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .PARAMETER ADAdministrativeGroups
    Ability to provide AD Administrative Groups from another command to speed up processing

    .EXAMPLE
    Set-WinADForestACLOwner -WhatIf -Verbose -LimitProcessing 2 -IncludeOwnerType 'NotAdministrative', 'Unknown'

    .NOTES
    General notes
    #>
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Include')]
    param(
        [parameter(Mandatory, ParameterSetName = 'Include')][validateSet('WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown')][string[]] $IncludeOwnerType,
        [parameter(Mandatory, ParameterSetName = 'Exclude')][validateSet('WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown')][string[]] $ExcludeOwnerType,
        [int] $LimitProcessing,

        [string] $Principal,

        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [System.Collections.IDictionary] $ADAdministrativeGroups
    )

    $Count = 0
    $getWinADACLForestSplat = @{
        Owner                     = $true
        IncludeOwnerType          = $IncludeOwnerType
        ExcludeOwnerType          = $ExcludeOwnerType
        Forest                    = $Forest
        IncludeDomains            = $IncludeDomains
        ExcludeDomains            = $ExcludeDomains
        ExtendedForestInformation = $ExtendedForestInformation
    }
    Remove-EmptyValue -Hashtable $getWinADACLForestSplat

    if (-not $ADAdministrativeGroups) {
        $ADAdministrativeGroups = Get-ADADministrativeGroups -Type DomainAdmins, EnterpriseAdmins -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    }

    Get-WinADACLForest @getWinADACLForestSplat | ForEach-Object {
        if (-not $Principal) {
            $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $_.DistinguishedName
            $Principal = $ADAdministrativeGroups[$DomainName]['DomainAdmins']
        }
        $Count += 1
        Set-ADACLOwner -ADObject $_.DistinguishedName -Principal $Principal
        if ($LimitProcessing -gt 0 -and $Count -ge $LimitProcessing) {
            break
        }
    }
}