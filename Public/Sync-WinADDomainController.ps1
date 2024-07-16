function Sync-WinADDomainController {
    <#
    .SYNOPSIS
    Synchronizes domain controllers across a specified forest or domains.

    .DESCRIPTION
    This cmdlet synchronizes domain controllers across a specified forest or domains. It uses the repadmin tool to force synchronization of domain controllers for each domain in the forest. The cmdlet can be filtered to include or exclude specific domains or domain controllers, and can also skip Read-Only Domain Controllers (RODCs).

    .PARAMETER Forest
    The name of the forest to synchronize domain controllers for. If not specified, the current user's forest is used.

    .PARAMETER ExcludeDomains
    An array of domain names to exclude from the synchronization process.

    .PARAMETER ExcludeDomainControllers
    An array of domain controller names to exclude from the synchronization process.

    .PARAMETER IncludeDomains
    An array of domain names to include in the synchronization process. If specified, only these domains will be synchronized.

    .PARAMETER IncludeDomainControllers
    An array of domain controller names to include in the synchronization process. If specified, only these domain controllers will be synchronized.

    .PARAMETER SkipRODC
    A switch to skip Read-Only Domain Controllers (RODCs) during the synchronization process.

    .PARAMETER ExtendedForestInformation
    A dictionary containing extended information about the forest, which can be used to speed up processing.

    .EXAMPLE
    Sync-WinADDomainController -Forest "example.com"

    .NOTES
    This cmdlet is useful for ensuring domain controllers are synchronized across a forest or domains, which is essential for maintaining consistency and ensuring all domain controllers have the same information.
    #>
    [alias('Sync-DomainController')]
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $DistinguishedName = (Get-ADDomain -Server $QueryServer).DistinguishedName
        ($ForestInformation['DomainDomainControllers']["$Domain"]).Name | ForEach-Object {
            Write-Verbose -Message "Sync-DomainController - Forcing synchronization $_"
            repadmin /syncall $_ $DistinguishedName /e /A | Out-Null
        }
    }
}