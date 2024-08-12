function Get-ADWinDnsServerZones {
    <#
    .SYNOPSIS
    Retrieves detailed information about DNS zones from Active Directory DNS servers.

    .DESCRIPTION
    This function retrieves detailed information about DNS zones from Active Directory DNS servers. It queries the DNS servers to gather information such as zone name, type, dynamic update settings, replication scope, and other zone-related details.

    .PARAMETER Forest
    Specifies the target forest to retrieve DNS zone information from.

    .PARAMETER ExcludeDomains
    Specifies the domains to exclude from the search.

    .PARAMETER ExcludeDomainControllers
    Specifies the domain controllers to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies the domains to include in the search.

    .PARAMETER IncludeDomainControllers
    Specifies the domain controllers to include in the search.

    .PARAMETER SkipRODC
    Skips Read-Only Domain Controllers when querying for information.

    .PARAMETER ExtendedForestInformation
    Provides forest information from another command to speed up processing.

    .PARAMETER ReverseLookupZone
    Indicates whether to retrieve reverse lookup zones.

    .PARAMETER PrimaryZone
    Indicates whether to retrieve primary zones.

    .PARAMETER Forwarder
    Indicates whether to retrieve forwarder zones.

    .PARAMETER ZoneName
    Specifies the name of the zone to retrieve information for.

    .EXAMPLE
    Get-ADWinDnsServerZones -Forest "example.com" -IncludeDomains "domain1.com", "domain2.com" -PrimaryZone -ZoneName "example.com" | Format-Table

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory DNS servers.
    #>
    [alias('Get-WinDnsServerZones')]
    [CmdLetBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,

        [switch] $ReverseLookupZone,
        [switch] $PrimaryZone,
        [switch] $Forwarder,
        [string] $ZoneName
    )

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        foreach ($Computer in $ForestInformation['DomainDomainControllers'][$Domain]) {
            $getDnsServerZoneSplat = @{
                ComputerName = $Computer.HostName
                Name         = $ZoneName
            }
            Remove-EmptyValue -Hashtable $getDnsServerZoneSplat
            $Zones = Get-DnsServerZone @getDnsServerZoneSplat -ErrorAction SilentlyContinue
            foreach ($_ in $Zones) {
                if ($ZoneName) {
                    if ($ZoneName -ne $_.ZoneName) {
                        continue
                    }
                }
                if ($_.ZoneType -eq 'Primary') {
                    $ZoneAging = Get-DnsServerZoneAging -Name $_.ZoneName -ComputerName $Computer.HostName
                    $AgingEnabled = $ZoneAging.AgingEnabled
                    $AvailForScavengeTime = $ZoneAging.AvailForScavengeTime
                    $RefreshInterval = $ZoneAging.RefreshInterval
                    $NoRefreshInterval = $ZoneAging.NoRefreshInterval
                    $ScavengeServers = $ZoneAging.ScavengeServers
                } else {
                    $AgingEnabled = $null
                    $AvailForScavengeTime = $null
                    $RefreshInterval = $null
                    $NoRefreshInterval = $null
                    $ScavengeServers = $null
                }
                if ($Forwarder) {
                    if ($_.ZoneType -ne 'Forwarder') {
                        continue
                    }
                } elseif ($ReverseLookupZone -and $PrimaryZone) {
                    if ($_.IsReverseLookupZone -ne $true -or $_.ZoneType -ne 'Primary') {
                        continue
                    }
                } elseif ($ReverseLookupZone) {
                    if ($_.IsReverseLookupZone -ne $true) {
                        continue
                    }
                } elseif ($PrimaryZone) {
                    if ($_.ZoneType -ne 'Primary' -or $_.IsReverseLookupZone -ne $false ) {
                        continue
                    }
                }
                [PSCustomObject] @{
                    'ZoneName'                          = $_.'ZoneName'
                    'ZoneType'                          = $_.'ZoneType'
                    'IsPDC'                             = $Computer.IsPDC
                    'AgingEnabled'                      = $AgingEnabled
                    'AvailForScavengeTime'              = $AvailForScavengeTime
                    'RefreshInterval'                   = $RefreshInterval
                    'NoRefreshInterval'                 = $NoRefreshInterval
                    'ScavengeServers'                   = $ScavengeServers
                    'MasterServers'                     = $_.MasterServers
                    'NotifyServers'                     = $_.'NotifyServers'
                    'SecondaryServers'                  = $_.'SecondaryServers'
                    'AllowedDcForNsRecordsAutoCreation' = $_.'AllowedDcForNsRecordsAutoCreation'
                    'DistinguishedName'                 = $_.'DistinguishedName'
                    'IsAutoCreated'                     = $_.'IsAutoCreated'
                    'IsDsIntegrated'                    = $_.'IsDsIntegrated'
                    'IsPaused'                          = $_.'IsPaused'
                    'IsReadOnly'                        = $_.'IsReadOnly'
                    'IsReverseLookupZone'               = $_.'IsReverseLookupZone'
                    'IsShutdown'                        = $_.'IsShutdown'
                    'DirectoryPartitionName'            = $_.'DirectoryPartitionName'
                    'DynamicUpdate'                     = $_.'DynamicUpdate'
                    'IgnorePolicies'                    = $_.'IgnorePolicies'
                    'IsSigned'                          = $_.'IsSigned'
                    'IsWinsEnabled'                     = $_.'IsWinsEnabled'
                    'Notify'                            = $_.'Notify'
                    'ReplicationScope'                  = $_.'ReplicationScope'
                    'SecureSecondaries'                 = $_.'SecureSecondaries'
                    'ZoneFile'                          = $_.'ZoneFile'
                    'GatheredFrom'                      = $Computer.HostName
                    'GatheredDomain'                    = $Domain
                }

            }
        }
    }
}