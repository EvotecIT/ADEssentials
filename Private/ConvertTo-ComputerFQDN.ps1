function ConvertTo-ComputerFQDN {
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