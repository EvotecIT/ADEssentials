function Get-WinADForestReplication {
    <#
    .SYNOPSIS
    Retrieves replication information for a specified Active Directory forest.

    .DESCRIPTION
    Retrieves detailed information about replication within the specified Active Directory forest.

    .PARAMETER Forest
    Specifies the target forest to retrieve replication information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the replication search.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from the replication search.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the replication search.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in the replication search.

    .PARAMETER SkipRODC
    Indicates whether to skip read-only domain controllers during replication.

    .PARAMETER Extended
    Indicates whether to include extended replication information.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest for replication.

    .EXAMPLE
    Get-WinADForestReplication -Forest "example.com" -IncludeDomains @("example.com") -ExcludeDomains @("test.com") -IncludeDomainControllers @("DC1") -ExcludeDomainControllers @("DC2") -SkipRODC -Extended -ExtendedForestInformation $ExtendedForestInfo

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [switch] $Extended,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ProcessErrors = [System.Collections.Generic.List[PSCustomObject]]::new()
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    $Replication = foreach ($DC in $ForestInformation.ForestDomainControllers) {
        try {
            Get-ADReplicationPartnerMetadata -Target $DC.HostName -Partition * -ErrorAction Stop #-ErrorVariable +ProcessErrors
        } catch {
            Write-Warning -Message "Get-WinADForestReplication - Error on server $($_.Exception.ServerName): $($_.Exception.Message)"
            $ProcessErrors.Add([PSCustomObject] @{ Server = $_.Exception.ServerName; StatusMessage = $_.Exception.Message })
        }
    }
    foreach ($R in $Replication) {
        $ServerPartner = (Resolve-DnsName -Name $R.PartnerAddress -Verbose:$false -ErrorAction SilentlyContinue)
        $ServerInitiating = (Resolve-DnsName -Name $R.Server -Verbose:$false -ErrorAction SilentlyContinue)
        $ReplicationObject = [ordered] @{
            Server                         = $R.Server
            ServerIPV4                     = $ServerInitiating.IP4Address
            ServerPartner                  = $ServerPartner.NameHost
            ServerPartnerIPV4              = $ServerPartner.IP4Address
            LastReplicationAttempt         = $R.LastReplicationAttempt
            LastReplicationResult          = $R.LastReplicationResult
            LastReplicationSuccess         = $R.LastReplicationSuccess
            ConsecutiveReplicationFailures = $R.ConsecutiveReplicationFailures
            LastChangeUsn                  = $R.LastChangeUsn
            PartnerType                    = $R.PartnerType

            Partition                      = $R.Partition
            TwoWaySync                     = $R.TwoWaySync
            ScheduledSync                  = $R.ScheduledSync
            SyncOnStartup                  = $R.SyncOnStartup
            CompressChanges                = $R.CompressChanges
            DisableScheduledSync           = $R.DisableScheduledSync
            IgnoreChangeNotifications      = $R.IgnoreChangeNotifications
            IntersiteTransport             = $R.IntersiteTransport
            IntersiteTransportGuid         = $R.IntersiteTransportGuid
            IntersiteTransportType         = $R.IntersiteTransportType

            UsnFilter                      = $R.UsnFilter
            Writable                       = $R.Writable
            Status                         = if ($R.LastReplicationResult -ne 0) { $false } else { $true }
            StatusMessage                  = "Last successful replication time was $($R.LastReplicationSuccess), Consecutive Failures: $($R.ConsecutiveReplicationFailures)"
        }
        if ($Extended) {
            $ReplicationObject.Partner = $R.Partner
            $ReplicationObject.PartnerAddress = $R.PartnerAddress
            $ReplicationObject.PartnerGuid = $R.PartnerGuid
            $ReplicationObject.PartnerInvocationId = $R.PartnerInvocationId
            $ReplicationObject.PartitionGuid = $R.PartitionGuid
        }
        [PSCustomObject] $ReplicationObject
    }

    foreach ($E in $ProcessErrors) {
        if ($null -ne $E.Server) {
            $ServerInitiating = (Resolve-DnsName -Name $E.Server -Verbose:$false -ErrorAction SilentlyContinue)
        } else {
            $ServerInitiating = [PSCustomObject] @{ IP4Address = '127.0.0.1' }
        }
        $ReplicationObject = [ordered] @{
            Server                         = $_.Server
            ServerIPV4                     = $ServerInitiating.IP4Address
            ServerPartner                  = 'Unknown'
            ServerPartnerIPV4              = '127.0.0.1'
            LastReplicationAttempt         = $null
            LastReplicationResult          = $null
            LastReplicationSuccess         = $null
            ConsecutiveReplicationFailures = $null
            LastChangeUsn                  = $null
            PartnerType                    = $null

            Partition                      = $null
            TwoWaySync                     = $null
            ScheduledSync                  = $null
            SyncOnStartup                  = $null
            CompressChanges                = $null
            DisableScheduledSync           = $null
            IgnoreChangeNotifications      = $null
            IntersiteTransport             = $null
            IntersiteTransportGuid         = $null
            IntersiteTransportType         = $null

            UsnFilter                      = $null
            Writable                       = $null
            Status                         = $false
            StatusMessage                  = $E.StatusMessage
        }
        if ($Extended) {
            $ReplicationObject.Partner = $null
            $ReplicationObject.PartnerAddress = $null
            $ReplicationObject.PartnerGuid = $null
            $ReplicationObject.PartnerInvocationId = $null
            $ReplicationObject.PartitionGuid = $null
        }
        [PSCustomObject] $ReplicationObject
    }

}