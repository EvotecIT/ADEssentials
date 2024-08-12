function Get-WinDnsServerSettings {
    <#
    .SYNOPSIS
    Retrieves DNS server settings for a specified computer.

    .DESCRIPTION
    This function retrieves various DNS server settings for a specified computer.

    .PARAMETER ComputerName
    Specifies the name of the computer for which to retrieve DNS server settings.

    .EXAMPLE
    Get-WinDnsServerSettings -ComputerName "AD1.ad.evotec.xyz"
    Retrieves DNS server settings for the computer "AD1.ad.evotec.xyz".

    #>
    [CmdLetBinding()]
    param(
        [string] $ComputerName
    )

    <#
    ComputerName                            : AD1.ad.evotec.xyz
    MajorVersion                            : 10
    MinorVersion                            : 0
    BuildNumber                             : 14393
    IsReadOnlyDC                            : False
    EnableDnsSec                            : False
    EnableIPv6                              : True
    EnableOnlineSigning                     : True
    NameCheckFlag                           : 2
    AddressAnswerLimit                      : 0
    XfrConnectTimeout(s)                    : 30
    BootMethod                              : 3
    AllowUpdate                             : True
    UpdateOptions                           : 783
    DsAvailable                             : True
    DisableAutoReverseZone                  : False
    AutoCacheUpdate                         : False
    RoundRobin                              : True
    LocalNetPriority                        : True
    StrictFileParsing                       : False
    LooseWildcarding                        : False
    BindSecondaries                         : False
    WriteAuthorityNS                        : False
    ForwardDelegations                      : False
    AutoConfigFileZones                     : 1
    EnableDirectoryPartitions               : True
    RpcProtocol                             : 5
    EnableVersionQuery                      : 0
    EnableDuplicateQuerySuppression         : True
    LameDelegationTTL                       : 00:00:00
    AutoCreateDelegation                    : 2
    AllowCnameAtNs                          : True
    RemoteIPv4RankBoost                     : 5
    RemoteIPv6RankBoost                     : 0
    EnableRsoForRodc                        : True
    MaximumRodcRsoQueueLength               : 300
    MaximumRodcRsoAttemptsPerCycle          : 100
    OpenAclOnProxyUpdates                   : True
    NoUpdateDelegations                     : False
    EnableUpdateForwarding                  : False
    MaxResourceRecordsInNonSecureUpdate     : 30
    EnableWinsR                             : True
    LocalNetPriorityMask                    : 255
    DeleteOutsideGlue                       : False
    AppendMsZoneTransferTag                 : False
    AllowReadOnlyZoneTransfer               : False
    MaximumUdpPacketSize                    : 4000
    TcpReceivePacketSize                    : 65536
    EnableSendErrorSuppression              : True
    SelfTest                                : 4294967295
    XfrThrottleMultiplier                   : 10
    SilentlyIgnoreCnameUpdateConflicts      : False
    EnableIQueryResponseGeneration          : False
    SocketPoolSize                          : 2500
    AdminConfigured                         : True
    SocketPoolExcludedPortRanges            : {}
    ForestDirectoryPartitionBaseName        : ForestDnsZones
    DomainDirectoryPartitionBaseName        : DomainDnsZones
    ServerLevelPluginDll                    :
    EnableRegistryBoot                      :
    PublishAutoNet                          : False
    QuietRecvFaultInterval(s)               : 0
    QuietRecvLogInterval(s)                 : 0
    ReloadException                         : False
    SyncDsZoneSerial                        : 2
    EnableDuplicateQuerySuppression         : True
    SendPort                                : Random
    MaximumSignatureScanPeriod              : 2.00:00:00
    MaximumTrustAnchorActiveRefreshInterval : 15.00:00:00
    ListeningIPAddress                      : {192.168.240.189}
    AllIPAddress                            : {192.168.240.189}
    ZoneWritebackInterval                   : 00:01:00
    RootTrustAnchorsURL                     : https://data.iana.org/root-anchors/root-anchors.xml
    ScopeOptionValue                        : 0
    IgnoreServerLevelPolicies               : False
    IgnoreAllPolicies                       : False
    VirtualizationInstanceOptionValue       : 0

    #>

    $DnsServerSetting = Get-DnsServerSetting -ComputerName $ComputerName -All
    foreach ($_ in $DnsServerSetting) {
        [PSCustomObject] @{
            AllIPAddress       = $_.AllIPAddress
            ListeningIPAddress = $_.ListeningIPAddress
            BuildNumber        = $_.BuildNumber
            ComputerName       = $_.ComputerName
            EnableDnsSec       = $_.EnableDnsSec
            EnableIPv6         = $_.EnableIPv6
            IsReadOnlyDC       = $_.IsReadOnlyDC
            MajorVersion       = $_.MajorVersion
            MinorVersion       = $_.MinorVersion
            GatheredFrom       = $ComputerName
        }
    }
}

#Get-WinDnsServerSettings -ComputerName 'AD1'
#Get-DnsServerSetting -ComputerName AD1 -All