function Get-ADSubnet {
    [cmdletBinding()]
    param(
        [Array] $Subnets,
        [switch] $AsHashTable
    )
    foreach ($Subnet in $Subnets) {
        if ($Subnet.SiteObject) {
            $SiteObject = ConvertFrom-DistinguishedName -DistinguishedName $Subnet.SiteObject
        } else {
            $SiteObject = ''
        }
        $AddressRange = Get-IPAddressRange -NetworkAddress $Subnet.Name
        $MaskBits = ([int](($Subnet.Name -split "/")[1]))
        if ($AsHashTable) {
            [ordered] @{
                Name        = $Subnet.Name
                SiteName    = $SiteObject
                SiteStatus  = if ($SiteObject) { $true } else { $false }
                OverLap     = $null
                OverLapList = $null
                Subnet      = ([IPAddress](($Subnet.Name -split "/")[0]))
                MaskBits    = ([int](($Subnet.Name -split "/")[1]))
                SubnetMask  = ([IPAddress]"$([system.convert]::ToInt64(("1"*$MaskBits).PadRight(32,"0"),2))")
                TotalHosts  = $AddressRange.TotalHosts
                UsableHosts = $AddressRange.UsableHosts
                HostMin     = $AddressRange.HostMin
                HostMax     = $AddressRange.HostMax
                Broadcast   = $AddressRange.Broadcast
            }
        } else {
            [PSCustomObject] @{
                Name        = $Subnet.Name
                SiteName    = $SiteObject
                SiteStatus  = if ($SiteObject) { $true } else { $false }
                Subnet      = ([IPAddress](($Subnet.Name -split "/")[0]))
                MaskBits    = ([int](($Subnet.Name -split "/")[1]))
                SubnetMask  = ([IPAddress]"$([system.convert]::ToInt64(("1"*$MaskBits).PadRight(32,"0"),2))")
                TotalHosts  = $AddressRange.TotalHosts
                UsableHosts = $AddressRange.UsableHosts
                HostMin     = $AddressRange.HostMin
                HostMax     = $AddressRange.HostMax
                Broadcast   = $AddressRange.Broadcast
            }
        }
    }
}