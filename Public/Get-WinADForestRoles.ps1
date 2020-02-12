function Get-WinADForestRoles {
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

    #$DomainControllers = Get-WinADForestControllers -Domain $Domain
    if (-not $ExtendedForestInformation) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC
    } else {
        $ForestInformation = $ExtendedForestInformation
    }
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