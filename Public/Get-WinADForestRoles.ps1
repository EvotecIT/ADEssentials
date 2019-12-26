function Get-WinADForestRoles {
    [alias('Get-WinADRoles', 'Get-WinADDomainRoles')]
    param(
        [string] $Domain,
        [switch] $Formatted,
        [string] $Splitter = ', '
    )

    $DomainControllers = Get-WinADForestControllers -Domain $Domain

    $Roles = [ordered] @{
        SchemaMaster         = $null
        DomainNamingMaster   = $null
        PDCEmulator          = $null
        RIDMaster            = $null
        InfrastructureMaster = $null
        IsReadOnly           = $null
        IsGlobalCatalog      = $null
    }

    foreach ($_ in $DomainControllers) {
        if ($_.SchemaMaster -eq $true) {
            $Roles['SchemaMaster'] = if ($null -ne $Roles['SchemaMaster']) { @($Roles['SchemaMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.DomainNamingMaster -eq $true) {
            $Roles['DomainNamingMaster'] = if ($null -ne $Roles['DomainNamingMaster']) { @($Roles['DomainNamingMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.PDCEmulator -eq $true) {
            $Roles['PDCEmulator'] = if ($null -ne $Roles['PDCEmulator']) { @($Roles['PDCEmulator']) + $_.HostName } else { $_.HostName }
        }
        if ($_.RIDMaster -eq $true) {
            $Roles['RIDMaster'] = if ($null -ne $Roles['RIDMaster']) { @($Roles['RIDMaster']) + $_.HostName } else { $_.HostName }
        }
        if ($_.InfrastructureMaster -eq $true) {
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