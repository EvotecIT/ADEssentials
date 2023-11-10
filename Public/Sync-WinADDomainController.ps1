﻿function Sync-WinADDomainController {
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