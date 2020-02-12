function Test-ADRolesAvailability {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Roles = Get-WinADForestRoles -Forest $Forest -IncludeDomains $IncludeDomains -IncludeDomainControllers $IncludeDomainControllers -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    if ($IncludeDomains) {
        [PSCustomObject] @{
            PDCEmulator                      = $Roles['PDCEmulator']
            PDCEmulatorAvailability          = if ($Roles['PDCEmulator']) { (Test-NetConnection -ComputerName $Roles['PDCEmulator']).PingSucceeded } else { $false }
            RIDMaster                        = $Roles['RIDMaster']
            RIDMasterAvailability            = if ($Roles['RIDMaster']) { (Test-NetConnection -ComputerName $Roles['RIDMaster']).PingSucceeded } else { $false }
            InfrastructureMaster             = $Roles['InfrastructureMaster']
            InfrastructureMasterAvailability = if ($Roles['InfrastructureMaster']) { (Test-NetConnection -ComputerName $Roles['InfrastructureMaster']).PingSucceeded } else { $false }
        }
    } else {
        [PSCustomObject] @{
            SchemaMaster                   = $Roles['SchemaMaster']
            SchemaMasterAvailability       = if ($Roles['SchemaMaster']) { (Test-NetConnection -ComputerName $Roles['SchemaMaster']).PingSucceeded } else { $false }
            DomainNamingMaster             = $Roles['DomainNamingMaster']
            DomainNamingMasterAvailability = if ($Roles['DomainNamingMaster']) { (Test-NetConnection -ComputerName $Roles['DomainNamingMaster']).PingSucceeded } else { $false }
        }
    }
}

#Test-ADRolesAvailability