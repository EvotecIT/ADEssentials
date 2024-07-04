function Get-WinADDnsInformation {
    <#
    .SYNOPSIS
    Retrieves DNS information for specified forest and domains.

    .DESCRIPTION
    This function retrieves DNS information for the specified forest and domains. It gathers various DNS server details such as cache, client subnets, diagnostics, directory partitions, DS settings, EDNS, forwarders, global name zones, global query block lists, recursion settings, recursion scopes, response rate limiting, root hints, scavenging details, server settings, virtualization instance, and more.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve DNS information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from retrieving DNS information.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from retrieving DNS information.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include for retrieving DNS information.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include for retrieving DNS information.

    .PARAMETER Splitter
    Specifies the delimiter to use for joining IP addresses.

    .PARAMETER ExtendedForestInformation
    Provides additional extended forest information to speed up processing.

    .EXAMPLE
    Get-WinADDnsInformation -Forest "example.com" -IncludeDomains "domain1.com", "domain2.com" -Splitter ", " -ExtendedForestInformation $ExtendedForestInformation

    Retrieves DNS information for the "example.com" forest, including "domain1.com" and "domain2.com" domains, using ", " as the splitter for IP addresses, and with extended forest information.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory DNS servers.
    #>
    [CmdLetBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [string] $Splitter,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    if ($null -eq $TypesRequired) {
        #Write-Verbose 'Get-WinADDomainInformation - TypesRequired is null. Getting all.'
        #$TypesRequired = Get-Types -Types ([PSWinDocumentation.ActiveDirectory])
    } # Gets all types

    # This queries AD ones for Forest/Domain/DomainControllers, passing this value to commands can help speed up discovery
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation

    $DNSServers = @{ }
    foreach ($Computer in $ForestInformation.ForestDomainControllers.HostName) {
        #try {
        #    $DNSServer = Get-DNSServer -ComputerName $Computer
        #} catch {
        #
        #}
        $Data = [ordered] @{ }
        $Data.ServerCache = Get-WinDnsServerCache -ComputerName $Computer
        $Data.ServerClientSubnets = Get-DnsServerClientSubnet  -ComputerName $Computer # TODO
        $Data.ServerDiagnostics = Get-WinDnsServerDiagnostics -ComputerName $Computer
        $Data.ServerDirectoryPartition = Get-WinDnsServerDirectoryPartition -ComputerName $Computer -Splitter $Splitter
        $Data.ServerDsSetting = Get-WinDnsServerDsSetting -ComputerName $Computer
        $Data.ServerEdns = Get-WinDnsServerEDns -ComputerName $Computer
        $Data.ServerForwarder = Get-WinADDnsServerForwarder -ComputerName $Computer -ExtendedForestInformation $ForestInformation -Formatted -Splitter $Splitter
        $Data.ServerGlobalNameZone = Get-WinDnsServerGlobalNameZone -ComputerName $Computer
        $Data.ServerGlobalQueryBlockList = Get-WinDnsServerGlobalQueryBlockList -ComputerName $Computer -Splitter $Splitter
        # $Data.ServerPolicies = $DNSServer.ServerPolicies
        $Data.ServerRecursion = Get-WinDnsServerRecursion -ComputerName $Computer

        $Data.ServerRecursionScopes = Get-WinDnsServerRecursionScope -ComputerName $Computer
        $Data.ServerResponseRateLimiting = Get-WinDnsServerResponseRateLimiting -ComputerName $Computer
        $Data.ServerResponseRateLimitingExceptionlists = Get-DnsServerResponseRateLimitingExceptionlist -ComputerName $Computer # TODO
        $Data.ServerRootHint = Get-WinDnsRootHint -ComputerName $Computer
        $Data.ServerScavenging = Get-WinADDnsServerScavenging -ComputerName $Computer
        $Data.ServerSetting = Get-WinDnsServerSettings -ComputerName $Computer
        # $Data.ServerZone = Get-DnsServerZone -ComputerName $Computer # problem
        # $Data.ServerZoneAging = Get-DnsServerZoneAging -ComputerName $Computer # problem
        # $Data.ServerZoneScope = Get-DnsServerZoneScope -ComputerName $Computer # problem
        # $Data.ServerDnsSecZoneSetting = Get-DnsServerDnsSecZoneSetting -ComputerName $Computer # problem
        $Data.VirtualizedServer = $DNSServer.VirtualizedServer
        $Data.VirtualizationInstance = Get-WinDnsServerVirtualizationInstance -ComputerName $Computer
        $DNSServers.$Computer = $Data
    }
    return $DNSServers
}