function ReadADDnsARecord {
    # .SYNOPSIS
    #   Reads properties for an A record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    ADDRESS                    |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.A

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.A")

    # Property: IPAddress
    $ResourceRecord | Add-Member IPAddress -MemberType NoteProperty -Value $BinaryReader.ReadIPv4Address()

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.IPAddress.ToString()
    }

    return $ResourceRecord
}

function ReadADDnsNSRecord {
    # .SYNOPSIS
    #   Reads properties for an NS record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   NSDNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.NS

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.NS")

    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Hostname
    }

    return $ResourceRecord
}

function ReadADDnsMDRecord {
    # .SYNOPSIS
    #   Reads properties for an MD record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   Present for legacy support; the MD record is marked as obsolete in favour of MX.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   MADNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MD

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MD")

    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Hostname
    }

    return $ResourceRecord
}

function ReadADDnsMFRecord {
    # .SYNOPSIS
    #   Reads properties for an MF record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   Present for legacy support; the MF record is marked as obsolete in favour of MX.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   MADNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MF

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MF")

    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Hostname
    }

    return $ResourceRecord
}

function ReadADDnsCNAMERecord {
    # .SYNOPSIS
    #   Reads properties for an CNAME record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                     CNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.CNAME

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.CNAME")

    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Hostname
    }

    return $ResourceRecord
}

function ReadADDnsSOARecord {
    # .SYNOPSIS
    #   Reads properties for an SOA record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                     SERIAL                    |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    REFRESH                    |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                     RETRY                     |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    EXPIRE                     |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                  MINIMUM TTL                  |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                     DATA                      /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /               RESPONSIBLE PERSON              /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.SOA

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.SOA")

    # Property: Serial
    $ResourceRecord | Add-Member Serial -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
    # Property: Refresh
    $ResourceRecord | Add-Member Refresh -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
    # Property: Retry
    $ResourceRecord | Add-Member Retry -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
    # Property: Expire
    $ResourceRecord | Add-Member Expire -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
    # Property: MinimumTTL
    $ResourceRecord | Add-Member MinimumTTL -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
    # Property: NameServer
    $ResourceRecord | Add-Member NameServer -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)
    # Property: ResponsiblePerson
    $ResourceRecord | Add-Member ResponsiblePerson -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1} (`n" +
            "    {2} ; serial`n" +
            "    {3} ; refresh ({4})`n" +
            "    {5} ; retry ({6})`n" +
            "    {7} ; expire ({8})`n" +
            "    {9} ; minimum ttl ({10})`n" +
            ")",
            $this.NameServer,
            $this.ResponsiblePerson,
            $this.Serial.ToString().PadRight(10, ' '),
            $this.Refresh.ToString().PadRight(10, ' '),
      (ConvertTo-TimeSpanString -Seconds $this.Refresh),
            $this.Retry.ToString().PadRight(10, ' '),
      (ConvertTo-TimeSpanString -Seconds $this.Retry),
            $this.Expire.ToString().PadRight(10, ' '),
      (ConvertTo-TimeSpanString -Seconds $this.Expire),
            $this.MinimumTTL.ToString().PadRight(10, ' '),
      (ConvertTo-TimeSpanString -Seconds $this.Refresh))
    }

    return $ResourceRecord
}

function ReadADDnsMBRecord {
    # .SYNOPSIS
    #   Reads properties for an MB record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   The MB record is marked as experimental.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   MADNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MB

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MB")

    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Hostname
    }

    return $ResourceRecord
}

function ReadADDnsMGRecord {
    # .SYNOPSIS
    #   Reads properties for an MG record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   The MG record is marked as experimental.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   MGMNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MG

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MG")

    # Property: MailboxName
    $ResourceRecord | Add-Member Mailbox -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.MailboxName
    }

    return $ResourceRecord
}

function ReadADDnsMRRecord {
    # .SYNOPSIS
    #   Reads properties for an MR record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   The MR record is marked as experimental.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   NEWNAME                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MR

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MR")

    # Property: MailboxName
    $ResourceRecord | Add-Member MailboxName -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.MailboxName
    }

    return $ResourceRecord
}

function ReadADDnsWKSRecord {
    # TO-DO
    #
    # .SYNOPSIS
    #   Reads properties for an WKS record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    ADDRESS                    |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |       PROTOCOL        |                       /
    #    +--+--+--+--+--+--+--+--+                       /
    #    /                                               /
    #    /                   <BIT MAP>                   /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.WKS

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.WKS")

    # Property: IPAddress
    $ResourceRecord | Add-Member IPAddress -MemberType NoteProperty -Value $BinaryReader.ReadIPv4Address()
    # Property: IPProtocolNumber
    $ResourceRecord | Add-Member IPProtocolNumber -MemberType NoteProperty -Value $BinaryReader.ReadByte()
    # Property: IPProtocolType
    $ResourceRecord | Add-Member IPProtocolType -MemberType ScriptProperty -Value {
        [Net.Sockets.ProtocolType]$this.IPProtocolNumber
    }

    # BitMap length in bytes, discounting the first five bytes (IPAddress and ProtocolType).
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - 5)
    $BinaryString = , $Bytes | ConvertTo-String -Binary

    # Property: BitMap
    $ResourceRecord | Add-Member BitMap -MemberType NoteProperty -Value $BinaryString
    # Property: Ports (numeric)
    $ResourceRecord | Add-Member Ports -MemberType ScriptProperty -Value {
        $Length = $BinaryString.Length; $Ports = @()
        for ([UInt16]$i = 0; $i -lt $Length; $i++) {
            if ($BinaryString[$i] -eq 1) {
                $Ports += $i
            }
        }
        $Ports
    }

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1} ( {2} )",
            $this.IPAddress,
            $this.IPProtocolType,
            "$($this.Ports)")
    }

    return $ResourceRecord
}

function ReadADDnsPTRRecord {
    # .SYNOPSIS
    #   Reads properties for an PTR record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   PTRDNAME                    /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.PTR

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.PTR")

    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Hostname
    }

    return $ResourceRecord
}

function ReadADDnsHINFORecord {
    # .SYNOPSIS
    #   Reads properties for an HINFO record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                      CPU                      /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                       OS                      /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.HINFO

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.HINFO")

    # Property: CPU
    $ResourceRecord | Add-Member CPU -MemberType NoteProperty -Value (ReadADDnsCharacterString $BinaryReader)

    # Property: OS
    $ResourceRecord | Add-Member OS -MemberType NoteProperty -Value (ReadADDnsCharacterString $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("""{0}"" ""{1}""",
            $this.CPU,
            $this.OS)
    }

    return $ResourceRecord
}

function ReadADDnsMINFORecord {
    # .SYNOPSIS
    #   Reads properties for an MINFO record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                    RMAILBX                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                    EMAILBX                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MINFO

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MINFO")

    # Property: ResponsibleMailbox
    $ResourceRecord | Add-Member ResponsibleMailbox -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)
    # Property: ErrorMailbox
    $ResourceRecord | Add-Member ErrorMailbox -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1}",
            $this.ResponsibleMailbox,
            $this.ErrorMailbox)
    }

    return $ResourceRecord
}

function ReadADDnsMXRecord {
    # .SYNOPSIS
    #   Reads properties for an MX record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                  PREFERENCE                   |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   EXCHANGE                    /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.MX

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.MX")

    # Property: Preference
    $ResourceRecord | Add-Member Preference -MemberType NoteProperty -Value $BinaryReader.ReadUInt16()
    # Property: Exchange
    $ResourceRecord | Add-Member Exchange -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1}",
            $this.Preference.ToString().PadRight(5, ' '),
            $this.Exchange)
    }

    return $ResourceRecord
}

function ReadADDnsTXTRecord {
    # .SYNOPSIS
    #   Reads properties for an TXT record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   TXT-DATA                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.TXT

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.TXT")

    # Property: Text
    $ResourceRecord | Add-Member Text -MemberType NoteProperty -Value (ReadADDnsCharacterString $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.Text
    }

    return $ResourceRecord
}

function ReadADDnsRPRecord {
    # .SYNOPSIS
    #   Reads properties for an RP record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                    RMAILBX                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                    EMAILBX                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.RP

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.RP")

    # Property: ResponsibleMailbox
    $ResourceRecord | Add-Member ResponsibleMailbox -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)
    # Property: TXTDomainName
    $ResourceRecord | Add-Member TXTDomainName -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1}",
            $this.ResponsibleMailbox,
            $this.TXTDomainName)
    }

    return $ResourceRecord
}

function ReadADDnsAFSDBRecord {
    # .SYNOPSIS
    #   Reads properties for an AFSDB record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    SUBTYPE                    |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                    HOSTNAME                   /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.AFSDB

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.AFSDB")

    $SubType = $BinaryReader.ReadUInt16()
    if ([Enum]::IsDefined([Idented.Dns.AFSDBSubType], $SubType)) {
        $SubType = [Indented.Dns.AFSDBSubType]$SubType
    }

    # Property: SubType
    $ResourceRecord | Add-Member SubType -MemberType NoteProperty -Value $SubType
    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1}",
            $this.SubType,
            $this.Hostname)
    }

    return $ResourceRecord
}

function ReadADDnsX25Record {
    # .SYNOPSIS
    #   Reads properties for an X25 record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                PSDNADDRESS                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.X25

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.X25")

    # Property: PSDNAddress
    $ResourceRecord | Add-Member PSDNAddress -MemberType NoteProperty -Value (ReadADDnsCharacterString $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.PSDNAddress
    }

    return $ResourceRecord
}

function ReadADDnsISDNRecord {
    # .SYNOPSIS
    #   Reads properties for an ISDN record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                ISDNADDRESS                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                 SUBADDRESS                    /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.ISDN

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.ISDN")

    # Property: ISDNAddress
    $ResourceRecord | Add-Member ISDNAddress -MemberType NoteProperty -Value (ReadADDnsCharacterString $BinaryReader)
    # Property: SubAddress
    $ResourceRecord | Add-Member SubAddress -MemberType NoteProperty -Value (ReadADDnsCharacterString $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("""{0}"" ""{1}""",
            $this.ISDNAddress,
            $this.SubAddress)
    }

    return $ResourceRecord
}

function ReadADDnsRTRecord {
    # .SYNOPSIS
    #   Reads properties for an RT record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                  PREFERENCE                   |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   EXCHANGE                    /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.RT

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.RT")

    # Property: Preference
    $ResourceRecord | Add-Member Preference -MemberType NoteProperty -Value $BinaryReader.ReadUInt16()
    # Property: IntermediateHost
    $ResourceRecord | Add-Member IntermediateHost -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1}",
            $this.Preference.ToString().PadRight(5, ' '),
            $this.IntermediateHost)
    }

    return $ResourceRecord
}

function ReadADDnsSIGRecord {
    # TO-DO
    #
    # .SYNOPSIS
    #   Reads properties for an SIG record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                 TYPE COVERED                  |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |       ALGORITHM       |         LABELS        |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                 ORIGINAL TTL                  |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |             SIGNATURE EXPIRATION              |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |              SIGNATURE INCEPTION              |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    KEY TAG                    |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                 SIGNER'S NAME                 /
    #    /                                               /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   SIGNATURE                   /
    #    /                                               /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.SIG

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.SIG")

    # Property: TypeCovered
    $ResourceRecord | Add-Member TypeCovered -MemberType NoteProperty -Value ([Indented.Dns.RecordType]$BinaryReader.ReadUIn16())
    # Property: Algorithm
    $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([Indented.Dns.EncryptionAlgorithm]$BinaryReader.ReadByte())
    # Property: Labels
    $ResourceRecord | Add-Member Labels -MemberType NoteProperty -Value $BinaryReader.ReadByte()
    # Property: OriginalTTL
    $ResourceRecord | Add-Member OriginalTTL -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: SignatureExpiration
    $ResourceRecord | Add-Member SignatureExpiration -MemberType NoteProperty -Value ((Get-Date "01/01/1970").AddSeconds($BinaryReader.ReadUInt32()))
    # Property: SignatureInception
    $ResourceRecord | Add-Member SignatureInception -MemberType NoteProperty -Value ((Get-Date "01/01/1970").AddSeconds($BinaryReader.ReadUInt32()))
    # Property: KeyTag
    $ResourceRecord | Add-Member KeyTag -MemberType NoteProperty -Value $BinaryReader.ReadUInt16()
    # Property: SignersName
    $ResourceRecord | Add-Member SignersName -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)
    # Property: Signature
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
    $Base64String = , $Bytes | ConvertTo-String -Base64
    $ResourceRecord | Add-Member Signature -MemberType NoteProperty -Value $Base64String

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1} {2} ( ; type-cov={0}, alg={1}, labels={2}`n" +
            "    {3} ; Signature expiration`n" +
            "    {4} ; Signature inception`n" +
            "    {5} ; Key identifier`n" +
            "    {6} ; Signer`n" +
            "    {7} ; Signature`n" +
            ")",
            $this.TypeCovered,
      (([Byte]$this.Algorithm).ToString()),
      ([Byte]$this.Labels.ToString()),
            $this.SignatureExpiration,
            $this.SignatureInception,
            $this.KeyTag,
            $this.SignersName,
            $this.Signature)
    }

    return $ResourceRecord
}

function ReadADDnsKEYRecord {
    # TO-DO
    #
    # .SYNOPSIS
    #   Reads properties for an KEY record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                     FLAGS                     |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |        PROTOCOL       |       ALGORITHM       |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                  PUBLIC KEY                   /
    #    /                                               /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    #   The flags field takes the following format, discussed in RFC 2535 3.1.2:
    #
    #      0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5
    #    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    #    |  A/C  | Z | XT| Z | Z | NAMTYP| Z | Z | Z | Z |      SIG      |
    #    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.KEY

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.KEY")

    # Property: Flags
    $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value ($BinaryReader.ReadUInt16())
    # Property: Authentication/Confidentiality (bit 0 and 1 of Flags)
    $ResourceRecord | Add-Member AuthenticationConfidentiality -MemberType ScriptProperty -Value {
        [Indented.Dns.KEYAC]([Byte]($this.Flags -shr 14))
    }
    # Property: Flags extension (bit 3)
    if (($Flags -band 0x1000) -eq 0x1000) {
        $ResourceRecord | Add-Member FlagsExtension -MemberType NoteProperty -Value $BinaryReader.ReadUInt16()
    }
    # Property: NameType (bit 6 and 7)
    $ResourceRecord | Add-Member NameType -MemberType ScriptProperty -Value {
        [Indented.Dns.KEYNameType]([Byte](($Flags -band 0x0300) -shr 9))
    }
    # Property: SignatoryField (bit 12 and 15)
    $ResourceRecord | Add-Member SignatoryField -MemberType ScriptProperty -Value {
        [Boolean]($this.Flags -band 0x000F)
    }
    # Property: Protocol
    $ResourceRecord | Add-Member Protocol -MemberType NoteProperty -Value ([Indented.Dns.KEYProtocol]$BinaryReader.ReadByte())
    # Property: Algorithm
    $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([Indented.Dns.EncryptionAlgorithm]$BinaryReader.ReadByte())

    if ($ResourceRecord.AuthenticationConfidentiality -ne [Indented.Dns.KEYAC]::NoKey) {
        # Property: PublicKey
        $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
        $Base64String = , $Bytes | ConvertTo-String -Base64
        $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String
    }

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1} {2} ( {3} )",
            $this.Flags,
      ([Byte]$this.Protocol).ToString(),
      ([Byte]$this.Algorithm).ToString(),
            $this.PublicKey)
    }

    return $ResourceRecord
}

function ReadADDnsAAAARecord {
    # .SYNOPSIS
    #   Reads properties for an AAAA record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    ADDRESS                    |
    #    |                                               |
    #    |                                               |
    #    |                                               |
    #    |                                               |
    #    |                                               |
    #    |                                               |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.AAAA

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.AAAA")

    # Property: IPAddress
    $ResourceRecord | Add-Member IPAddress -MemberType NoteProperty -Value $BinaryReader.ReadIPv6Address()

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.IPAddress.ToString()
    }

    return $Record
}

function ReadADDnsNXTRecord {
    # TO-DO
    #
    # .SYNOPSIS
    #   Reads properties for an NXT record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   DOMAINNAME                  /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                   <BIT MAP>                   /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.NXT
    # .LINK
    #   http://www.ietf.org/rfc/rfc2535.txt
    #   http://www.ietf.org/rfc/rfc3755.txt

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.NXT")

    # Property: DomainName
    $ResourceRecord | Add-Member DomainName -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RRTypeBitMap
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
    $BinaryString = , $Bytes | ConvertTo-String -Binary
    $ResourceRecord | Add-Member RRTypeBitMap -MemberType NoteProperty -Value $BinaryString
    # Property: RRTypes
    $ResourceRecord | Add-Member RRTypes -MemberType ScriptProperty -Value {
        $RRTypes = @()
        [Enum]::GetNames([Indented.Dns.RecordType]) |
        Where-Object { [UInt16][Indented.Dns.RecordType]::$_ -lt $BinaryString.Length -and
            $BinaryString[([UInt16][Indented.Dns.RecordType]::$_)] -eq '1' } |
        ForEach-Object {
            $RRTypes += [Indented.Dns.RecordType]::$_
        }
        $RRTypes
    }

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {2}",
            $this.DomainName,
            "$($this.RRTypes)")
    }

    return $ResourceRecord
}

function ReadADDnsSRVRecord {
    # .SYNOPSIS
    #   Reads properties for an SRV record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                   PRIORITY                    |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                    WEIGHT                     |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                     PORT                      |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                    TARGET                     /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.SRV

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.SRV")

    # Property: Priority
    $ResourceRecord | Add-Member Priority -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
    # Property: Weight
    $ResourceRecord | Add-Member Weight -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
    # Property: Port
    $ResourceRecord | Add-Member Port -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
    # Property: Hostname
    $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ReadADDnsDomainName $BinaryReader)

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        [String]::Format("{0} {1} {2} {3}",
            $this.Priority,
            $this.Weight,
            $this.Port,
            $this.Hostname)
    }

    return $ResourceRecord
}

function ReadADDnsATMARecord {
    # .SYNOPSIS
    #   Reads properties for an ATMA record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |         FORMAT        |                       |
    #    +--+--+--+--+--+--+--+--+                       |
    #    /                   ATMADDRESS                  /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.ATMA

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.ATMA")

    # Format
    $Format = [Indented.Dns.ATMAFormat]$BinaryReader.ReadByte()

    # ATMAAddress length, discounting the first byte (Format)
    $Length = $RecorceRecord.RecordDataLength - 1
    $ATMAAddress = New-Object Text.StringBuilder

    switch ($Format) {
    ([Indented.Dns.ATMAFormat]::AESA) {
            for ($i = 0; $i -lt $Length; $i++) {
                $ATMAAddress.Append($BinaryReader.ReadChar()) | Out-Null
            }
            break
        }
    ([Indented.Dns.ATMAFormat]::E164) {
            for ($i = 0; $i -lt $Length; $i++) {
                if ((3, 6) -contains $i) { $ATMAAddress.Append(".") | Out-Null }
                $ATMAAddress.Append($BinaryReader.ReadChar()) | Out-Null
            }
            break
        }
    ([Indented.Dns.ATMAFormat]::NSAP) {
            for ($i = 0; $i -lt $Length; $i++) {
                if ((1, 3, 13, 19) -contains $i) { $ATMAAddress.Append(".") | Out-Null }
                $ATMAAddress.Append(('{0:X2}' -f $BinaryReader.ReadByte())) | Out-Null
            }
            break
        }
    }

    # Property: Format
    $ResourceRecord | Add-Member Format -MemberType NoteProperty -Value $Format
    # Property: ATMAAddress
    $ResourceRecord | Add-Member ATMAAddress -MemberType NoteProperty -Value $ATMAAddress.ToString()

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $this.ATMAAddress
    }

    return $ResourceRecord
}

function ReadADDnsDHCIDRecord {
    # .SYNOPSIS
    #   Reads properties for an DHCID record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                  <anything>                   /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.DHCID

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.DHCID")

    # Property: BinaryData
    $ResourceRecord | Add-Member BinaryData -MemberType NoteProperty -Value ($BinaryReader.ReadBytes($ResourceRecord.RecordDataLength))

    return $ResourceRecord
}

function ReadADDnsWINSRecord {
    # TO-DO
    #
    # .SYNOPSIS
    #   Reads properties for an WINS record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                  LOCAL FLAG                   |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                LOOKUP TIMEOUT                 |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                 CACHE TIMEOUT                 |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |               NUMBER OF SERVERS               |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                SERVER IP LIST                 /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.WINS
    # .LINK
    #   http://msdn.microsoft.com/en-us/library/ms682748%28VS.85%29.aspx

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.WINS")

    # Property: MappingFlag
    $ResourceRecord | Add-Member MappingFlag -MemberType NoteProperty -Value ([Indented.Dns.WINSMappingFlag]$BinaryReader.ReadUInt32())
    # Property: LookupTimeout
    $ResourceRecord | Add-Member LookupTimeout -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: CacheTimeout
    $ResourceRecord | Add-Member CacheTimeout -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: NumberOfServers
    $ResourceRecord | Add-Member NumberOfServers -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: ServerList
    $ResourceRecord | Add-Member ServerList -MemberType NoteProperty -Value @()

    for ($i = 0; $i -lt $ResourceRecord.NumberOfServers; $i++) {
        $ResourceRecord.ServerList += $BinaryReader.ReadIPv4Address()
    }

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $Value = [String]::Format("L{0} C{1} ( {2} )",
            $this.LookupTimeout,
            $this.CacheTimeout,
            "$($this.ServerList)")
        if ($this.MappingFlag -eq [Indented.Dns.WINSMappingFlag]::NoReplication) {
            $Value = "LOCAL $Value"
        }
        $Value
    }

    return $Record
}

function ReadADDnsWINSRRecord {
    # TO-DO
    #
    # .SYNOPSIS
    #   Reads properties for an WINSR record from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                  LOCAL FLAG                   |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                LOOKUP TIMEOUT                 |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |                 CACHE TIMEOUT                 |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    |               NUMBER OF SERVERS               |
    #    |                                               |
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                  DOMAIN NAME                  /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.WINSR
    # .LINK
    #   http://msdn.microsoft.com/en-us/library/ms682748%28VS.85%29.aspx

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.WINSR")

    # Property: LocalFlag
    $ResourceRecord | Add-Member LocalFlag -MemberType NoteProperty -Value ([Indented.Dns.WINSMappingFlag]$BinaryReader.ReadUInt32())
    # Property: LookupTimeout
    $ResourceRecord | Add-Member LookupTimeout -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: CacheTimeout
    $ResourceRecord | Add-Member CacheTimeout -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: NumberOfDomains
    $ResourceRecord | Add-Member NumberOfDomains -MemberType NoteProperty -Value $BinaryReader.ReadUInt32()
    # Property: DomainNameList
    $ResourceRecord | Add-Member DomainNameList -MemberType NoteProperty -Value @()

    for ($i = 0; $i -lt $ResourceRecord.NumberOfDomains; $i++) {
        $ResourceRecord.DomainNameList += ReadADDnsDomainName $BinaryReader
    }

    # Property: RecordData
    $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
        $Value = [String]::Format("L{0} C{1} ( {2} )",
            $this.LookupTimeout,
            $this.CacheTimeout,
            "$($this.DomainNameList)")
        if ($this.LocalFlag -eq [Indented.Dns.WINSMappingFlag]::NoReplication) {
            $Value = "LOCAL $Value"
        }
        $Value
    }

    return $Record
}


# function Get-ADDnsPartition {
#     # .SYNOPSIS
#     #   Get all partitions which are likely to contain DNS zones and records from Active Directory.
#     # .DESCRIPTION
#     #   Get-ADDnsPartition executes a search against the configuration subtree to locate partitions which may hold DNS information.
#     # .PARAMETER Credential
#     #   Specifies a user account that has permittion to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
#     # .PARAMETER Server
#     #   By default, Get-ADDnsPartition will use serverless binding to locate a suitable directory server. If the query must be targetted, or run against a non-local forest domain, a server must be specified.
#     # .INPUTS
#     #   System.String
#     # .OUTPUTS
#     #   Indented.Dns.AD.Partition
#     # .EXAMPLE
#     #   Get-ADDnsPartition
#     # .EXAMPLE
#     #   Get-ADDnsPartition -Credential (Get-Credential)
#     # .EXAMPLE
#     #   Get-ADDnsPartition -Server "remoteserver.testdomain.com" -Credential (Get-Credential)

#     [CmdLetBinding()]
#     param(
#         [String]$Server = "",

#         [Parameter(ParameterSetName = "")]
#         [PSCredential]$Credential
#     )

#     $Params = @{}
#     if ($Credential) {
#         $Params.Add("Credential", $Credential)
#     }
#     $Params.Add("Server", "$Server")

#     # Find the configuration NC
#     $RootDSE = Get-LdapObject @Params -SearchScope Base
#     $ConfigurationNamingContext = $RootDSE.Attributes['configurationnamingcontext'].Item(0)

#     $LdapFilter = "(&(objectCategory=crossRef)(!name=Enterprise Configuration)(!name=Enterprise Schema))"
#     $Properties = "name", "whenCreated", "objectGUID", "msDS-NC-Replica-Locations", "nCName", "nETBIOSName"

#     Get-LdapObject @Params -SearchRoot $ConfigurationNamingContext -LdapFilter $LdapFilter -Properties $Properties | ForEach-Object {

#         $DN = [String]$_.Attributes['ncname'].Item(0)
#         if ($_.Attributes.AttributeNames -contains 'netbiosname') {
#             $DN = "CN=MicrosoftDNS,CN=System,$DN"
#             $PartitionType = "Legacy"
#         }
#         if ($DN -match '^dc=DomainDnsZones') {
#             $PartitionType = "Domain"
#         } elseif ($DN -match '^dc=ForestDnsZones') {
#             $PartitionType = "Forest"
#         } elseif (!$PartitionType) {
#             $PartitionType = "Custom"
#         }

#         $ReplicaLocations = @()
#         if ($_.Attributes.AttributeNames -contains 'msds-nc-replica-locations') {
#             $Count = $_.Attributes['msds-nc-replica-locations'].Count
#             for ($i = 0; $i -lt $Count; $i++) {
#                 $ReplicaLocations += $_.Attributes['msds-nc-replica-locations'].Item($i) -replace '^[^,]+,CN=|,.+$'
#             }
#         }

#         $ADDnsPartition = New-Object PsObject -Property ([Ordered]@{
#                 DN               = $DN;
#                 PartitionType    = $PartitionType;
#                 ReplicaLocations = $ReplicaLocations;
#                 objectGUID       = ([GUID]$_.Attributes['objectguid'].Item(0));
#                 WhenCreated      = ([DateTime]::ParseExact(($_.Attributes['whencreated'].Item(0)), "yyyyMMddHHmmss.0Z", [Globalization.CultureInfo]::CurrentCulture))
#             })
#         $ADDnsPartition.PsObject.TypeNames.Add("Indented.Dns.AD.Partition")

#         $ADDnsPartition
#     }
# }


function ReadADDnsDomainName {
    # .SYNOPSIS
    #   Reads a domain-name from dnsRecord.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   Domain name values are held in the following format:
    #
    #                                  1  1  1  1  1  1
    #    0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #  |         LENGTH        |   NUMBER OF LABELS    |
    #  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #  |      LABEL LENGTH     |                       |
    #  |--+--+--+--+--+--+--+--+                       |
    #  /                     DATA                      /
    #  /                                               /
    #  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   System.String

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader
    )

    $Length = $BinaryReader.ReadByte()
    $NumberOfLabels = $BinaryReader.ReadByte()

    $DomainName = @()

    for ($i = 0; $i -lt $NumberOfLabels; $i++) {
        $LabelLength = $BinaryReader.ReadByte()
        $DomainName += New-Object String (, $BinaryReader.ReadChars($LabelLength))
    }

    # Drop the terminating byte
    $BinaryReader.ReadByte() | Out-Null

    return ([String]::Join('.', $DomainName) + '.')
}

function ReadADDnsCharacterString {
    # .SYNOPSIS
    #   Reads a character-string from a DNS message.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   Character string values are held in the following format:
    #
    #                                  1  1  1  1  1  1
    #    0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #  |         LENGTH        |                       |
    #  |--+--+--+--+--+--+--+--+                       |
    #  /                     DATA                      /
    #  /                                               /
    #  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .INPUTS
    #   System.IO.BinaryReader
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   System.String

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader
    )

    $Length = $BinaryReader.ReadByte()
    $CharacterString = New-Object String (, $BinaryReader.ReadChars($Length))

    return $CharacterString
}

function ReadADDnsResourceRecord {
    # .SYNOPSIS
    #   Reads common DNS resource record fields from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #   Reads a byte array in the following format:
    #
    #                                     1  1  1  1  1  1
    #       0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                 RDATA LENGTH                  |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                      TYPE                     |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |        VERSION        |         RANK          |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                     FLAGS                     |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                 UPDATEDATSERIAL               |
    #     |                                               |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                      TTL                      |
    #     |                                               |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                    RESERVED                   |
    #     |                                               |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #     |                   TIMESTAMP                   |
    #     |                                               |
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    #     /                     RDATA                     /
    #     /                                               /
    #     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER SearchResultEntry
    #   A SearchResultEntry passed from Get-ADDnsRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #   System.DirectoryServices.Protocols.SearchResultEntry
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [DirectoryServices.Protocols.SearchResultEntry]$SearchResultEntry
    )

    $ResourceRecord = New-Object PsObject -Property ([Ordered]@{
            Name             = ($SearchResultEntry.Attributes['name'].Item(0));
            TTL              = [UInt32]0;
            RecordClass      = [Indented.Dns.RecordClass]::IN;
            RecordType       = [Indented.Dns.RecordType]::Empty;
            RecordDataLength = 0;
            RecordData       = "";
            DN               = $SearchResultEntry.DistinguishedName;
            ZoneName         = "";
            objectGUID       = ([GUID]$SearchResultEntry.Attributes['objectguid'].Item(0));
            Rank             = $null;
            TimeStamp        = $null;
            UpdatedAtSerial  = $null;
            WhenCreated      = ([DateTime]::ParseExact(($SearchResultEntry.Attributes['whencreated'].Item(0)), "yyyyMMddHHmmss.0Z", [Globalization.CultureInfo]::CurrentCulture));
            DnsTombstone     = $false;
        })
    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord")

    # Property: ZoneName
    $ResourceRecord.ZoneName = $ResourceRecord.DN -replace '^DC=[^,]+,DC=|,.+$'
    # Property: Name - rebuild the name; concatenate with the zone name
    if ($ResourceRecord.Name -eq '@') {
        $ResourceRecord.Name = "$($ResourceRecord.ZoneName)."
    } else {
        $ResourceRecord.Name = [String]::Format("{0}.{1}.",
            $ResourceRecord.Name,
            $ResourceRecord.ZoneName)
    }
    # Property: RecordDataLength
    $ResourceRecord.RecordDataLength = $BinaryReader.ReadUInt16()
    # Property: RecordType
    $ResourceRecord.RecordType = [Indented.Dns.RecordType]($BinaryReader.ReadUInt16())
    # Property: Version
    $BinaryReader.ReadByte() | Out-Null
    # Property: Rank
    $ResourceRecord.Rank = [Indented.Dns.Rank]$BinaryReader.ReadByte()
    # Property: Flags
    $BinaryReader.ReadUInt16() | Out-Null
    # Property: UpdatedAtSerial
    $ResourceRecord.UpdatedAtSerial = $BinaryReader.ReadUInt32()
    # Property: TTL
    $ResourceRecord.TTL = $BinaryReader.ReadBEUInt32()
    # Property: Reserved
    $BinaryReader.ReadUInt32() | Out-Null
    # Property: TimeStamp
    $TimeStamp = $BinaryReader.ReadUInt32()
    if ($TimeStamp -gt 0) {
        $ResourceRecord.TimeStamp = (Get-Date '01/01/1601').AddHours($TimeStamp)
    }
    # Property: DnsTombstone
    if ($SearchResultEntry.Attributes['dnstombstoned']) {
        [Boolean]$ResourceRecord.DnsTombstone = $SearchResultEntry.Attributes['dnstombstoned'].Item(0)
    }

    # Method: ToString
    $ResourceRecord | Add-Member ToString -MemberType ScriptMethod -Force -Value {
        return [String]::Format("{0} {1} {2} {3} {4}",
            $this.Name.PadRight(19, ' '),
            $this.TTL.ToString().PadRight(5, ' '),
            $this.RecordClass.ToString().PadRight(5, ' '),
            $this.RecordType.ToString().PadRight(5, ' '),
            $this.RecordData)
    }

    # Mark the beginning of the RecordData
    $BinaryReader.SetPositionMarker()

    $Params = @{BinaryReader = $BinaryReader; ResourceRecord = $ResourceRecord }

    # Create appropriate properties for each record type
    switch ($ResourceRecord.RecordType) {
    ([Indented.Dns.RecordType]::A) { $ResourceRecord = ReadADDnsARecord @Params; break }
    ([Indented.Dns.RecordType]::NS) { $ResourceRecord = ReadADDnsNSRecord @Params; break }
    ([Indented.Dns.RecordType]::MD) { $ResourceRecord = ReadADDnsMDRecord @Params; break }
    ([Indented.Dns.RecordType]::MF) { $ResourceRecord = ReadADDnsMFRecord @Params; break }
    ([Indented.Dns.RecordType]::CNAME) { $ResourceRecord = ReadADDnsCNAMERecord @Params; break }
    ([Indented.Dns.RecordType]::SOA) { $ResourceRecord = ReadADDnsSOARecord @Params; break }
    ([Indented.Dns.RecordType]::MB) { $ResourceRecord = ReadADDnsMBRecord @Params; break }
    ([Indented.Dns.RecordType]::MG) { $ResourceRecord = ReadADDnsMGRecord @Params; break }
    ([Indented.Dns.RecordType]::MR) { $ResourceRecord = ReadADDnsMRRecord @Params; break }
    ([Indented.Dns.RecordType]::WKS) { $ResourceRecord = ReadADDnsWKSRecord @Params; break }
    ([Indented.Dns.RecordType]::PTR) { $ResourceRecord = ReadADDnsPTRRecord @Params; break }
    ([Indented.Dns.RecordType]::HINFO) { $ResourceRecord = ReadADDnsHINFORecord @Params; break }
    ([Indented.Dns.RecordType]::MINFO) { $ResourceRecord = ReadADDnsMINFORecord @Params; break }
    ([Indented.Dns.RecordType]::MX) { $ResourceRecord = ReadADDnsMXRecord @Params; break }
    ([Indented.Dns.RecordType]::TXT) { $ResourceRecord = ReadADDnsTXTRecord @Params; break }
    ([Indented.Dns.RecordType]::RP) { $ResourceRecord = ReadADDnsRPRecord @Params; break }
    ([Indented.Dns.RecordType]::AFSDB) { $ResourceRecord = ReadADDnsAFSDBRecord @Params; break }
    ([Indented.Dns.RecordType]::X25) { $ResourceRecord = ReadADDnsX25Record @Params; break }
    ([Indented.Dns.RecordType]::ISDN) { $ResourceRecord = ReadADDnsISDNRecord @Params; break }
    ([Indented.Dns.RecordType]::RT) { $ResourceRecord = ReadADDnsRTRecord @Params; break }
    ([Indented.Dns.RecordType]::SIG) { $ResourceRecord = ReadADDnsSIGRecord @Params; break }
    ([Indented.Dns.RecordType]::KEY) { $ResourceRecord = ReadADDnsKEYRecord @Params; break }
    ([Indented.Dns.RecordType]::AAAA) { $ResourceRecord = ReadADDnsAAAARecord @Params; break }
    ([Indented.Dns.RecordType]::NXT) { $ResourceRecord = ReadADDnsNXTRecord @Params; break }
    ([Indented.Dns.RecordType]::SRV) { $ResourceRecord = ReadADDnsSRVRecord @Params; break }
    ([Indented.Dns.RecordType]::ATMA) { $ResourceRecord = ReadADDnsATMARecord @Params; break }
    ([Indented.Dns.RecordType]::WINS) { $ResourceRecord = ReadADDnsWINSRecord @Params; break }
    ([Indented.Dns.RecordType]::WINSR) { $ResourceRecord = ReadADDnsWINSRRecord @Params; break }
        default { ReadADDnsUnknownRecord @Params }
    }

    return $ResourceRecord
}

function ReadADDnsUnknownRecord {
    # .SYNOPSIS
    #   Reads properties for an unknown record type from a byte array.
    # .DESCRIPTION
    #   Internal use only.
    #
    #                                    1  1  1  1  1  1
    #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #    /                  <anything>                   /
    #    /                                               /
    #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    #
    # .PARAMETER BinaryReader
    #   A binary reader created by using New-BinaryReader (Indented.Common) containing a byte array representing the dnsRecord attribute.
    # .PARAMETER ResourceRecord
    #   An Indented.Dns.AD.ResourceRecord object created by ReadADDnsResourceRecord.
    # .INPUTS
    #   System.IO.BinaryReader
    #   Indented.Dns.AD.ResourceRecord
    #
    #   The BinaryReader object must be created using New-BinaryReader (Indented.Common)
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord.Unknown

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.BinaryReader]$BinaryReader,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.Dns.AD.ResourceRecord' } )]
        $ResourceRecord
    )

    # Create the basic Resource Record
    $ResourceRecord.PsObject.TypeNames.Add("Indented.Dns.AD.ResourceRecord.Unknown")

    # Property: BinaryData
    $ResourceRecord | Add-Member BinaryData -MemberType NoteProperty -Value ($BinaryReader.ReadBytes($ResourceRecord.RecordDataLength))

    return $ResourceRecord
}



function Get-ADDnsRecord {
    # .SYNOPSIS
    #   Get all DNS records from Active Directory.
    # .DESCRIPTION
    #   Get-ADDnsRecord executes a search against a partition holding DNS data to locate dnsNode objects.
    #
    #   Each dnsNode object contains one or more dnsRecord values.
    #
    #   Get-ADDnsRecord can return records which have been deleteed, where DNS tombstoned is set to True. As record type identifiers are stripped from deleted records the record data is returned as a simple byte array (BinaryData).
    # .PARAMETER ChaseLdapReferrals
    #   By default, Get-ADDnsRecord does not follow referrals returned by an LDAP query. RefErr messages may be returned when executing a search. This behaviour may be changed using this parameter. The search will be modified to follow all referrals.
    # .PARAMETER Credential
    #   Specifies a user account that has permittion to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
    # .PARAMETER Name
    #   A name is used to define an LDAP filter for a specific record. The name value supports standard LDAP wildcard characters.
    # .PARAMETER RecordType
    #   RecordType filtering is offered within this CmdLet as a convenience, it offers no operational benefit.
    # .PARAMETER SearchRoot
    #   An LDAP distinguished named defining the starting point for this query.
    # .PARAMETER Server
    #   By default, Get-ADDnsRecord will use serverless binding to locate a suitable directory server. If the query must be targetted, or run against a non-local forest domain, a server must be specified.
    # .PARAMETER Tombstone
    #   Return dnsTombstoned records.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   Indented.Dns.AD.ResourceRecord
    #
    #   ResourceRecord may be considered to be a parent class, a record type specific class is returned.
    # .EXAMPLE
    #   Get-ADDnsRecord
    #
    #   All records under DomainDnsZones partition (the default search root) for the current domain.
    # .EXAMPLE
    #   Get-ADDnsZone domain.example | Get-ADDnsRecord
    #
    #   All records within the zone domain.example. The distinguishedName for the zone will be passed as the search root.
    # .EXAMPLE
    #   Get-ADDnsRecord AComputer
    #
    #   Get a record with a specific named.
    # .EXAMPLE
    #   Get-ADDnsRecord -RecordType A
    #
    #   Filter the records to A only.
    # .EXAMPLE
    #   Get-ADDnsZone domain.example | Get-ADDnsRecord "@" SOA
    #
    #   The SOA record for domain.example. @ represents the zone name and is used as a literal character in AD.
    #
    #   The @ character is rewritten by Get-ADDnsRecord and is replaced with the zone name (parent container name in AD).

    [CmdLetBinding(DefaultParameterSetName = 'ActiveRecords')]
    param(
        [Parameter(Position = 1, ParameterSetName = 'ActiveRecords')]
        [String]$Name = "",

        [Parameter(Position = 2, ParameterSetName = 'ActiveRecords')]
        [Indented.Dns.RecordType[]]$RecordType,

        [Parameter(Mandatory = $true, ParameterSetName = 'TombstonedRecords')]
        [Switch]$Tombstone,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("DN")]
        [String]$SearchRoot = "DC=DomainDnsZones,DC=$($env:UserDnsDomain -replace '\.', ',DC=')",

        [Switch]$ChaseLdapReferrals,

        [String]$Server = "",

        [PSCredential]$Credential
    )

    begin {
        $Params = @{}
        if ($Credential) {
            $Params.Add("Credential", $Credential)
        }
        if ($ChaseLdapReferrals) {
            $Params.Add("ReferralChasingOptions", [DirectoryServices.Protocols.ReferralChasingOptions]::All)
        }
        $Params.Add("Server", "$Server")

        $LdapFilter = "(&(objectCategory=dnsNode)(!dnsTombStoned=TRUE))"
        if ($Name) {
            $LdapFilter = [String]::Format("(&(objectCategory=dnsNode)(name={0}))", $Name)
        }
        if ($Tombstone) {
            $LdapFilter = "(&(objectCategory=dnsNode)(dnsTombStoned=TRUE))"
        }
        $Properties = "name", "distinguishedName", "whenCreated", "objectGuid", "dnsRecord", "dnsTombstoned"
    }

    process {
        Get-LdapObject @Params -SearchRoot $SearchRoot -LdapFilter $LdapFilter -Properties $Properties | ForEach-Object {

            $Count = $_.Attributes['dnsrecord'].Count
            for ($i = 0; $i -lt $Count; $i++) {
                $DnsRecord = $_.Attributes['dnsrecord'].GetValues([Byte[]])[$i]
                $BinaryReader = New-BinaryReader -ByteArray $DnsRecord

                $ResourceRecord = ReadADDnsResourceRecord -BinaryReader $BinaryReader -SearchResultEntry $_

                # Filter the return values by record type (but only if a filter is defined)
                if ($RecordType) {
                    if ($RecordType -contains $ResourceRecord.RecordType) {
                        $ResourceRecord
                    }
                } else {
                    $ResourceRecord
                }
            }
        }
    }
}

function Get-ADDnsZone {
    # .SYNOPSIS
    #   Get all dnsZone objects from an Active Directory partition.
    # .DESCRIPTION
    #   Get-ADDnsZone executes a search against a partition holding DNS information to locate dnsZone objects.
    #
    #   Each dnsZone object contains a dnsProperty attribute. The dnsProperty attribute is a multi-value field describing several properties, each of which is decoded by this CmdLet.
    # .PARAMETER ChaseLdapReferrals
    #   By default, Get-ADDnsZone does not follow referrals returned by an LDAP query. RefErr messages may be returned when executing a search. This behaviour may be changed using this parameter. The search will be modified to follow all referrals.
    # .PARAMETER Credential
    #   Specifies a user account that has permittion to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
    # .PARAMETER Name
    #   A name is used to define an LDAP filter for a specific zone. The name value supports standard LDAP wildcard characters (* and ?).
    # .PARAMETER SearchRoot
    #   An LDAP distinguished named defining the starting point for this query.
    # .PARAMETER Server
    #   By default, Get-ADDnsZone will use serverless binding to locate a suitable directory server. If the query must be targetted, or run against a non-local forest domain, a server must be specified.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   Indented.Dns.AD.Zone
    # .EXAMPLE
    #   Get-ADDnsZone
    #
    #   Get DNS zones from the DomainDnsZones partition in the current domain.
    # .EXAMPLE
    #   Get-ADDnsPartition | Get-ADDnsZone
    #
    #   Get DNS zones from all partitions in the current forest.
    # .EXAMPLE
    #   Get-ADDnsPartition | Get-ADDnsZone indented.co.uk
    #
    #   Get all instances of the indented.co.uk zone from all partitions in the forest.
    # .EXAMPLE
    #   Get-ADDnsZone -Credential (Get-Credential)
    # .EXAMPLE
    #   Get-ADDnsZone -Server "remoteserver.testdomain.com" -Credential (Get-Credential)

    [CmdLetBinding()]
    param(
        [String]$Name = "",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("DN")]
        [String]$SearchRoot = "DC=DomainDnsZones,DC=$($env:UserDnsDomain -replace '\.', ',DC=')",

        [Switch]$ChaseLdapReferrals,

        [String]$Server = "",

        [Parameter(ParameterSetName = "")]
        [PSCredential]$Credential
    )

    begin {
        $Params = @{}
        if ($Credential) {
            $Params.Add("Credential", $Credential)
        }
        if ($ChaseLdapReferrals) {
            $Params.Add("ReferralChasingOptions", [DirectoryServices.Protocols.ReferralChasingOptions]::All)
        }
        $Params.Add("Server", "$Server")

        $LdapFilter = "(&(objectCategory=dnsZone))"
        if ($Name) {
            $LdapFilter = [String]::Format("(&(objectCategory=dnsZone)(name={0}))", $Name)
        }
        $Properties = "name", "distinguishedName", "whenCreated", "objectGuid", "dnsProperty"
    }

    process {
        Get-LdapObject @Params -SearchRoot $SearchRoot -LdapFilter $LdapFilter -Properties $Properties | ForEach-Object {

            $ADDnsZone = New-Object PsObject -Property ([Ordered]@{
                    ZoneName                   = ($_.Attributes['name'].Item(0));
                    DN                         = $_.DistinguishedName;
                    objectGUID                 = ([GUID]$_.Attributes['objectguid'].Item(0));
                    WhenCreated                = ([DateTime]::ParseExact(($_.Attributes['whencreated'].Item(0)), "yyyyMMddHHmmss.0Z", [Globalization.CultureInfo]::CurrentCulture))
                    Aging                      = $false;
                    AgingEnabledDate           = $Null;
                    AllowNSRecordsAutoCreation = [IPAddress[]]@();
                    DataFile                   = "";
                    DeletedFromHostname        = "";
                    DynamicUpdate              = [Indented.Dns.DynamicUpdate]"None";
                    ForwarderUseRecursion      = $false;
                    MasterServers              = [IPAddress[]]@();
                    NoRefreshInterval          = $Null;
                    RefreshInterval            = $Null;
                    ScavengeServers            = [IPAddress[]]@();
                    SecureTime                 = $Null;
                    ZoneType                   = [Indented.Dns.ZoneType]::Primary;
                })
            $ADDnsZone.PsObject.TypeNames.Add("Indented.Dns.AD.Zone")

            # Decode the dnsProperty field
            $Count = $_.Attributes['dnsproperty'].Count
            for ($i = 0; $i -lt $Count; $i++) {
                $DnsProperty = $_.Attributes['dnsproperty'].GetValues([Byte[]])[$i]

                $BinaryReader = New-BinaryReader -ByteArray $DnsProperty

                $DataLength = $BinaryReader.ReadUInt32()
                $NameLength = $BinaryReader.ReadUInt32()
                $Flag = $BinaryReader.ReadUInt32()
                $Version = $BinaryReader.ReadUInt32()
                $ZonePropertyID = [Indented.Dns.ZonePropertyID]($BinaryReader.ReadUInt32())

                switch ($ZonePropertyID) {
            ([Indented.Dns.ZonePropertyID]::AgingEnabledTime) {
                        $AgingEnabledHours = $BinaryReader.ReadUInt32()
                        if ($AgingEnabledHours -gt 0) {
                            # Property: AgingEnabledDate
                            $ADDnsZone.AgingEnabledDate = (Get-Date "01/01/1601").AddHours($AgingEnabledHours)
                        }
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::AgingState) {
                        if ($BinaryReader.ReadUInt32() -eq 1) {
                            # Property: Aging
                            $ADDnsZone.Aging = $true
                        }
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::AllowUpdate) {
                        # Property: DynamicUpdate
                        $ADDnsZone.DynamicUpdate = [Indented.Dns.DynamicUpdate]($BinaryReader.ReadByte())
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::AutoNSServers) {
                        if ($DataLength -ge 4) {
                            $NumberOfServers = $BinaryReader.ReadUInt32()
                            for ($j = 0; $j -lt $NumberOfServers; $j++) {
                                # Property: AllowNSRecordsAutoCreation
                                $ADDnsZone.AllowNSRecordsAutoCreation += $BinaryReader.ReadIPv4Address()
                            }
                        }
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::AutoNSServersDA) {
                        # Ignore this value
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::DCPromoConvert) {
                        # Hide this property
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::DeletedFromHostname) {
                        # Property: DeletedFromHostname
                        $ADDnsZone.DeletedFromHostname = ConvertTo-String ($BinaryReader.ReadBytes($DataLength)) -Unicode
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::MasterServers) {
                        # Ignore this value
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::MasterServersDA) {
                        $MaxCount = $BinaryReader.ReadUInt32()
                        $AddressCount = $BinaryReader.ReadUInt32()

                        # Drop padding / reserved bytes
                        $BinaryReader.ReadBytes(24) | Out-Null

                        for ($j = 0; $j -lt $AddressCount; $j++) {
                            # Each address is in a specific format across a number of fields
                            $AddressFamily = [Net.Sockets.AddressFamily]($BinaryReader.ReadUInt16())
                            # Probably need to reverse the endian order here if it's used.
                            $Port = $BinaryReader.ReadUInt16()

                            # The format includes sequential fields for both IPv4 and IPv6 addressing
                            $IPv4 = $BinaryReader.ReadIPv4Address()
                            $IPv6 = $BinaryReader.ReadIPv6Address()

                            if ($AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
                                # Property: MasterServers
                                $ADDnsZone.MasterServers += $IPv4
                            } elseif ($AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6) {
                                # Property: MasterServers
                                $ADDnsZone.MasterServers += $IPv6
                            }
                            # Read off and discard the trailing data
                            $BinaryReader.ReadBytes(8) | Out-Null
                            # The SALen field (dnscmd returns this, ignoring it here beyond this comment)
                            $BinaryReader.ReadUInt32() | Out-Null
                            # Read off and discard the trailing data
                            $BinaryReader.ReadBytes(28) | Out-Null
                        }
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::NodeDBFlags) {
                        # Ignore this value
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::NoRefreshInterval) {
                        # Property: NoRefreshInterval
                        $ADDnsZone.NoRefreshInterval = New-TimeSpan -Hours $BinaryReader.ReadUInt32()
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::RefreshInterval) {
                        # Property: RefreshInterval
                        $ADDnsZone.RefreshInterval = New-TimeSpan -Hours $BinaryReader.ReadUInt32()
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::ScavengingServers) {
                        if ($DataLength -ge 4) {
                            $NumberOfServers = $BinaryReader.ReadUInt32()
                            for ($j = 0; $j -lt $NumberOfServers; $j++) {
                                # Property: ScavengeServers
                                $ADDnsZone.ScavengeServers += $BinaryReader.ReadIPv4Address()
                            }
                        }
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::ScavengingServersDA) {
                        # Ignore this value
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::SecureTime) {
                        $SecureTimeSeconds = $BinaryReader.ReadUInt64()
                        if ($SecureTimeSeconds -gt 0) {
                            # Property: SecureTime
                            $ADDnsZone.SecureTime = (Get-Date "01/01/1601").AddSeconds($SecuretimeSeconds)
                        }
                        break
                    }
            ([Indented.Dns.ZonePropertyID]::Type) {
                        # Property: ZoneType
                        $ADDnsZone.ZoneType = [Indented.Dns.ZoneType]$BinaryReader.ReadUInt32()
                        break
                    }
                }
            }
            $ADDnsZone
        }
    }
}
