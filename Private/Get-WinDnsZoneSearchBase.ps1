function Get-WinDnsZoneSearchBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Zone,

        [Parameter(Mandatory)]
        [psobject] $RootDSE
    )

    if ($Zone.DistinguishedName) {
        return $Zone.DistinguishedName
    }

    if ($Zone.ReplicationScope -eq 'Domain') {
        return "DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=DomainDnsZones,$($RootDSE.defaultNamingContext)"
    }

    if ($Zone.ReplicationScope -eq 'Forest') {
        $ForestNamingContext = if ($RootDSE.rootDomainNamingContext) {
            $RootDSE.rootDomainNamingContext
        } else {
            $RootDSE.defaultNamingContext
        }
        return "DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=ForestDnsZones,$ForestNamingContext"
    }

    return $null
}
