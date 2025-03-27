function Get-WinADDHCP {
    <#
    .SYNOPSIS
    Retrieves DHCP information from Active Directory forest domain controllers.

    .DESCRIPTION
    This function retrieves DHCP information from Active Directory forest domain controllers. It collects DHCP server details such as DNS name, IP address, whether it is a domain controller, read-only domain controller, global catalog, and the associated IPv4 and IPv6 addresses.

    .PARAMETER None
    No parameters are required for this function.

    .EXAMPLE
    Get-WinADDHCP
    Retrieves DHCP information from all Active Directory forest domain controllers.

    .NOTES
    This function requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory DHCP servers.
    #>
    [cmdletBinding()]
    param(

    )
    $ForestDomainControllers = Get-WinADForestControllers
    try {
        $DHCPs = Get-DhcpServerInDC -Verbose
    } catch {
        $DnsNames = Get-ADObject -SearchBase ( Get-ADRootDSE ).ConfigurationNamingContext -Filter "ObjectClass -eq 'DhcpClass' -AND Name -ne 'DhcpRoot'" |
            Select-Object -ExpandProperty Name
        $DHCPs = ForEach ( $DnsName in $DnsNames ) {
            $Identity = $DnsName -replace ( Get-ADDomain ).DNSRoot -replace '\.'
            $IPAddress = Get-AdComputer -Identity $Identity -Property IPv4Address | Select-Object -ExpandProperty IPv4Address
            [PSCustomObject]@{
                IPAddress = $IPAddress
                DnsName   = $DnsName
            }
        }
        if ( -not $DHCPs ) {
            Write-Warning -Message "Get-WinAdDhcp - Couldn't get DHCP data from AD: $($_.Exception.Message)"
            return
        }
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
