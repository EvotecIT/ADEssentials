function Get-ForestTrustRecord {
    <#
    .SYNOPSIS
    Retrieves and processes forest trust record information.

    .DESCRIPTION
    This function retrieves and processes forest trust record information from the provided BinaryReader.

    .PARAMETER BinaryReader
    Specifies the BinaryReader object containing the forest trust record information.

    .EXAMPLE
    Get-ForestTrustRecord -BinaryReader $BinaryReader
    Retrieves and processes forest trust record information from the BinaryReader object.

    .NOTES
    Author: Chris Dent
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.IO.BinaryReader]$BinaryReader
    )
    [Flags()]
    enum TrustFlags {
        LsaTlnDisabledNew = 0x1
        LsaTlnDisabledAdmin = 0x2
        LsaTlnDisabledConflict = 0x4
    }

    [Flags()]
    enum ForestTrustFlags {
        LsaSidDisabledAdmin = 0x1
        LsaSidDisabledConflict = 0x2
        LsaNBDisabledAdmin = 0x4
        LsaNBDisabledConflict = 0x8
    }

    enum RecordType {
        ForestTrustTopLevelName
        ForestTrustTopLevelNameEx
        ForestTrustDomainInfo
    }


    $record = [PSCustomObject]@{
        RecordLength    = $BinaryReader.ReadUInt32()
        Flags           = $BinaryReader.ReadUInt32()
        Timestamp       = $BinaryReader.ReadUInt32(), $BinaryReader.ReadUInt32()
        RecordType      = $BinaryReader.ReadByte() -as [RecordType]
        ForestTrustData = $null
    }

    $record.Timestamp = [DateTime]::FromFileTimeUtc(
        ($record.Timestamp[0] -as [UInt64] -shl 32) + $record.Timestamp[1]
    )

    $record.Flags = switch ($record.RecordType) {
        ([RecordType]::ForestTrustDomainInfo) { $record.Flags -as [ForestTrustFlags] }
        default { $record.Flags -as [TrustFlags] }
    }

    if ($record.RecordLength -gt 11) {
        switch ($record.RecordType) {
            ([RecordType]::ForestTrustDomainInfo) {
                $record.ForestTrustData = [PSCustomObject]@{
                    Sid         = $null
                    DnsName     = $null
                    NetbiosName = $null
                }

                $sidLength = $BinaryReader.ReadUInt32()
                if ($sidLength -gt 0) {
                    $record.ForestTrustData.Sid = [System.Security.Principal.SecurityIdentifier]::new(
                        $BinaryReader.ReadBytes($sidLength),
                        0
                    )
                }
                $dnsNameLen = $BinaryReader.ReadUInt32()
                if ($dnsNameLen -gt 0) {
                    $record.ForestTrustData.DnsName = [string]::new($BinaryReader.ReadBytes($dnsNameLen) -as [char[]])
                }
                $NetbiosNameLen = $BinaryReader.ReadUInt32()
                if ($NetbiosNameLen -gt 0) {
                    $record.ForestTrustData.NetbiosName = [string]::new($BinaryReader.ReadBytes($NetbiosNameLen) -as [char[]])
                }
            }
            default {
                $nameLength = $BinaryReader.ReadUInt32()
                if ($nameLength -gt 0) {
                    $record.ForestTrustData = [String]::new($BinaryReader.ReadBytes($nameLength) -as [char[]])
                }
            }
        }
    }

    $record
}