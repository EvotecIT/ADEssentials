function Get-WinADForestSites {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [switch] $Formatted,
        [string] $Splitter,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    <#
                'nTSecurityDescriptor'                              = $_.'nTSecurityDescriptor'
                LastKnownParent                                     = $_.LastKnownParent
                instanceType                                        = $_.InstanceType
                InterSiteTopologyGenerator                          = $_.InterSiteTopologyGenerator
                dSCorePropagationData                               = $_.dSCorePropagationData
                ReplicationSchedule                                 = $_.ReplicationSchedule.RawSchedule -join ','
                msExchServerSiteBL                                  = $_.msExchServerSiteBL -join ','
                siteObjectBL                                        = $_.siteObjectBL -join ','
                systemFlags                                         = $_.systemFlags
                ObjectGUID                                          = $_.ObjectGUID
                ObjectCategory                                      = $_.ObjectCategory
                ObjectClass                                         = $_.ObjectClass
                ScheduleHashingEnabled                              = $_.ScheduleHashingEnabled
    #>
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $Sites = Get-ADReplicationSite -Filter * -Properties * -Server $QueryServer
    foreach ($Site in $Sites) {
        [Array] $DCs = $ForestInformation.ForestDomainControllers | Where-Object { $_.Site -eq $Site.Name }
        [Array] $Subnets = ConvertFrom-DistinguishedName -DistinguishedName $Site.'Subnets'

        if ($Formatted) {
            [PSCustomObject] @{
                'Name'                                                    = $Site.Name
                'Display Name'                                            = $Site.'DisplayName'
                'Description'                                             = $Site.'Description'
                'CanonicalName'                                           = $Site.'CanonicalName'
                'Subnets Count'                                           = $Subnets.Count
                'Domain Controllers Count'                                = $DCs.Count
                'Location'                                                = $Site.'Location'
                'ManagedBy'                                               = $Site.'ManagedBy'
                'Subnets'                                                 = if ($Splitter) { $Subnets -join $Splitter } else { $Subnets }
                'Domain Controllers'                                      = if ($Splitter) { ($DCs).HostName -join $Splitter } else { ($DCs).HostName }
                'DistinguishedName'                                       = $Site.'DistinguishedName'
                'Protected From Accidental Deletion'                      = $Site.'ProtectedFromAccidentalDeletion'
                'Redundant Server Topology Enabled'                       = $Site.'RedundantServerTopologyEnabled'
                'Automatic Inter-Site Topology Generation Enabled'        = $Site.'AutomaticInterSiteTopologyGenerationEnabled'
                'Automatic Topology Generation Enabled'                   = $Site.'AutomaticTopologyGenerationEnabled'
                'sDRightsEffective'                                       = $Site.'sDRightsEffective'
                'Topology Cleanup Enabled'                                = $Site.'TopologyCleanupEnabled'
                'Topology Detect Stale Enabled'                           = $Site.'TopologyDetectStaleEnabled'
                'Topology Minimum Hops Enabled'                           = $Site.'TopologyMinimumHopsEnabled'
                'Universal Group Caching Enabled'                         = $Site.'UniversalGroupCachingEnabled'
                'Universal Group Caching Refresh Site'                    = $Site.'UniversalGroupCachingRefreshSite'
                'Windows Server 2000 Bridgehead Selection Method Enabled' = $Site.'WindowsServer2000BridgeheadSelectionMethodEnabled'
                'Windows Server 2000 KCC ISTG Selection Behavior Enabled' = $Site.'WindowsServer2000KCCISTGSelectionBehaviorEnabled'
                'Windows Server 2003 KCC Behavior Enabled'                = $Site.'WindowsServer2003KCCBehaviorEnabled'
                'Windows Server 2003 KCC Ignore Schedule Enabled'         = $Site.'WindowsServer2003KCCIgnoreScheduleEnabled'
                'Windows Server 2003 KCC SiteLink Bridging Enabled'       = $Site.'WindowsServer2003KCCSiteLinkBridgingEnabled'
                'Created'                                                 = $Site.Created
                'Modified'                                                = $Site.Modified
                'Deleted'                                                 = $Site.Deleted
            }
        } else {
            [PSCustomObject] @{
                'Name'                                              = $Site.Name
                'DisplayName'                                       = $Site.'DisplayName'
                'Description'                                       = $Site.'Description'
                'CanonicalName'                                     = $Site.'CanonicalName'
                'SubnetsCount'                                      = $Subnets.Count
                'DomainControllersCount'                            = $DCs.Count
                'Subnets'                                           = if ($Splitter) { $Subnets -join $Splitter } else { $Subnets }
                'DomainControllers'                                 = if ($Splitter) { ($DCs).HostName -join $Splitter } else { ($DCs).HostName }
                'Location'                                          = $Site.'Location'
                'ManagedBy'                                         = $Site.'ManagedBy'
                'DistinguishedName'                                 = $Site.'DistinguishedName'
                'ProtectedFromAccidentalDeletion'                   = $Site.'ProtectedFromAccidentalDeletion'
                'RedundantServerTopologyEnabled'                    = $Site.'RedundantServerTopologyEnabled'
                'AutomaticInterSiteTopologyGenerationEnabled'       = $Site.'AutomaticInterSiteTopologyGenerationEnabled'
                'AutomaticTopologyGenerationEnabled'                = $Site.'AutomaticTopologyGenerationEnabled'
                'sDRightsEffective'                                 = $Site.'sDRightsEffective'
                'TopologyCleanupEnabled'                            = $Site.'TopologyCleanupEnabled'
                'TopologyDetectStaleEnabled'                        = $Site.'TopologyDetectStaleEnabled'
                'TopologyMinimumHopsEnabled'                        = $Site.'TopologyMinimumHopsEnabled'
                'UniversalGroupCachingEnabled'                      = $Site.'UniversalGroupCachingEnabled'
                'UniversalGroupCachingRefreshSite'                  = $Site.'UniversalGroupCachingRefreshSite'
                'WindowsServer2000BridgeheadSelectionMethodEnabled' = $Site.'WindowsServer2000BridgeheadSelectionMethodEnabled'
                'WindowsServer2000KCCISTGSelectionBehaviorEnabled'  = $Site.'WindowsServer2000KCCISTGSelectionBehaviorEnabled'
                'WindowsServer2003KCCBehaviorEnabled'               = $Site.'WindowsServer2003KCCBehaviorEnabled'
                'WindowsServer2003KCCIgnoreScheduleEnabled'         = $Site.'WindowsServer2003KCCIgnoreScheduleEnabled'
                'WindowsServer2003KCCSiteLinkBridgingEnabled'       = $Site.'WindowsServer2003KCCSiteLinkBridgingEnabled'
                'Created'                                           = $Site.Created
                'Modified'                                          = $Site.Modified
                'Deleted'                                           = $Site.Deleted
            }
        }
    }
}