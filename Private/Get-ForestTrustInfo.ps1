function Get-ForestTrustInfo {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Byte
    An array of bytes which describes the forest trust information.

    .EXAMPLE
    An example

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