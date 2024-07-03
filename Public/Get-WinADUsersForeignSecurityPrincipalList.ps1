function Get-WinADUsersForeignSecurityPrincipalList {
    <#
    .SYNOPSIS
    Retrieves a list of foreign security principals from the specified Active Directory forest or domains.

    .DESCRIPTION
    This cmdlet retrieves a list of foreign security principals from the specified Active Directory forest or domains. It supports the option to include or exclude specific domains and translates the security identifiers to NTAccount format for easier identification.

    .PARAMETER Forest
    Specifies the name of the Active Directory forest to retrieve foreign security principals from. If not specified, the current forest is used.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the retrieval process. If not specified, all domains in the forest are included.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the retrieval process.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest to aid in the retrieval process.

    .EXAMPLE
    Get-WinADUsersForeignSecurityPrincipalList -Forest "example.com" -IncludeDomains "example.com", "subdomain.example.com"

    This example retrieves the list of foreign security principals from the "example.com" and "subdomain.example.com" domains in the "example.com" forest.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported.
    #>
    [CmdletBinding()]
    [alias('Get-WinADUsersFP')]
    param(
        [alias('ForestName')][string] $Forest,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $ForeignSecurityPrincipalList = Get-ADObject -Filter "ObjectClass -eq 'ForeignSecurityPrincipal'" -Properties * -Server $QueryServer
        foreach ($FSP in $ForeignSecurityPrincipalList) {
            Try {
                $Translated = (([System.Security.Principal.SecurityIdentifier]::new($FSP.objectSid)).Translate([System.Security.Principal.NTAccount])).Value
            } Catch {
                $Translated = $null
            }
            Add-Member -InputObject $FSP -Name 'TranslatedName' -Value $Translated -MemberType NoteProperty -Force
        }
        $ForeignSecurityPrincipalList
    }
}