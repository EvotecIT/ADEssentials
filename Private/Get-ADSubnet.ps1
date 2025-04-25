function Get-ADSubnet {
    <#
    .SYNOPSIS
    Retrieve Active Directory subnet details.

    .DESCRIPTION
    Retrieves subnet information from Active Directory. This function processes the provided subnet objects and provides details such as IP address, network length, site information, and more.
    The function handles both IPv4 and IPv6 subnets and includes error handling for CNF (conflict) objects and malformed subnet entries.

    .PARAMETER Subnets
    Specifies an array of subnet objects for which information needs to be retrieved.

    .PARAMETER AsHashTable
    If specified, the subnet information is returned as a hashtable.

    .EXAMPLE
    Get-ADSubnet -Subnets $SubnetArray -AsHashTable
    Retrieves subnet details for the specified subnet array and returns the information as a hashtable.
    #>
    [cmdletBinding()]
    param(
        [Array] $Subnets,
        [switch] $AsHashTable
    )

    foreach ($Subnet in $Subnets) {
        # Skip CNF objects
        if ($Subnet.Name -like "*CNF:*") {
            Write-Warning "Get-ADSubnet - Skipping conflict object: $($Subnet.Name)"
            continue
        }

        if ($Subnet.SiteObject) {
            $SiteObject = ConvertFrom-DistinguishedName -DistinguishedName $Subnet.SiteObject
        } else {
            $SiteObject = ''
        }

        # Split subnet name into IP and mask parts with error handling
        $Addr = $Subnet.Name -split '/'
        if ($Addr.Count -ne 2) {
            Write-Warning "Get-ADSubnet - Invalid subnet format for: $($Subnet.Name). Expected format: IP/mask"
            continue
        }

        $Address = [PSCustomObject] @{
            IP            = $Addr[0]
            NetworkLength = $Addr[1]
        }

        # Validate IP address
        try {
            $IPAddress = [IPAddress]::Parse($Address.IP)
        } catch {
            Write-Warning "Get-ADSubnet - Invalid IP address in subnet: $($Subnet.Name). Error: $($_.Exception.Message)"
            continue
        }

        # Validate network length
        try {
            $MaskBits = [int]$Address.NetworkLength
            if ($IPAddress.AddressFamily -eq 'InterNetwork' -and ($MaskBits -lt 0 -or $MaskBits -gt 32)) {
                Write-Warning "Get-ADSubnet - Invalid network length for IPv4 subnet: $($Subnet.Name). Must be between 0 and 32."
                continue
            }
            if ($IPAddress.AddressFamily -eq 'InterNetworkV6' -and ($MaskBits -lt 0 -or $MaskBits -gt 128)) {
                Write-Warning "Get-ADSubnet - Invalid network length for IPv6 subnet: $($Subnet.Name). Must be between 0 and 128."
                continue
            }
        } catch {
            Write-Warning "Get-ADSubnet - Invalid network length in subnet: $($Subnet.Name). Error: $($_.Exception.Message)"
            continue
        }

        # Process IPv4 subnets
        if ($IPAddress.AddressFamily -eq 'InterNetwork') {
            $AddressRange = $null
            try {
                $AddressRange = Get-IPAddressRangeInformation -CIDRObject $Address
            } catch {
                Write-Warning "Get-ADSubnet - Failed to calculate address range for subnet: $($Subnet.Name). Error: $($_.Exception.Message)"
            }
            # Calculate subnet mask with proper error handling
            $SubnetMask = $null
            try {
                $BinaryMask = ("1" * $MaskBits).PadRight(32, "0")
                $DecimalMask = [system.convert]::ToInt64($BinaryMask, 2)
                $SubnetMask = [IPAddress]"$DecimalMask"
            } catch {
                Write-Warning "Get-ADSubnet - Failed to calculate subnet mask for $($Subnet.Name): $($_.Exception.Message)"
            }

            # Create subnet object with safe defaults for failed calculations
            if ($AsHashTable) {
                [ordered] @{
                    Name        = $Subnet.Name
                    Type        = 'IPv4'
                    SiteName    = $SiteObject
                    SiteStatus  = if ($SiteObject) { $true } else { $false }
                    OverLap     = $null
                    OverLapList = $null
                    Subnet      = $IPAddress
                    MaskBits    = $MaskBits
                    SubnetMask  = $SubnetMask
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
                    Subnet      = $IPAddress
                    MaskBits    = $MaskBits
                    SubnetMask  = $SubnetMask
                    TotalHosts  = $AddressRange.TotalHosts
                    UsableHosts = $AddressRange.UsableHosts
                    HostMin     = $AddressRange.HostMin
                    HostMax     = $AddressRange.HostMax
                    Broadcast   = $AddressRange.Broadcast
                }
            }
        } else {
            # Process IPv6 subnets
            if ($AsHashTable) {
                [ordered] @{
                    Name        = $Subnet.Name
                    Type        = 'IPv6'
                    SiteName    = $SiteObject
                    SiteStatus  = if ($SiteObject) { $true } else { $false }
                    OverLap     = $null
                    OverLapList = $null
                    Subnet      = $IPAddress
                    MaskBits    = $MaskBits
                    SubnetMask  = $null
                    TotalHosts  = $null
                    UsableHosts = $null
                    HostMin     = $null
                    HostMax     = $null
                    Broadcast   = $null
                }
            } else {
                [PSCustomObject] @{
                    Name        = $Subnet.Name
                    Type        = 'IPv6'
                    SiteName    = $SiteObject
                    SiteStatus  = if ($SiteObject) { $true } else { $false }
                    Subnet      = $IPAddress
                    MaskBits    = $MaskBits
                    SubnetMask  = $null
                    TotalHosts  = $null
                    UsableHosts = $null
                    HostMin     = $null
                    HostMax     = $null
                    Broadcast   = $null
                }
            }
        }
    }
}