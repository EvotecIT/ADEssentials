function Get-WinADDHCP {
    [cmdletBinding()]
    param(

    )
    $ForestDomainControllers = Get-WinADForestControllers
    try {
        $DHCPs = Get-DhcpServerInDC -Verbose
    } catch {
        Write-Warning -Message "Get-WinADDHCP - Couldn't get DHCP data from AD: $($_.Exception.Message)"
        return
    }
    $CacheDHCP = @{}
    $CacheAD = [ordered] @{}
    foreach ($DHCP in $DHCPs) {
        $CacheDHCP[$DHCP.DNSName] = $DHCP
    }
    foreach ($DC in $ForestDomainControllers) {
        $CacheAD[$DC.HostName] = $DC
    }

    foreach ($DHCP in $DHCPs) {
        $DHCPObject = [ordered] @{
            DNSName   = $DHCP.DNSName
            IPAddress = $DHCP.IPAddress
        }
        if ($CacheAD[$DHCP.DNSName]) {
            $DHCPObject['IsDC'] = $true
            $DHCPObject['IsRODC'] = $CacheAD[$DHCP.DNSName].IsReadOnly
            $DHCPObject['IsGlobalCatalog'] = $CacheAD[$DHCP.DNSName].IsGlobalCatalog
            $DHCPObject['DCIPv4'] = $CacheAD[$DHCP.DNSName].IPV4Address
            $DHCPObject['DCIPv6'] = $CacheAD[$DHCP.DNSName].IPV6Address
        } else {
            $DHCPObject['IsDC'] = $false
            $DHCPObject['IsRODC'] = $false
            $DHCPObject['IsGlobalCatalog'] = $false
            $DHCPObject['DCIPv4'] = $null
            $DHCPObject['DCIPv6'] = $null
        }
        $DNS = Resolve-DnsName -Name $DHCP.DNSName -ErrorAction SilentlyContinue
        if ($DNS) {
            $DHCPObject['IsInDNS'] = $true
            $DHCPObject['DNSType'] = $DNS.Type
        } else {
            $DHCPObject['IsInDNS'] = $false
            $DHCPObject['DNSType'] = $null
        }
        [PSCustomObject] $DHCPObject
    }
}