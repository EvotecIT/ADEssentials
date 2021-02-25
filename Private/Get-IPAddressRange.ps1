function Get-IPAddressRange {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER NetworkAddress
    CIDR notation network address, or using subnet mask. Examples: '192.168.0.1/24', '10.20.30.40/255.255.0.0'.

    .EXAMPLE
    Get-IPAddressRange -NetworkAddress '192.168.0.1/24', '10.20.30.40/255.255.0.0'

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]] $NetworkAddress
    )
    foreach ($Network in $NetworkAddress) {
        $Addr = $Network.Split('/')
        $Address = [PSCustomObject] @{
            IP            = $Addr[0]
            NetworkLength = $Addr[1]
        }
        Get-IPAddressRangeInformation -CIDRObject $Address
    }
}