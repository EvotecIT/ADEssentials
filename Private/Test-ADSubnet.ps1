function Test-ADSubnet {
    [cmdletBinding()]
    param(
        [Array] $Subnets
    )
    foreach ($Subnet in $Subnets) {
        # we only check for IPV4, I have no clue for IPV6
        if ($Subnet.Type -ne 'IPV4') {
            continue
        }
        $SmallSubnets = $Subnets | Where-Object { $_.MaskBits -gt $Subnet.MaskBits -and $Subnet.Type -ne 'IPV4'}
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