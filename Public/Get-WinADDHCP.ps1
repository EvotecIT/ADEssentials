function Get-WinADDHCP {
    <#
    .SYNOPSIS
    Retrieves DHCP server information from Active Directory forest with domain controller correlation.

    .DESCRIPTION
    This function retrieves DHCP server information from Active Directory forest domain controllers.
    It collects DHCP server details such as DNS name, IP address, whether it is a domain controller,
    read-only domain controller, global catalog, and the associated IPv4 and IPv6 addresses.
    It also performs connectivity testing and basic server validation for specified servers only.

    .PARAMETER ComputerName
    Specifies an array of DHCP server names to perform detailed testing on. If not specified,
    all discovered DHCP servers will be shown but without connectivity testing.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve DHCP information from. If not specified, uses current forest.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from DHCP information retrieval.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from DHCP information retrieval.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include in DHCP information retrieval.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in DHCP information retrieval.

    .PARAMETER SkipRODC
    Indicates whether to skip Read-Only Domain Controllers (RODC) when retrieving DHCP information.

    .PARAMETER ExtendedForestInformation
    Specifies additional extended forest information to include in the output.

    .PARAMETER TestConnectivity
    When specified, performs connectivity tests to DHCP servers. If ComputerName is specified,
    only tests those servers. If ComputerName is not specified, tests all discovered servers.

    .EXAMPLE
    Get-WinADDHCP

    Retrieves DHCP information from all Active Directory forest domain controllers without connectivity testing.

    .EXAMPLE
    Get-WinADDHCP -ComputerName "dhcp01.example.com", "dhcp02.example.com" -TestConnectivity

    Retrieves all DHCP servers from AD but only performs connectivity testing on specified servers.

    .EXAMPLE
    Get-WinADDHCP -Forest "example.com" -TestConnectivity

    Retrieves DHCP information from the "example.com" forest with connectivity testing on all discovered servers.

    .EXAMPLE
    Get-WinADDHCP -IncludeDomains "domain1.com", "domain2.com" -SkipRODC

    Retrieves DHCP information from specific domains, excluding RODCs.

    .NOTES
    This function requires the Active Directory PowerShell module and DHCP PowerShell module.
    It also requires appropriate permissions to query the Active Directory DHCP servers.
    For performance with large numbers of DHCP servers, use ComputerName to target specific servers for testing.

    .OUTPUTS
    Returns objects with DHCP server information including domain controller correlation and connectivity status.
    #>
    [CmdletBinding()]
    param(
        [string[]] $ComputerName,
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $TestConnectivity
    )

    Write-Verbose "Get-WinADDHCP - Starting DHCP server discovery and analysis"

    # Get forest domain controllers for cross-reference
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation

    # Get DHCP servers from Active Directory
    try {
        $DHCPs = Get-DhcpServerInDC -ErrorAction Stop
        Write-Verbose "Get-WinADDHCP - Found $($DHCPs.Count) DHCP servers in Active Directory"
    } catch {
        Write-Warning -Message "Get-WinADDHCP - Couldn't get DHCP data from AD: $($_.Exception.Message)"
        return
    }

    # Create lookup caches for performance
    $CacheDHCP = @{}
    $CacheAD = [ordered] @{}

    # Create a set of servers to test for performance
    $ServersToTest = @{}
    if ($ComputerName) {
        # If specific servers are provided, only test those
        foreach ($Server in $ComputerName) {
            $ServersToTest[$Server.ToLower()] = $true
        }
        Write-Verbose "Get-WinADDHCP - Will perform detailed testing on $($ComputerName.Count) specified servers"
    } else {
        # If no specific servers provided and TestConnectivity is specified, test all
        if ($TestConnectivity) {
            foreach ($DHCP in $DHCPs) {
                $ServersToTest[$DHCP.DNSName.ToLower()] = $true
            }
            Write-Verbose "Get-WinADDHCP - Will perform detailed testing on all $($DHCPs.Count) discovered servers"
        }
    }

    foreach ($DHCP in $DHCPs) {
        $CacheDHCP[$DHCP.DNSName] = $DHCP
    }

    if ($ForestInformation -and $ForestInformation.ForestDomainControllers) {
        foreach ($DC in $ForestInformation.ForestDomainControllers) {
            $CacheAD[$DC.HostName] = $DC
        }
    }

    # Process each DHCP server
    foreach ($DHCP in $DHCPs) {
        Write-Verbose "Get-WinADDHCP - Processing DHCP server: $($DHCP.DNSName)"

        # Determine if this server should be tested
        $ShouldTest = $ServersToTest[$DHCP.DNSName.ToLower()] -eq $true

        $DHCPObject = [ordered] @{
            DNSName             = $DHCP.DNSName
            IPAddress          = $DHCP.IPAddress
            IsDC               = $false
            IsRODC             = $false
            IsGlobalCatalog    = $false
            DCIPv4             = $null
            DCIPv6             = $null
            DCDomain           = $null
            IsInDNS            = $false
            DNSType            = $null
            DHCPVersion        = $null
            IsReachable        = $false
            ConnectivityStatus = if ($ShouldTest) { 'Unknown' } else { 'Not Tested' }
            ErrorMessage       = $null
            TestedDate         = if ($ShouldTest) { $null } else { 'N/A' }
            GatheredFrom       = $env:COMPUTERNAME
            GatheredDate       = Get-Date
        }

        # Check if DHCP server is also a domain controller
        if ($CacheAD[$DHCP.DNSName]) {
            $DHCPObject['IsDC'] = $true
            $DHCPObject['IsRODC'] = $CacheAD[$DHCP.DNSName].IsReadOnly
            $DHCPObject['IsGlobalCatalog'] = $CacheAD[$DHCP.DNSName].IsGlobalCatalog
            $DHCPObject['DCIPv4'] = $CacheAD[$DHCP.DNSName].IPV4Address
            $DHCPObject['DCIPv6'] = $CacheAD[$DHCP.DNSName].IPV6Address
            $DHCPObject['DCDomain'] = $CacheAD[$DHCP.DNSName].Domain
        }

        # Always perform DNS resolution test as it's lightweight
        try {
            $DNS = Resolve-DnsName -Name $DHCP.DNSName -ErrorAction Stop
            if ($DNS) {
                $DHCPObject['IsInDNS'] = $true
                $DHCPObject['DNSType'] = ($DNS.Type | Select-Object -Unique) -join ', '
            }
        } catch {
            $DHCPObject['IsInDNS'] = $false
            Write-Verbose "Get-WinADDHCP - DNS resolution failed for $($DHCP.DNSName): $($_.Exception.Message)"
        }

        # Test connectivity and get version only for specified servers
        if ($ShouldTest -and $TestConnectivity) {
            try {
                Write-Verbose "Get-WinADDHCP - Testing connectivity to $($DHCP.DNSName)"
                $DHCPServerInfo = Get-DhcpServerVersion -ComputerName $DHCP.DNSName -ErrorAction Stop
                $DHCPObject['IsReachable'] = $true
                $DHCPObject['ConnectivityStatus'] = 'Online'
                $DHCPObject['DHCPVersion'] = "$($DHCPServerInfo.MajorVersion).$($DHCPServerInfo.MinorVersion)"
                $DHCPObject['TestedDate'] = Get-Date
                Write-Verbose "Get-WinADDHCP - Successfully connected to $($DHCP.DNSName), version: $($DHCPObject['DHCPVersion'])"
            } catch {
                $DHCPObject['IsReachable'] = $false
                $DHCPObject['ConnectivityStatus'] = 'Unreachable'
                $DHCPObject['ErrorMessage'] = $_.Exception.Message
                $DHCPObject['TestedDate'] = Get-Date
                Write-Warning "Get-WinADDHCP - Cannot reach DHCP server $($DHCP.DNSName): $($_.Exception.Message)"
            }
        } elseif ($ShouldTest -and -not $TestConnectivity) {
            # Server was specified but TestConnectivity not used
            $DHCPObject['ConnectivityStatus'] = 'Not Tested (Use -TestConnectivity)'
        }

        [PSCustomObject] $DHCPObject
    }

    # Summary information
    $TestedCount = ($ServersToTest.Keys | Measure-Object).Count
    $TotalCount = $DHCPs.Count

    if ($TestConnectivity -and $ComputerName) {
        Write-Verbose "Get-WinADDHCP - DHCP server discovery completed. Found $TotalCount servers, tested $TestedCount specified servers"
    } elseif ($TestConnectivity) {
        Write-Verbose "Get-WinADDHCP - DHCP server discovery completed. Found and tested $TotalCount servers"
    } else {
        Write-Verbose "Get-WinADDHCP - DHCP server discovery completed. Found $TotalCount servers (no connectivity testing performed)"
    }
}