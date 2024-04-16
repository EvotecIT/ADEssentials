function Get-ADDNSObject {
    [CmdletBinding()]
    param(

    )

    $Object = Get-ADObject 'DC=PILAFU080,DC=ad.evotec.xyz,CN=MicrosoftDNS,DC=DomainDnsZones,DC=ad,DC=evotec,DC=xyz' -Properties dnsRecord, dnsTombstoned

    $DNSRecord = $Object.DnsRecord[0]
    $BinaryReader = New-BinaryReader -ByteArray $DnsRecord
    $ResourceRecord = [ordered] @{}
    # Property: RecordDataLength
    $ResourceRecord.RecordDataLength = $BinaryReader.ReadUInt16()
    # Property: RecordType
    $ResourceRecord.RecordType = [RecordType]($BinaryReader.ReadUInt16())
    $BinaryReader.ReadByte() | Out-Null
    # Property: Rank
    $ResourceRecord.Rank = [Rank]$BinaryReader.ReadByte()
    # Property: Flags
    $BinaryReader.ReadUInt16() | Out-Null
    # Property: UpdatedAtSerial
    $ResourceRecord.UpdatedAtSerial = $BinaryReader.ReadUInt32()
    # Property: TTL
    $ResourceRecord.TTL = $BinaryReader.ReadBEUInt32()
    # Property: Reserved
    $BinaryReader.ReadUInt32() | Out-Null

    $TimeStamp = $BinaryReader.ReadUInt32()
    if ($TimeStamp -gt 0) {
        $ResourceRecord.TimeStamp = (Get-Date '01/01/1601').AddHours($TimeStamp)
    }
    # Property: DnsTombstone
    [Boolean] $ResourceRecord.DnsTombstone = $Object.'dnstombstoned'

    # Mark the beginning of the RecordData
    $BinaryReader.SetPositionMarker()

    $Params = @{BinaryReader = $BinaryReader; ResourceRecord = $ResourceRecord }

    # Create appropriate properties for each record type
    switch ($ResourceRecord.RecordType) {
        ([Indented.Dns.RecordType]::A) { $ResourceRecord = ReadADDnsARecord @Params; break }
        ([RecordType]::NS) { $ResourceRecord = ReadADDnsNSRecord @Params; break }
        ([RecordType]::MD) { $ResourceRecord = ReadADDnsMDRecord @Params; break }
        ([RecordType]::MF) { $ResourceRecord = ReadADDnsMFRecord @Params; break }
        ([RecordType]::CNAME) { $ResourceRecord = ReadADDnsCNAMERecord @Params; break }
        ([RecordType]::SOA) { $ResourceRecord = ReadADDnsSOARecord @Params; break }
        ([RecordType]::MB) { $ResourceRecord = ReadADDnsMBRecord @Params; break }
        ([RecordType]::MG) { $ResourceRecord = ReadADDnsMGRecord @Params; break }
        ([RecordType]::MR) { $ResourceRecord = ReadADDnsMRRecord @Params; break }
        ([RecordType]::WKS) { $ResourceRecord = ReadADDnsWKSRecord @Params; break }
        ([RecordType]::PTR) { $ResourceRecord = ReadADDnsPTRRecord @Params; break }
        ([RecordType]::HINFO) { $ResourceRecord = ReadADDnsHINFORecord @Params; break }
        ([RecordType]::MINFO) { $ResourceRecord = ReadADDnsMINFORecord @Params; break }
        ([RecordType]::MX) { $ResourceRecord = ReadADDnsMXRecord @Params; break }
        ([RecordType]::TXT) { $ResourceRecord = ReadADDnsTXTRecord @Params; break }
        ([RecordType]::RP) { $ResourceRecord = ReadADDnsRPRecord @Params; break }
        ([RecordType]::AFSDB) { $ResourceRecord = ReadADDnsAFSDBRecord @Params; break }
        ([RecordType]::X25) { $ResourceRecord = ReadADDnsX25Record @Params; break }
        ([RecordType]::ISDN) { $ResourceRecord = ReadADDnsISDNRecord @Params; break }
        ([RecordType]::RT) { $ResourceRecord = ReadADDnsRTRecord @Params; break }
        ([RecordType]::SIG) { $ResourceRecord = ReadADDnsSIGRecord @Params; break }
        ([RecordType]::KEY) { $ResourceRecord = ReadADDnsKEYRecord @Params; break }
        ([RecordType]::AAAA) { $ResourceRecord = ReadADDnsAAAARecord @Params; break }
        ([RecordType]::NXT) { $ResourceRecord = ReadADDnsNXTRecord @Params; break }
        ([RecordType]::SRV) { $ResourceRecord = ReadADDnsSRVRecord @Params; break }
        ([RecordType]::ATMA) { $ResourceRecord = ReadADDnsATMARecord @Params; break }
        ([RecordType]::WINS) { $ResourceRecord = ReadADDnsWINSRecord @Params; break }
        ([RecordType]::WINSR) { $ResourceRecord = ReadADDnsWINSRRecord @Params; break }
        default {
            ReadADDnsUnknownRecord @Params
        }
    }

    $ResourceRecord
}