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
        [switch] $All,
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
    [Array] $ReplicationData = @(
        foreach ($R in $Replication) {
            $ServerPartner = (Resolve-DnsName -Name $R.PartnerAddress -Verbose:$false -ErrorAction SilentlyContinue)
            $ServerInitiating = (Resolve-DnsName -Name $R.Server -Verbose:$false -ErrorAction SilentlyContinue)
            $ReplicationObject = [ordered] @{
                Server                         = $R.Server.ToUpper()
                ServerIPV4                     = $ServerInitiating.IP4Address
                ServerPartner                  = $ServerPartner.NameHost.ToUpper()
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
                Server                         = $E.Server.ToUpper()
                ServerIPV4                     = $ServerInitiating.IP4Address
                ServerPartner                  = 'Unknown'.ToUpper()
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
    )

    if (-not $All) {
        return $ReplicationData
    }

    $SiteInformation = @{}

    $Sites = Get-WinADForestSites
    $Subnets = Get-WinADForestSubnet -VerifyOverlap

    # Build a mapping of DC names to their sites
    foreach ($Site in $Sites) {
        if ($Site.DomainControllers) {
            foreach ($DC in $Site.DomainControllers) {
                $SiteInformation[$DC] = $Site.Name
            }
        }
    }

    $DCs = @{}
    $Links = [System.Collections.Generic.List[object]]::new()

    foreach ($RepLink in $ReplicationData) {
        # Ensure Server and Partner are added as nodes
        if ($RepLink.Server -and -not $DCs.ContainsKey($RepLink.Server)) {
            $DCs[$RepLink.Server] = @{
                Label    = $RepLink.Server
                IP       = $RepLink.ServerIPV4
                Partners = [System.Collections.Generic.HashSet[string]]::new()
                Status   = $true  # Will be set to false if any replication link fails
            }
        }
        if ($RepLink.ServerPartner -and -not $DCs.ContainsKey($RepLink.ServerPartner)) {
            # Attempt to resolve partner IP if not directly available (may require another lookup or be less reliable)
            $PartnerIP = $RepLink.ServerPartnerIPV4 # Use the IP already resolved by Get-WinADForestReplication
            $DCs[$RepLink.ServerPartner] = @{
                Label    = $RepLink.ServerPartner
                IP       = $PartnerIP
                Partners = [System.Collections.Generic.HashSet[string]]::new()
                Status   = $true
            }
        }

        # Add partner to the server's partner list (using HashSet to avoid duplicates)
        if ($RepLink.Server -and $RepLink.ServerPartner) {
            $null = $DCs[$RepLink.Server].Partners.Add($RepLink.ServerPartner)

            # Update status if there's any failure
            if (-not $RepLink.Status) {
                $DCs[$RepLink.Server].Status = $false
            }
        }

        # Add the link (handle potential duplicates if needed, maybe group by Server/Partner/Partition?)
        # For simplicity now, add each link found. Diagram might show multiple lines if partitions differ.
        if ($RepLink.Server -and $RepLink.ServerPartner) {
            $Links.Add(@{
                    From        = $RepLink.Server
                    To          = $RepLink.ServerPartner
                    Status      = $RepLink.Status
                    Fails       = $RepLink.ConsecutiveReplicationFailures
                    LastSuccess = $RepLink.LastReplicationSuccess
                    Partition   = $RepLink.Partition
                })
        }
    }

    # Create consolidated view of DC replication partnerships
    $DCPartnerSummary = foreach ($DCName in $DCs.Keys) {
        $DC = $DCs[$DCName]
        [PSCustomObject]@{
            DomainController = $DCName
            Site             = $SiteInformation[$DCName]
            IPAddress        = $DC.IP
            Partners         = $DC.Partners | ForEach-Object { $_ }
            PartnerCount     = $DC.Partners.Count
            PartnerSites     = @(
                foreach ($Partner in $DC.Partners) {
                    if ($SiteInformation.ContainsKey($Partner)) {
                        $SiteInformation[$Partner]
                    } else {
                        "Unknown"
                    }
                }
            ) | Sort-Object -Unique
            PartnersIP       = $DC.Partners | ForEach-Object {
                if ($DCs.ContainsKey($_)) {
                    $DCs[$_].IP
                } else {
                    "Unknown"
                }
            } | Sort-Object -Unique
            Status           = if ($DC.Status) { "Healthy" } else { "Issues Detected" }
        }
    }

    # Create a matrix-style mapping of DCs to their replication partners
    $DCNames = $DCs.Keys | Sort-Object
    $MatrixHeaders = $DCNames
    $ReplicationMatrix = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($SourceDC in $DCNames) {
        $Row = [ordered]@{
            'Source DC'    = $SourceDC
            'Site'         = $SiteInformation[$SourceDC]
            'IP'           = $DCs[$SourceDC].IP
            'PartnerCount' = $DCs[$SourceDC].Partners.Count
        }

        foreach ($TargetDC in $DCNames) {
            if ($SourceDC -eq $TargetDC) {
                # A DC doesn't replicate with itself
                $Row[$TargetDC] = "-"
            } else {
                # Check if there are any replication links from Source to Target
                $ReplicationLinks = $Links | Where-Object { $_.From -eq $SourceDC -and $_.To -eq $TargetDC }

                if ($ReplicationLinks) {
                    $AllHealthy = $true
                    foreach ($Link in $ReplicationLinks) {
                        if (-not $Link.Status) {
                            $AllHealthy = $false
                            break
                        }
                    }

                    $Row[$TargetDC] = if ($AllHealthy) { "✓" } else { "✗" }
                } else {
                    $Row[$TargetDC] = " "  # No direct replication
                }
            }
        }

        $ReplicationMatrix.Add([PSCustomObject]$Row)
    }

    [ordered] @{
        ReplicationData   = $ReplicationData
        DCs               = $DCs
        Links             = $Links
        DCPartnerSummary  = $DCPartnerSummary
        ReplicationMatrix = $ReplicationMatrix
        MatrixHeaders     = $MatrixHeaders
        Sites             = $Sites
        Subnets           = $Subnets
    }
}