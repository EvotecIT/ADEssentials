function Get-WinADDnsServerScavenging {
    <#
    .SYNOPSIS
    Retrieves DNS server scavenging details for specified forest and domains.

    .DESCRIPTION
    This function retrieves DNS server scavenging details for the specified forest and domains. It gathers information about DNS server scavenging settings for each domain controller in the forest.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve DNS server scavenging details for.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from DNS server scavenging details retrieval.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from DNS server scavenging details retrieval.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include in DNS server scavenging details retrieval.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in DNS server scavenging details retrieval.

    .PARAMETER SkipRODC
    Indicates whether to skip Read-Only Domain Controllers (RODC) when retrieving DNS server scavenging details.

    .PARAMETER GPOs
    Specifies an array of Group Policy Objects (GPOs) related to DNS server scavenging.

    .PARAMETER ExtendedForestInformation
    Specifies additional extended forest information to include in the output.

    .EXAMPLE
    Get-WinADDnsServerScavenging -Forest "example.com" -IncludeDomains "domain1.com", "domain2.com" -ExcludeDomainControllers "dc1.domain1.com" -SkipRODC

    Retrieves DNS server scavenging details for the "example.com" forest, including "domain1.com" and "domain2.com" domains, excluding the "dc1.domain1.com" domain controller, and skipping RODCs.

    #>
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