function Get-WinADDnsIPAddresses {
    <#
    .SYNOPSIS
    Gets all the DNS records from all the zones within a forest sorted by IPAddress

    .DESCRIPTION
    Gets all the DNS records from all the zones within a forest sorted by IPAddress

    .PARAMETER IncludeZone
    Limit the output of DNS records to specific zones

    .PARAMETER ExcludeZone
    Limit the output of dNS records to only zones not in the exclude list

    .PARAMETER IncludeDetails
    Adds additional information such as creation time, changed time

    .PARAMETER Prettify
    Converts arrays into strings connected with comma

    .PARAMETER IncludeDNSRecords
    Include full DNS records just in case one would like to further process them

    .PARAMETER AsHashtable
    Outputs the results as a hashtable instead of an array

    .EXAMPLE
    Get-WinADDnsIPAddresses | Format-Table *

    .EXAMPLE
    Get-WinADDnsIPAddresses -Prettify | Format-Table *

    .EXAMPLE
    Get-WinADDnsIPAddresses -Prettify -IncludeDetails -IncludeDNSRecords | Format-Table *

    .NOTES
    General notes
    #>
    [alias('Get-WinDnsIPAddresses')]
    [cmdletbinding()]
    param(
        [string[]] $IncludeZone,
        [string[]] $ExcludeZone,
        [switch] $IncludeDetails,
        [switch] $Prettify,
        [switch] $IncludeDNSRecords,
        [switch] $AsHashtable
    )
    $DNSRecordsCached = [ordered] @{}
    $DNSRecordsPerZone = [ordered] @{}
    $ADRecordsPerZone = [ordered] @{}

    try {
        $oRootDSE = Get-ADRootDSE -ErrorAction Stop
    } catch {
        Write-Warning -Message "Get-WinADDnsIPAddresses - Could not get the root DSE. Make sure you're logged in to machine with Active Directory RSAT tools installed, and there's connecitivity to the domain. Error: $($_.Exception.Message)"
        return
    }
    $ADServer = ($oRootDSE.dnsHostName)
    $Exclusions = 'DomainDnsZones', 'ForestDnsZones', '@'
    $DNS = Get-DnsServerZone -ComputerName $ADServer
    [Array] $ZonesToProcess = foreach ($Zone in $DNS) {
        if ($Zone.ZoneType -eq 'Primary' -and $Zone.IsDsIntegrated -eq $true -and $Zone.IsReverseLookupZone -eq $false) {
            if ($Zone.ZoneName -notlike "*_*" -and $Zone.ZoneName -ne 'TrustAnchors') {
                if ($IncludeZone -and $IncludeZone -notcontains $Zone.ZoneName) {
                    continue
                }
                if ($ExcludeZone -and $ExcludeZone -contains $Zone.ZoneName) {
                    continue
                }
                $Zone
            }
        }
    }

    foreach ($Zone in $ZonesToProcess) {
        Write-Verbose -Message "Get-WinADDnsIPAddresses - Processing zone for DNS records: $($Zone.ZoneName)"
        $DNSRecordsPerZone[$Zone.ZoneName] = Get-DnsServerResourceRecord -ComputerName $ADServer -ZoneName $Zone.ZoneName -RRType A
    }
    if ($IncludeDetails) {
        $Filter = "(Name -notlike '@' -and Name -notlike '_*' -and ObjectClass -eq 'dnsNode' -and Name -ne 'ForestDnsZone' -and Name -ne 'DomainDnsZone' )"
        #$Filter = { (Name -notlike "@" -and Name -notlike "_*" -and ObjectClass -eq 'dnsNode' -and Name -ne 'ForestDnsZone' -and Name -ne 'DomainDnsZone' ) }
        foreach ($Zone in $ZonesToProcess) {
            $ADRecordsPerZone[$Zone.ZoneName] = [ordered]@{}
            Write-Verbose -Message "Get-WinADDnsIPAddresses - Processing zone for AD records: $($Zone.ZoneName)"
            $TempObjects = @(
                if ($Zone.ReplicationScope -eq 'Domain') {
                    try {
                        Get-ADObject -Server $ADServer -Filter $Filter -SearchBase ("DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=DomainDnsZones," + $oRootDSE.defaultNamingContext) -Properties CanonicalName, whenChanged, whenCreated, DistinguishedName, ProtectedFromAccidentalDeletion, dNSTombstoned
                    } catch {
                        Write-Warning -Message "Get-WinADDnsIPAddresses - Error getting AD records for DomainDnsZones zone: $($Zone.ZoneName). Error: $($_.Exception.Message)"
                    }
                } elseif ($Zone.ReplicationScope -eq 'Forest') {
                    try {
                        Get-ADObject -Server $ADServer -Filter $Filter -SearchBase ("DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=ForestDnsZones," + $oRootDSE.defaultNamingContext) -Properties CanonicalName, whenChanged, whenCreated, DistinguishedName, ProtectedFromAccidentalDeletion, dNSTombstoned
                    } catch {
                        Write-Warning -Message "Get-WinADDnsIPAddresses - Error getting AD records for ForestDnsZones zone: $($Zone.ZoneName). Error: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning -Message "Get-WinADDnsIPAddresses - Unknown replication scope: $($Zone.ReplicationScope)"
                }
            )
            foreach ($DNSObject in $TempObjects) {
                $ADRecordsPerZone[$Zone.ZoneName][$DNSObject.Name] = $DNSObject
            }
        }
    }
    foreach ($Zone in $DNSRecordsPerZone.PSBase.Keys) {
        foreach ($Record in $DNSRecordsPerZone[$Zone]) {
            if ($Record.HostName -in $Exclusions) {
                continue
            }
            if (-not $DNSRecordsCached[$Record.RecordData.IPv4Address]) {
                $DNSRecordsCached[$Record.RecordData.IPv4Address] = [ordered] @{
                    IPAddress  = $Record.RecordData.IPv4Address
                    DnsNames   = [System.Collections.Generic.List[Object]]::new()
                    Timestamps = [System.Collections.Generic.List[Object]]::new()
                    Types      = [System.Collections.Generic.List[Object]]::new()
                    Count      = 0
                }
                if ($ADRecordsPerZone.Keys.Count -gt 0) {
                    $DNSRecordsCached[$Record.RecordData.IPv4Address].WhenCreated = $ADRecordsPerZone[$Zone][$Record.HostName].whenCreated
                    $DNSRecordsCached[$Record.RecordData.IPv4Address].WhenChanged = $ADRecordsPerZone[$Zone][$Record.HostName].whenChanged
                }
                if ($IncludeDNSRecords) {
                    $DNSRecordsCached[$Record.RecordData.IPv4Address].List = [System.Collections.Generic.List[Object]]::new()
                }
            }
            $DNSRecordsCached[$Record.RecordData.IPv4Address].DnsNames.Add($Record.HostName + "." + $Zone)

            if ($IncludeDNSRecords) {
                $DNSRecordsCached[$Record.RecordData.IPv4Address].List.Add($Record)
            }
            if ($null -ne $Record.TimeStamp) {
                $DNSRecordsCached[$Record.RecordData.IPv4Address].Timestamps.Add($Record.TimeStamp)
            } else {
                $DNSRecordsCached[$Record.RecordData.IPv4Address].Timestamps.Add("Not available")
            }
            if ($Null -ne $Record.Timestamp) {
                $DNSRecordsCached[$Record.RecordData.IPv4Address].Types.Add('Dynamic')
            } else {
                $DNSRecordsCached[$Record.RecordData.IPv4Address].Types.Add('Static')
            }
            $DNSRecordsCached[$Record.RecordData.IPv4Address] = [PSCustomObject] $DNSRecordsCached[$Record.RecordData.IPv4Address]

        }
    }
    foreach ($DNS in $DNSRecordsCached.PSBase.Keys) {
        $DNSRecordsCached[$DNS].Count = $DNSRecordsCached[$DNS].DnsNames.Count
        if ($Prettify) {
            $DNSRecordsCached[$DNS].DnsNames = $DNSRecordsCached[$DNS].DnsNames -join ", "
            $DNSRecordsCached[$DNS].Timestamps = $DNSRecordsCached[$DNS].Timestamps -join ", "
            $DNSRecordsCached[$DNS].Types = $DNSRecordsCached[$DNS].Types -join ", "
        }
    }
    if ($AsHashtable) {
        $DNSRecordsCached
    } else {
        $DNSRecordsCached.Values
    }
}