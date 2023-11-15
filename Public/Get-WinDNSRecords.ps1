function Get-WinDNSRecords {
    <#
    .SYNOPSIS
    Gets all the DNS records from all the zones within a forest

    .DESCRIPTION
    Gets all the DNS records from all the zones within a forest

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
    Get-WinDNSRecords -Prettify -IncludeDetails | Format-Table

    .EXAMPLE
    $Output = Get-WinDNSRecords -Prettify -IncludeDetails -Verbose
    $Output.Count
    $Output | Sort-Object -Property Count -Descending | Select-Object -First 30 | Format-Table

    .NOTES
    General notes
    #>
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
    $ADRecordsPerZoneByDns = [ordered] @{}

    try {
        $oRootDSE = Get-ADRootDSE -ErrorAction Stop
    } catch {
        Write-Warning -Message "Get-WinDNSRecords - Could not get the root DSE. Make sure you're logged in to machine with Active Directory RSAT tools installed, and there's connecitivity to the domain. Error: $($_.Exception.Message)"
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
        Write-Verbose -Message "Get-WinDNSRecords - Processing zone for DNS records: $($Zone.ZoneName)"
        $DNSRecordsPerZone[$Zone.ZoneName] = Get-DnsServerResourceRecord -ComputerName $ADServer -ZoneName $Zone.ZoneName -RRType A
        $ADRecordsPerZoneByDns[$Zone.ZoneName] = [ordered] @{}
        foreach ($Record in  $DNSRecordsPerZone[$Zone.ZoneName]) {
            if (-not $ADRecordsPerZoneByDns[$Zone.ZoneName][$Record.HostName]) {
                $ADRecordsPerZoneByDns[$Zone.ZoneName][$Record.HostName] = [System.Collections.Generic.List[Object]]::new()
            }
            $ADRecordsPerZoneByDns[$Zone.ZoneName][$Record.HostName].Add($Record)
        }
    }
    if ($IncludeDetails) {
        $Filter = { (Name -notlike "@" -and Name -notlike "_*" -and ObjectClass -eq 'dnsNode' -and Name -ne 'ForestDnsZone' -and Name -ne 'DomainDnsZone' ) }
        foreach ($Zone in $ZonesToProcess) {
            $ADRecordsPerZone[$Zone.ZoneName] = [ordered]@{}
            Write-Verbose -Message "Get-WinDNSRecords - Processing zone for AD records: $($Zone.ZoneName)"
            $TempObjects = @(
                if ($Zone.ReplicationScope -eq 'Domain') {
                    try {
                        $getADObjectSplat = @{
                            Server     = $ADServer
                            Filter     = $Filter
                            SearchBase = ("DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=DomainDnsZones," + $oRootDSE.defaultNamingContext)
                            Properties = 'CanonicalName', 'whenChanged', 'whenCreated', 'DistinguishedName', 'ProtectedFromAccidentalDeletion', 'dNSTombstoned', 'nTSecurityDescriptor'
                        }
                        Get-ADObject @getADObjectSplat
                    } catch {
                        Write-Warning -Message "Get-WinDNSRecords - Error getting AD records for DomainDnsZones zone: $($Zone.ZoneName). Error: $($_.Exception.Message)"
                    }
                } elseif ($Zone.ReplicationScope -eq 'Forest') {
                    try {
                        $getADObjectSplat = @{
                            Server     = $ADServer
                            Filter     = $Filter
                            SearchBase = ("DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=ForestDnsZones," + $oRootDSE.defaultNamingContext)
                            Properties = 'CanonicalName', 'whenChanged', 'whenCreated', 'DistinguishedName', 'ProtectedFromAccidentalDeletion', 'dNSTombstoned', 'nTSecurityDescriptor'
                        }
                        Get-ADObject @getADObjectSplat
                    } catch {
                        Write-Warning -Message "Get-WinDNSRecords - Error getting AD records for ForestDnsZones zone: $($Zone.ZoneName). Error: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning -Message "Get-WinDNSRecords - Unknown replication scope: $($Zone.ReplicationScope)"
                }
            )
            foreach ($DNSObject in $TempObjects) {
                $ADRecordsPerZone[$Zone.ZoneName][$DNSObject.Name] = $DNSObject
            }
        }
    }
    # PSBase is required because of "Keys" DNS name
    foreach ($Zone in $ADRecordsPerZone.PSBase.Keys) {
        foreach ($RecordName in [string[]] $ADRecordsPerZone[$Zone].PSBase.Keys) {
            $ADDNSRecord = $ADRecordsPerZone[$Zone][$RecordName]
            [Array] $ListRecords = $ADRecordsPerZoneByDns[$Zone][$RecordName]

            if ($ADDNSRecord.Name -in $Exclusions) {
                continue
            }
            if (-not $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"]) {
                $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"] = [ordered] @{
                    'HostName' = $ADDNSRecord.Name
                    'Zone'     = $Zone
                    'Status'   = if ($ADDNSRecord.dNSTombstoned -eq $true) { 'Tombstoned' } else { 'Active' }
                    Owner      = $ADDNSRecord.ntsecuritydescriptor.owner
                    RecordIP   = [System.Collections.Generic.List[Object]]::new()
                    Types      = [System.Collections.Generic.List[Object]]::new()
                    Timestamps = [System.Collections.Generic.List[Object]]::new()
                    Count      = 0
                }
                #if ($ADRecordsPerZone.Keys.Count -gt 0) {
                #$DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].dNSTombstoned = $ADRecordsPerZone[$Zone][$ADDNSRecord.Name].dNSTombstoned
                $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].WhenCreated = $ADRecordsPerZone[$Zone][$ADDNSRecord.Name].whenCreated
                $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].WhenChanged = $ADRecordsPerZone[$Zone][$ADDNSRecord.Name].whenChanged
                #}
                if ($IncludeDNSRecords) {
                    $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].List = [System.Collections.Generic.List[Object]]::new()
                }
            }
            if ($ListRecords.Count -gt 0) {
                foreach ($Record in $ListRecords) {
                    if ($IncludeDNSRecords) {
                        $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].List.Add($Record)
                    }
                    if ($null -ne $Record.TimeStamp) {
                        $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].Timestamps.Add($Record.TimeStamp)
                    } else {
                        $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].Timestamps.Add("Not available")
                    }
                    $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].RecordIP.Add($Record.RecordData.IPv4Address)
                    if ($Null -ne $Record.Timestamp) {
                        $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].Types.Add('Dynamic')
                    } else {
                        $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].Types.Add('Static')
                    }
                }
            } else {
                $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].RecordIP.Add('Not available')
                $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].Types.Add('Not available')
                $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"].Timestamps.Add('Not available')
            }
            $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"] = [PSCustomObject] $DNSRecordsCached["$($ADDNSRecord.Name).$($Zone)"]
        }
    }
    foreach ($DNS in $DNSRecordsCached.PSBase.Keys) {
        $DNSRecordsCached[$DNS].Count = $DNSRecordsCached[$DNS].RecordIP.Count
        if ($Prettify) {
            $DNSRecordsCached[$DNS].Types = $DNSRecordsCached[$DNS].Types -join ", "
            $DNSRecordsCached[$DNS].RecordIP = $DNSRecordsCached[$DNS].RecordIP -join ", "
            $DNSRecordsCached[$DNS].Timestamps = $DNSRecordsCached[$DNS].Timestamps -join ", "
        }
    }
    if ($AsHashtable) {
        $DNSRecordsCached
    } else {
        $DNSRecordsCached.Values
    }
}