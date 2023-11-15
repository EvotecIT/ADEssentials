function Get-WinDNSZones {
    [CmdletBinding()]
    param(

    )
    try {
        $oRootDSE = Get-ADRootDSE -ErrorAction Stop
    } catch {
        Write-Warning -Message "Get-WinDNSZones - Could not get the root DSE. Make sure you're logged in to machine with Active Directory RSAT tools installed, and there's connecitivity to the domain. Error: $($_.Exception.Message)"
        return
    }
    $ADServer = ($oRootDSE.dnsHostName)
    $DNS = Get-DnsServerZone -ComputerName $ADServer
    foreach ($Zone in $DNS) {
        [PSCustomObject] @{
            ZoneName                          = $Zone.ZoneName                            #: _msdcs.ad.evotec.xyz
            ZoneType                          = $Zone.ZoneType                            #: Primary
            DynamicUpdate                     = $Zone.DynamicUpdate                       #: Secure
            ReplicationScope                  = $Zone.ReplicationScope                    #: Forest
            DirectoryPartitionName            = $Zone.DirectoryPartitionName              #: ForestDnsZones.ad.evotec.xyz
            #:
            IsAutoCreated                     = $Zone.IsAutoCreated                       #: False
            IsDsIntegrated                    = $Zone.IsDsIntegrated                      #: True
            IsReadOnly                        = $Zone.IsReadOnly                          #: False
            IsReverseLookupZone               = $Zone.IsReverseLookupZone                 #: False
            IsSigned                          = $Zone.IsSigned                            #: False
            IsPaused                          = $Zone.IsPaused                            #: False
            IsShutdown                        = $Zone.IsShutdown                          #: False
            IsWinsEnabled                     = $Zone.IsWinsEnabled                       #: False
            Notify                            = $Zone.Notify                              #: NotifyServers
            NotifyServers                     = $Zone.NotifyServers                       #:
            SecureSecondaries                 = $Zone.SecureSecondaries                   #: NoTransfer
            SecondaryServers                  = $Zone.SecondaryServers                    #:
            LastZoneTransferAttempt           = $Zone.LastZoneTransferAttempt             #:
            LastSuccessfulZoneTransfer        = $Zone.LastSuccessfulZoneTransfer          #:
            LastZoneTransferResult            = $Zone.LastZoneTransferResult              #:
            LastSuccessfulSOACheck            = $Zone.LastSuccessfulSOACheck              #:
            MasterServers                     = $Zone.MasterServers                       #:
            LocalMasters                      = $Zone.LocalMasters                        #:
            UseRecursion                      = $Zone.UseRecursion                        #:
            ForwarderTimeout                  = $Zone.ForwarderTimeout                    #:
            AllowedDcForNsRecordsAutoCreation = $Zone.AllowedDcForNsRecordsAutoCreation   #:
            DistinguishedName                 = $Zone.DistinguishedName                   #: DC=_msdcs.ad.evotec.xyz,cn=MicrosoftDNS,DC=ForestDnsZones,DC=ad,DC=evotec,DC=xyz
            ZoneFile                          = $Zone.ZoneFile
        }
    }
}