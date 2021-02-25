function Test-ADSubnet {
    [cmdletBinding()]
    param(
        [Array] $Subnets
    )
    foreach ($Subnet in $Subnets) {
        $SmallSubnets = $Subnets | Where-Object { $_.MaskBits -gt $Subnet.MaskBits }
        foreach ($SmallSubnet in $SmallSubnets ) {
            if (($SmallSubnet.Subnet.Address -band $Subnet.SubnetMask.Address) -eq $Subnet.Subnet.Address) {
                [PSCustomObject]@{
                    Name                   = $Subnet.Name
                    SiteName               = $Subnet.SiteName
                    SiteStatus             = $Subnet.SiteStatus
                    SubnetRange            = $Subnet.Subnet
                    OverlappingSubnet      = $SmallSubnet.Name
                    OverlappingSubnetRange = $SmallSubnet.Subnet
                    SiteCollission         = $Subnet.Name -ne $SmallSubnet.Name
                }
            }
        }
    }
}