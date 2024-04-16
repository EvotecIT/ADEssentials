
function New-BinaryReader {
    # .SYNOPSIS
    #   Create a new extended instance of a System.IO.BinaryReader class from a Byte Array.
    # .DESCRIPTION
    #   System.IO.BinaryReader reads all multi-byte values as little endian, to address this the following methods have been added to the object:
    #
    #    * ReadBEUInt16
    #    * ReadBEInt32
    #    * ReadBEUInt32
    #    * ReadBEUInt64
    #
    #   In addition to handling big endian values, the following utility methods have been implemented:
    #
    #    * PeakByte
    #    * ReadIPv4Address
    #    * ReadIPv6Address
    #    * SetPositionMarker
    #
    #   SetPositionMarker populates the PositionMarker property which is associated with the BytesFromMarker property.
    # .PARAMETER ByteArray
    #   The byte array passed to this function is used to create a MemoryStream which is passed to the BinaryReader class.
    # .INPUTS
    #   System.Byte[]
    # .OUTPUTS
    #   System.IO.BinaryReader
    #
    #   The class has been extended as described above.
    # .EXAMPLE
    #   C:\PS>$ByteArray = [Byte[]](1, 2, 3, 4)
    #   C:\PS>$Reader = New-BinaryReader $ByteArray
    #   C:\PS>$Reader.PeakByte()
    #   C:\PS>$Reader.ReadIPv4Address()
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     16/08/2013 - Chris Dent - Created.

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Byte[]]$ByteArray
    )

    $MemoryStream = New-Object IO.MemoryStream(, $ByteArray)
    $BinaryReader = New-Object IO.BinaryReader($MemoryStream)

    # Property: PositionMarker
    $BinaryReader | Add-Member PositionMarker -MemberType NoteProperty -Value 0
    # Property: BytesFromPositionMarker
    $BinaryReader | Add-Member BytesFromMarker -MemberType ScriptProperty -Value {
        $this.BaseStream.Position - $this.PositionMarker
    }

    # Method: SetPositionMarket - Set a position marker to allow simple progress tracking
    $BinaryReader | Add-Member SetPositionMarker -MemberType ScriptMethod -Value {
        $this.PositionMarker = $this.BaseStream.Position
    }
    # Method: PeekByte - Allows viewing the next byte, resetting the stream position afterwards
    $BinaryReader | Add-Member PeekByte -MemberType ScriptMethod -Value {
        if ($this.BaseStream.Capacity -ge ($this.BaseStream.Position + 1)) {
            [Byte]$Value = $this.PsBase.ReadByte()
            $this.BaseStream.Seek(-1, [IO.SeekOrigin]::Current) | Out-Null
            $Value
        }
    }
    # Method: ReadBEUInt16 - Read big endian UInt16 values
    $BinaryReader | Add-Member ReadBEUInt16 -MemberType ScriptMethod -Value {
        $Bytes = $this.ReadBytes(2)
        [Array]::Reverse($Bytes)
        [BitConverter]::ToUInt16($Bytes, 0)
    }
    # Method: ReadBEInt32 - Read big endian Int32 values
    $BinaryReader | Add-Member ReadBEInt32 -MemberType ScriptMethod -Value {
        $Bytes = $this.ReadBytes(4)
        [Array]::Reverse($Bytes)
        [BitConverter]::ToInt32($Bytes, 0)
    }
    # Method: ReadBEInt32 - Read big endian UInt32 values
    $BinaryReader | Add-Member ReadBEUInt32 -MemberType ScriptMethod -Value {
        $Bytes = $this.ReadBytes(4)
        [Array]::Reverse($Bytes)
        [BitConverter]::ToUInt32($Bytes, 0)
    }
    # Method: ReadBEInt48 - Read big endian UInt48 values (returns as UInt64)
    $BinaryReader | Add-Member ReadBEUInt48 -MemberType ScriptMethod -Value {
        $Bytes = $this.ReadBytes(6)
        $Length = $Bytes.Length
        [UInt64]$Value = 0
        for ($i = 0; $i -lt $Length; $i++) {
            $Value = $Value -bor ([UInt64]$Bytes[$i] -shl (8 * ($Length - $i - 1)))
        }
        $Value
    }
    # Method: ReadBEInt64 - Read big endian UInt64 values
    $BinaryReader | Add-Member ReadBEUInt64 -MemberType ScriptMethod -Value {
        $Bytes = $this.ReadBytes(8)
        [Array]::Reverse($Bytes)
        [BitConverter]::ToUInt64($Bytes, 0)
    }
    # Method: ReadIPv4Address - Read 4 bytes as an IPv4 address
    $BinaryReader | Add-Member ReadIPv4Address -MemberType ScriptMethod -Value {
        [IPAddress]([String]::Format("{0}.{1}.{2}.{3}",
                $this.ReadByte(),
                $this.ReadByte(),
                $this.ReadByte(),
                $this.ReadByte())
        )
    }
    # Method: ReadIPv6Address - Read 16 bytes as an IPv6 address
    $BinaryReader | Add-Member ReadIPv6Address -MemberType ScriptMethod -Value {
        [IPAddress]([String]::Format("{0:X}:{1:X}:{2:X}:{3:X}:{4:X}:{5:X}:{6:X}:{7:X}",
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16(),
                $this.ReadBEUInt16())
        )
    }

    return $BinaryReader
}
