function Get-WinDNSNSRecords {
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
        Write-Warning -Message "Get-WinDNSIPAddresses - Could not get the root DSE. Make sure you're logged in to machine with Active Directory RSAT tools installed, and there's connecitivity to the domain. Error: $($_.Exception.Message)"
        return
    }
    $ADServer = ($oRootDSE.dnsHostName)
    #$Exclusions = 'DomainDnsZones', 'ForestDnsZones', '@'
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
        Write-Verbose -Message "Get-WinDNSIPAddresses - Processing zone for DNS records: $($Zone.ZoneName)"
        $DNSRecordsPerZone[$Zone.ZoneName] = Get-DnsServerResourceRecord -ComputerName $ADServer -ZoneName $Zone.ZoneName -RRType NS
    }
    if ($IncludeDetails) {
        $Filter = "(Name -notlike '@' -and Name -notlike '_*' -and ObjectClass -eq 'dnsNode' -and Name -ne 'ForestDnsZone' -and Name -ne 'DomainDnsZone' )"
        #$Filter = { (Name -notlike "@" -and Name -notlike "_*" -and ObjectClass -eq 'dnsNode' -and Name -ne 'ForestDnsZone' -and Name -ne 'DomainDnsZone' ) }
        foreach ($Zone in $ZonesToProcess) {
            $ADRecordsPerZone[$Zone.ZoneName] = [ordered]@{}
            Write-Verbose -Message "Get-WinDNSIPAddresses - Processing zone for AD records: $($Zone.ZoneName)"
            $TempObjects = @(
                if ($Zone.ReplicationScope -eq 'Domain') {
                    try {
                        Get-ADObject -Server $ADServer -Filter $Filter -SearchBase ("DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=DomainDnsZones," + $oRootDSE.defaultNamingContext) -Properties CanonicalName, whenChanged, whenCreated, DistinguishedName, ProtectedFromAccidentalDeletion, dNSTombstoned
                    } catch {
                        Write-Warning -Message "Get-WinDNSIPAddresses - Error getting AD records for DomainDnsZones zone: $($Zone.ZoneName). Error: $($_.Exception.Message)"
                    }
                } elseif ($Zone.ReplicationScope -eq 'Forest') {
                    try {
                        Get-ADObject -Server $ADServer -Filter $Filter -SearchBase ("DC=$($Zone.ZoneName),CN=MicrosoftDNS,DC=ForestDnsZones," + $oRootDSE.defaultNamingContext) -Properties CanonicalName, whenChanged, whenCreated, DistinguishedName, ProtectedFromAccidentalDeletion, dNSTombstoned
                    } catch {
                        Write-Warning -Message "Get-WinDNSIPAddresses - Error getting AD records for ForestDnsZones zone: $($Zone.ZoneName). Error: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning -Message "Get-WinDNSIPAddresses - Unknown replication scope: $($Zone.ReplicationScope)"
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
            $IPRecord = Resolve-DnsName -Name $Record.RecordData -Type A | Select-Object -Property Name, Type, Section, TTL, IPAddress, Timestamp
            $IPRecord
            #         if (-not $DNSRecordsCached[$Record.RecordData.IPv4Address]) {
            #             $DNSRecordsCached[$Record.RecordData.IPv4Address] = [ordered] @{
            #                 IPAddress  = $Record.RecordData.IPv4Address
            #                 DnsNames   = [System.Collections.Generic.List[Object]]::new()
            #                 Timestamps = [System.Collections.Generic.List[Object]]::new()
            #                 Types      = [System.Collections.Generic.List[Object]]::new()
            #                 Count      = 0
            #             }
            #             if ($ADRecordsPerZone.Keys.Count -gt 0) {
            #                 $DNSRecordsCached[$Record.RecordData.IPv4Address].WhenCreated = $ADRecordsPerZone[$Zone][$Record.HostName].whenCreated
            #                 $DNSRecordsCached[$Record.RecordData.IPv4Address].WhenChanged = $ADRecordsPerZone[$Zone][$Record.HostName].whenChanged
            #             }
            #             if ($IncludeDNSRecords) {
            #                 $DNSRecordsCached[$Record.RecordData.IPv4Address].List = [System.Collections.Generic.List[Object]]::new()
            #             }
            #         }
            #         $DNSRecordsCached[$Record.RecordData.IPv4Address].DnsNames.Add($Record.HostName + "." + $Zone)

            #         if ($IncludeDNSRecords) {
            #             $DNSRecordsCached[$Record.RecordData.IPv4Address].List.Add($Record)
            #         }
            #         if ($null -ne $Record.TimeStamp) {
            #             $DNSRecordsCached[$Record.RecordData.IPv4Address].Timestamps.Add($Record.TimeStamp)
            #         } else {
            #             $DNSRecordsCached[$Record.RecordData.IPv4Address].Timestamps.Add("Not available")
            #         }
            #         if ($Null -ne $Record.Timestamp) {
            #             $DNSRecordsCached[$Record.RecordData.IPv4Address].Types.Add('Dynamic')
            #         } else {
            #             $DNSRecordsCached[$Record.RecordData.IPv4Address].Types.Add('Static')
            #         }
            #         $DNSRecordsCached[$Record.RecordData.IPv4Address] = [PSCustomObject] $DNSRecordsCached[$Record.RecordData.IPv4Address]

        }
    }
    # foreach ($DNS in $DNSRecordsCached.PSBase.Keys) {
    #     $DNSRecordsCached[$DNS].Count = $DNSRecordsCached[$DNS].DnsNames.Count
    #     if ($Prettify) {
    #         $DNSRecordsCached[$DNS].DnsNames = $DNSRecordsCached[$DNS].DnsNames -join ", "
    #         $DNSRecordsCached[$DNS].Timestamps = $DNSRecordsCached[$DNS].Timestamps -join ", "
    #         $DNSRecordsCached[$DNS].Types = $DNSRecordsCached[$DNS].Types -join ", "
    #     }
    # }
    # if ($AsHashtable) {
    #     $DNSRecordsCached
    # } else {
    #     $DNSRecordsCached.Values
    # }
}

#Get-WinDNSNSRecords -IncludeZone 'test.domain.pl' -IncludeDetails -Prettify -IncludeDNSRecords -AsHashtable | Format-Table *

#Get-DnsServerResourceRecord -ZoneName 'test.ad.evotec.xyz' -ComputerName 'ad1'

#>
<#

Clear-Host
$Forest = Get-WinADForestDetails
$SourceDNS = $Forest.Forest.DomainNamingMaster
$ZoneName = 'abb.com'
$List = 'ace', 'api.ace', 'cam.ace', 'api.cam.ace', 'ftp.ace'
$ListToCheck = foreach ($Name in $List) {
    $ResourceRecords = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $SourceDNS -RRType CName -Name $Name
    foreach ($Resource in $ResourceRecords) {
        [PSCustomObject]@{
            FullHostName  = if ($Name -eq $Resource.HostName) {
                $Resource.HostName + "." + $ZoneName
            } else {
                $Resource.HostName + "." + $Name + "." + $ZoneName
            }
            HostName      = $Resource.HostName
            HostNameAlias = $Resource.RecordData.HostNameAlias
            RecordData    = $Resource.RecordData
        }
    }
}
$ListToCheck | Format-Table

$FullList = foreach ($DC in $Forest.ForestDomainControllers) {
    foreach ($Record in $ListToCheck) {
        Write-Color -Text "Testing ", $DC.HostName, " for ", $Record.FullHostName -Color White, Green
        try {
            $ResolveDNS = Resolve-DnsName -Name $Record.FullHostName -Server $DC.HostName -ErrorAction Stop -Type CNAME
            [PSCustomObject] @{
                DC               = $DC.HostName
                HostName         = $Record.HostName
                FullRecord       = $Record.FullHostName
                NameResolved     = $ResolveDNS.Name
                NameHostResolved = $ResolveDNS.NameHost
                AsExpected       = if ("$($ResolveDNS.NameHost)." -eq "$($Record.HostNameAlias)") {
                    "Yes"
                } else {
                    "No"
                }
                Status           = "Resolving"
            }
            Write-Color -Text "Testing ", $DC.HostName, " completed. Record NameHost: ", $ResolveDNS.HostName, " NameHost: ", $ResolveDNS.NameHost -Color White, Green, White, Green, White, Green
        } catch {
            Write-Color -Text "Testing ", $DC.HostName, " failed ", $_.Exception.Message -Color White, Red, White, Red
            [PSCustomObject] @{
                DC               = $DC.HostName
                HostName         = $Record.HostName
                FullRecord       = $Record.FullHostName
                NameResolved     = "Not Resolved"
                NameHostResolved = "Not Resolved"
                AsExpected       = "No"
                Status           = "Failed"
            }
        }
    }
}


$FullList | Format-Table
#>