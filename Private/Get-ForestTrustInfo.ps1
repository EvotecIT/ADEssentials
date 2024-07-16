function Get-ForestTrustInfo {
    <#
    .SYNOPSIS
    Retrieves and processes forest trust information from an array of bytes.

    .DESCRIPTION
    This function retrieves and processes forest trust information from the provided array of bytes.

    .PARAMETER Byte
    An array of bytes containing the forest trust information to be processed.

    .EXAMPLE
    Get-ForestTrustInfo -Byte $ByteData
    Retrieves and processes forest trust information from the specified array of bytes.

    .NOTES
    Author: Chris Dent
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][byte[]]$Byte
    )

    $reader = [System.IO.BinaryReader][System.IO.MemoryStream]$Byte

    $trustInfo = [PSCustomObject]@{
        Version     = $reader.ReadUInt32()
        RecordCount = $reader.ReadUInt32()
        Records     = $null
    }
    $trustInfo.Records = for ($i = 0; $i -lt $trustInfo.RecordCount; $i++) {
        Get-ForestTrustRecord -BinaryReader $reader
    }
    $trustInfo
}