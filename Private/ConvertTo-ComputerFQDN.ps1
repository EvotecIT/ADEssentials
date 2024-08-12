function ConvertTo-ComputerFQDN {
    <#
    .SYNOPSIS
    Converts a computer name to its fully qualified domain name (FQDN).

    .DESCRIPTION
    This function checks if the provided computer name is an IP address and converts it to a DNS name to ensure SSL functionality.

    .PARAMETER Computer
    The computer name or IP address to convert to FQDN.

    .EXAMPLE
    ConvertTo-ComputerFQDN -Computer "192.168.1.1"
    Converts the IP address to its corresponding DNS name.

    .NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
    [cmdletBinding()]
    param(
        [string] $Computer
    )
    # Checks for ServerName - Makes sure to convert IPAddress to DNS, otherwise SSL won't work
    $IPAddressCheck = [System.Net.IPAddress]::TryParse($Computer, [ref][ipaddress]::Any)
    $IPAddressMatch = $Computer -match '^(\d+\.){3}\d+$'
    if ($IPAddressCheck -and $IPAddressMatch) {
        [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue -Type PTR -Verbose:$false)
        if ($ADServerFQDN.Count -gt 0) {
            $ServerName = $ADServerFQDN[0].NameHost
        } else {
            $ServerName = $Computer
        }
    } else {
        [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue -Type A -Verbose:$false)
        if ($ADServerFQDN.Count -gt 0) {
            $ServerName = $ADServerFQDN[0].Name
        } else {
            $ServerName = $Computer
        }
    }
    $ServerName
}