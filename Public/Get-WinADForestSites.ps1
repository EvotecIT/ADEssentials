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
    if (-not $ExtendedForestInformation) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC
    } else {
        $ForestInformation = $ExtendedForestInformation
    }
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
                'DistinguishedName'                                       = $Site.'DistinguishedName'
                'Location'                                                = $Site.'Location'
                'ManagedBy'                                               = $Site.'ManagedBy'
                'Protected From Accidental Deletion'                      = $Site.'ProtectedFromAccidentalDeletion'
                'Redundant Server Topology Enabled'                       = $Site.'RedundantServerTopologyEnabled'
                'Automatic Inter-Site Topology Generation Enabled'        = $Site.'AutomaticInterSiteTopologyGenerationEnabled'
                'Automatic Topology Generation Enabled'                   = $Site.'AutomaticTopologyGenerationEnabled'
                'Subnets'                                                 = if ($Splitter) { $Subnets -join $Splitter } else { $Subnets }
                'Subnets Count'                                           = $Subnets.Count
                'Domain Controllers'                                      = if ($Splitter) { ($DCs).HostName -join $Splitter } else { ($DCs).HostName }
                'Domain Controllers Count'                                = $DCs.Count
                'sDRightsEffective'                                       = $_.'sDRightsEffective'
                'Topology Cleanup Enabled'                                = $_.'TopologyCleanupEnabled'
                'Topology Detect Stale Enabled'                           = $_.'TopologyDetectStaleEnabled'
                'Topology Minimum Hops Enabled'                           = $_.'TopologyMinimumHopsEnabled'
                'Universal Group Caching Enabled'                         = $_.'UniversalGroupCachingEnabled'
                'Universal Group Caching Refresh Site'                    = $_.'UniversalGroupCachingRefreshSite'
                'Windows Server 2000 Bridgehead Selection Method Enabled' = $_.'WindowsServer2000BridgeheadSelectionMethodEnabled'
                'Windows Server 2000 KCC ISTG Selection Behavior Enabled' = $_.'WindowsServer2000KCCISTGSelectionBehaviorEnabled'
                'Windows Server 2003 KCC Behavior Enabled'                = $_.'WindowsServer2003KCCBehaviorEnabled'
                'Windows Server 2003 KCC Ignore Schedule Enabled'         = $_.'WindowsServer2003KCCIgnoreScheduleEnabled'
                'Windows Server 2003 KCC SiteLink Bridging Enabled'       = $_.'WindowsServer2003KCCSiteLinkBridgingEnabled'
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
                'DistinguishedName'                                 = $Site.'DistinguishedName'
                'Location'                                          = $Site.'Location'
                'ManagedBy'                                         = $Site.'ManagedBy'
                'ProtectedFromAccidentalDeletion'                   = $Site.'ProtectedFromAccidentalDeletion'
                'RedundantServerTopologyEnabled'                    = $Site.'RedundantServerTopologyEnabled'
                'AutomaticInterSiteTopologyGenerationEnabled'       = $Site.'AutomaticInterSiteTopologyGenerationEnabled'
                'AutomaticTopologyGenerationEnabled'                = $Site.'AutomaticTopologyGenerationEnabled'
                'Subnets'                                           = if ($Splitter) { $Subnets -join $Splitter } else { $Subnets }
                'SubnetsCount'                                      = $Subnets.Count
                'DomainControllers'                                 = if ($Splitter) { ($DCs).HostName -join $Splitter } else { ($DCs).HostName }
                'DomainControllersCount'                            = $DCs.Count
                'sDRightsEffective'                                 = $_.'sDRightsEffective'
                'TopologyCleanupEnabled'                            = $_.'TopologyCleanupEnabled'
                'TopologyDetectStaleEnabled'                        = $_.'TopologyDetectStaleEnabled'
                'TopologyMinimumHopsEnabled'                        = $_.'TopologyMinimumHopsEnabled'
                'UniversalGroupCachingEnabled'                      = $_.'UniversalGroupCachingEnabled'
                'UniversalGroupCachingRefreshSite'                  = $_.'UniversalGroupCachingRefreshSite'
                'WindowsServer2000BridgeheadSelectionMethodEnabled' = $_.'WindowsServer2000BridgeheadSelectionMethodEnabled'
                'WindowsServer2000KCCISTGSelectionBehaviorEnabled'  = $_.'WindowsServer2000KCCISTGSelectionBehaviorEnabled'
                'WindowsServer2003KCCBehaviorEnabled'               = $_.'WindowsServer2003KCCBehaviorEnabled'
                'WindowsServer2003KCCIgnoreScheduleEnabled'         = $_.'WindowsServer2003KCCIgnoreScheduleEnabled'
                'WindowsServer2003KCCSiteLinkBridgingEnabled'       = $_.'WindowsServer2003KCCSiteLinkBridgingEnabled'
                'Created'                                           = $Site.Created
                'Modified'                                          = $Site.Modified
                'Deleted'                                           = $Site.Deleted
            }
        }
    }
}