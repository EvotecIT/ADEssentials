function Get-WinADForestRoles {
    <#
    .SYNOPSIS
    Lists all the forest roles for the chosen forest. By default uses current forest.

    .DESCRIPTION
    Lists all the forest roles for the chosen forest. By default uses current forest.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers, by default there are no exclusions

    .PARAMETER IncludeDomainControllers
    Include only specific domain controllers, by default all domain controllers are included

    .PARAMETER SkipRODC
    Skip Read-Only Domain Controllers. By default all domain controllers are included.

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .PARAMETER Formatted
    Returns objects in formatted way

    .PARAMETER Splitter
    Character to use as splitter/joiner in formatted output

    .EXAMPLE
    $Roles = Get-WinADForestRoles
    $Roles | ft *

    .NOTES
    General notes
    #>
    [alias('Get-WinADRoles', 'Get-WinADDomainRoles')]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [switch] $Formatted,
        [string] $Splitter = ', ',
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    $Roles = [ordered] @{
        SchemaMaster         = $null
        DomainNamingMaster   = $null
        PDCEmulator          = $null
        RIDMaster            = $null
        InfrastructureMaster = $null
        IsReadOnly           = $null
        IsGlobalCatalog      = $null
    }

    foreach ($_ in $ForestInformation.ForestDomainControllers) {
        if ($_.IsSchemaMaster -eq $true) {
            $Roles['SchemaMaster'] = if ($null -ne $Roles['SchemaMaster']) { @($Roles['SchemaMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.IsDomainNamingMaster -eq $true) {
            $Roles['DomainNamingMaster'] = if ($null -ne $Roles['DomainNamingMaster']) { @($Roles['DomainNamingMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.IsPDC -eq $true) {
            $Roles['PDCEmulator'] = if ($null -ne $Roles['PDCEmulator']) { @($Roles['PDCEmulator']) + $_.HostName } else { $_.HostName }
        }
        if ($_.IsRIDMaster -eq $true) {
            $Roles['RIDMaster'] = if ($null -ne $Roles['RIDMaster']) { @($Roles['RIDMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.IsInfrastructureMaster -eq $true) {
            $Roles['InfrastructureMaster'] = if ($null -ne $Roles['InfrastructureMaster']) { @($Roles['InfrastructureMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.IsReadOnly -eq $true) {
            $Roles['IsReadOnly'] = if ($null -ne $Roles['IsReadOnly']) { @($Roles['IsReadOnly']) + $_.HostName } else { $_.HostName }
        }
        if ($_.IsGlobalCatalog -eq $true) {
            $Roles['IsGlobalCatalog'] = if ($null -ne $Roles['IsGlobalCatalog']) { @($Roles['IsGlobalCatalog']) + $_.HostName } else { $_.HostName }
        }
    }
    if ($Formatted) {
        foreach ($_ in ([string[]] $Roles.Keys)) {
            $Roles[$_] = $Roles[$_] -join $Splitter
        }
    }
    $Roles
}