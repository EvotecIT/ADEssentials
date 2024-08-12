function Get-WinADDomainControllerNTDSSettings {
    <#
    .SYNOPSIS
    Gathers information about NTDS settings on a Domain Controller

    .DESCRIPTION
    Gathers information about NTDS settings on a Domain Controller

    .PARAMETER DomainController
    Specifies the Domain Controller to retrieve information from

    .PARAMETER All
    Retrieves all information from registry as is without any processing

    .EXAMPLE
    Get-WinADDomainControllerNTDSSettings -DomainController 'AD1'

    .EXAMPLE
    Get-WinADDomainControllerNTDSSettings -DomainController 'AD1' -All

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Alias('ComputerName')][string] $DomainController,
        [switch] $All
    )
    $RegistryNTDS = Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -ComputerName $DomainController
    if ($All) {
        $RegistryNTDS
    } else {
        [PSCustomObject] @{
            'DomainController'                                 = $RegistryNTDS.'PSComputerName'
            'Error'                                            = $RegistryNTDS.'PSError'
            'System Schema Version'                            = $RegistryNTDS.'System Schema Version' #: 87
            'Root Domain'                                      = $RegistryNTDS.'Root Domain' #: DC = ad, DC = evotec, DC = xyz
            'Configuration NC'                                 = $RegistryNTDS.'Configuration NC' #: CN = Configuration, DC = ad, DC = evotec, DC = xyz
            'Machine DN Name'                                  = $RegistryNTDS.'Machine DN Name' #: CN = NTDS Settings, CN = AD1, CN = Servers, CN = Default-First-Site-Name, CN = Sites, CN = Configuration, DC = ad, DC = evotec, DC = xyz
            'DsaOptions'                                       = $RegistryNTDS.'DsaOptions' #: 1
            'IsClone'                                          = $RegistryNTDS.'IsClone' #: 0
            'ServiceDll'                                       = $RegistryNTDS.'ServiceDll' #: % systemroot % \system32\ntdsa.dll
            'DSA Working Directory'                            = $RegistryNTDS.'DSA Working Directory' #: C:\Windows\NTDS
            'DSA Database file'                                = $RegistryNTDS.'DSA Database file' #: C:\Windows\NTDS\ntds.dit
            'Database backup path'                             = $RegistryNTDS.'Database backup path' #: C:\Windows\NTDS\dsadata.bak
            'Database log files path'                          = $RegistryNTDS.'Database log files path' #: C:\Windows\NTDS
            'Hierarchy Table Recalculation interval (minutes)' = $RegistryNTDS.'Hierarchy Table Recalculation interval (minutes)' #: 720
            'Database logging / recovery'                      = $RegistryNTDS.'Database logging / recovery' #  : ON
            'DS Drive Mappings'                                = $RegistryNTDS.'DS Drive Mappings' #: c:\=\\?\Volume { 2014dd39-5b27-44a6-be88-1d650346016d }\
            'DSA Database Epoch'                               = $RegistryNTDS.'DSA Database Epoch' #: 24290
            'Strict Replication Consistency'                   = $RegistryNTDS.'Strict Replication Consistency' #: 1
            'Schema Version'                                   = $RegistryNTDS.'Schema Version' #: 88
            'ldapserverintegrity'                              = $RegistryNTDS.'ldapserverintegrity' #: 1
            'Global Catalog Promotion Complete'                = $RegistryNTDS.'Global Catalog Promotion Complete' #: 1
            'DSA Previous Restore Count'                       = $RegistryNTDS.'DSA Previous Restore Count' #: 4
            'ErrorMessage'                                     = $RegistryNTDS.'PSErrorMessage'
        }
    }
}