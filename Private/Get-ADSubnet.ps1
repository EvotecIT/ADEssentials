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
        $Addr = $Subnet.Name.Split('/')
        $Address = [PSCustomObject] @{
            IP            = $Addr[0]
            NetworkLength = $Addr[1]
        }
        try {
            $IPAddress = ([IPAddress] $Address.IP)
        } catch {
            Write-Warning "Get-ADSubnet - Conversion to IP failed. Error: $($_.Exception.Message)"
        }
        if ($IPAddress.AddressFamily -eq 'InterNetwork') {
            # IPv4
            $AddressRange = Get-IPAddressRangeInformation -CIDRObject $Address
            $MaskBits = ([int](($Subnet.Name -split "/")[1]))
            if ($AsHashTable) {
                [ordered] @{
                    Name        = $Subnet.Name
                    Type        = 'IPv4'
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
                    Type        = 'IPv4'
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
        } else {
            # IPv6
            $AddressRange = $null
            if ($AsHashTable) {
                [ordered] @{
                    Name        = $Subnet.Name
                    Type        = 'IPv6'
                    SiteName    = $SiteObject
                    SiteStatus  = if ($SiteObject) { $true } else { $false }
                    OverLap     = $null
                    OverLapList = $null
                    Subnet      = ([IPAddress](($Subnet.Name -split "/")[0]))
                    MaskBits    = ([int](($Subnet.Name -split "/")[1]))
                    SubnetMask  = $null # Ipv6 doesn't have a subnet mask
                    TotalHosts  = $AddressRange.TotalHosts
                    UsableHosts = $AddressRange.UsableHosts
                    HostMin     = $AddressRange.HostMin
                    HostMax     = $AddressRange.HostMax
                    Broadcast   = $AddressRange.Broadcast
                }
            } else {
                [PSCustomObject] @{
                    Name        = $Subnet.Name
                    Type        = 'IPv6'
                    SiteName    = $SiteObject
                    SiteStatus  = if ($SiteObject) { $true } else { $false }
                    Subnet      = ([IPAddress](($Subnet.Name -split "/")[0]))
                    MaskBits    = ([int](($Subnet.Name -split "/")[1]))

                    SubnetMask  = $null # Ipv6 doesn't have a subnet mask
                    TotalHosts  = $AddressRange.TotalHosts
                    UsableHosts = $AddressRange.UsableHosts
                    HostMin     = $AddressRange.HostMin
                    HostMax     = $AddressRange.HostMax
                    Broadcast   = $AddressRange.Broadcast
                }
            }
        }
    }
}