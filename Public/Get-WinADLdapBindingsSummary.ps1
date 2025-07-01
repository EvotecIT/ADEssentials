function Get-WinADLDAPBindingsSummary {
    <#
    .SYNOPSIS
    Retrieves LDAP binding summary information for Active Directory.

    .DESCRIPTION
    Retrieves LDAP binding summary information for Active Directory based on specified parameters.

    .PARAMETER Forest
    Specifies the target forest to retrieve LDAP binding information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in the search.

    .PARAMETER SkipRODC
    Skips Read-Only Domain Controllers. By default, all domain controllers are included.

    .PARAMETER Days
    Specifies the number of days to consider for retrieving LDAP binding information. Default is 1 day.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .EXAMPLE
    Get-WinADLdapBindingsSummary -Forest "example.com" -IncludeDomains "example.com" -Days 7
    This example retrieves LDAP binding summary information for the "example.com" forest, including only the specified domains and considering the last 7 days.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [int] $Days = 1,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    $Events = Get-Events -LogName 'Directory Service' -ID 2887 -Machine $ForestInformation.ForestDomainControllers.HostName -DateFrom ((Get-Date).Date.adddays(-$Days))
    foreach ($E in $Events) {
        [PSCustomobject] @{
            'Domain Controller'                                                        = $E.Computer
            'Date'                                                                     = $E.Date
            'Number of simple binds performed without SSL/TLS'                         = $E.'NoNameA0'
            'Number of Negotiate/Kerberos/NTLM/Digest binds performed without signing' = $E.'NoNameA1'
            'GatheredFrom'                                                             = $E.'GatheredFrom'
            'GatheredLogName'                                                          = $E.'GatheredLogName'
        }
    }
}