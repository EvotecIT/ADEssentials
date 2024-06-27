function Get-WinADDnsServerScavenging {
    [CmdLetBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [Array] $GPOs,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Computer in $ForestInformation.ForestDomainControllers) {
        try {
            $DnsServerScavenging = Get-DnsServerScavenging -ComputerName $Computer.HostName -ErrorAction Stop
        } catch {
            [PSCustomObject] @{
                NoRefreshInterval  = $null
                RefreshInterval    = $null
                ScavengingInterval = $null
                ScavengingState    = $null
                LastScavengeTime   = $null
                GatheredFrom       = $Computer.HostName
                GatheredDomain     = $Computer.Domain
            }
            continue
        }
        foreach ($_ in $DnsServerScavenging) {
            [PSCustomObject] @{
                NoRefreshInterval  = $_.NoRefreshInterval
                RefreshInterval    = $_.RefreshInterval
                ScavengingInterval = $_.ScavengingInterval
                ScavengingState    = $_.ScavengingState
                LastScavengeTime   = $_.LastScavengeTime
                GatheredFrom       = $Computer.HostName
                GatheredDomain     = $Computer.Domain
            }
        }
    }
}