function Test-ADRolesAvailability {
    <#
    .SYNOPSIS
    Tests the availability of Active Directory roles across domain controllers in a specified forest.

    .DESCRIPTION
    This cmdlet tests the availability of Active Directory roles across domain controllers in a specified forest. It returns a custom object with details about the role, the hostname of the domain controller, and the status of the connection to the domain controller.

    .PARAMETER Forest
    The name of the forest to test roles for. If not specified, the current user's forest is used.

    .PARAMETER ExcludeDomains
    Exclude specific domains from the test.

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers from the test.

    .PARAMETER IncludeDomains
    Include only specific domains in the test.

    .PARAMETER IncludeDomainControllers
    Include only specific domain controllers in the test.

    .PARAMETER SkipRODC
    Skip Read-Only Domain Controllers when testing roles.

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing.

    .EXAMPLE
    Test-ADRolesAvailability

    .EXAMPLE
    Test-ADRolesAvailability -Forest "example.com"

    .NOTES
    This cmdlet is useful for monitoring the availability of Active Directory roles across domain controllers in a forest.
    #>
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