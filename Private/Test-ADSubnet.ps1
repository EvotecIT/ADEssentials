function Test-ADSubnet {
    <#
    .SYNOPSIS
    Tests for overlapping subnets within the provided array of subnets.

    .DESCRIPTION
    This function checks for overlapping subnets within the array of subnets provided. It specifically focuses on IPv4 subnets.

    .PARAMETER Subnets
    Specifies an array of subnets to check for overlapping subnets.

    .EXAMPLE
    Test-ADSubnet -Subnets @($Subnet1, $Subnet2, $Subnet3)
    Checks for overlapping subnets within the array of subnets provided.

    .NOTES
    This function only checks for overlapping IPv4 subnets.
    #>
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