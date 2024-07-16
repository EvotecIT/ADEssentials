function Get-WinADDnsServerForwarder {
    <#
    .SYNOPSIS
    Retrieves DNS server forwarder information from Active Directory forest domain controllers.

    .DESCRIPTION
    The Get-WinADDnsServerForwarder function retrieves DNS server forwarder information from Active Directory forest domain controllers. It gathers information such as IP addresses, reordering status, timeout, root hint usage, forwarders count, host name, and domain name.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve DNS server forwarder information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from retrieving DNS server forwarder information.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from retrieving DNS server forwarder information.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include for retrieving DNS server forwarder information.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include for retrieving DNS server forwarder information.

    .PARAMETER Formatted
    Indicates whether the output should be formatted.

    .PARAMETER Splitter
    Specifies the delimiter to use for joining IP addresses.

    .PARAMETER ExtendedForestInformation
    Specifies additional information to include in the forest details.

    .EXAMPLE
    Get-WinADDnsServerForwarder -Forest "example.com" -IncludeDomains "example.com" -Formatted
    Retrieves DNS server forwarder information for the "example.com" forest and includes only the "example.com" domain in a formatted output.

    .NOTES
    File: Get-WinADDnsServerForwarder.ps1
    Author: [Author Name]
    Date: [Date]
    Version: [Version]
    #>
    [CmdLetBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $Formatted,
        [string] $Splitter = ', ',
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Computer in $ForestInformation.ForestDomainControllers) {
        try {
            $DnsServerForwarder = Get-DnsServerForwarder -ComputerName $Computer.HostName -ErrorAction Stop
        } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            Write-Warning "Get-WinDnsServerForwarder - Error $ErrorMessage"
            continue
        }
        foreach ($_ in $DnsServerForwarder) {
            if ($Formatted) {
                [PSCustomObject] @{
                    IPAddress          = $_.IPAddress.IPAddressToString -join $Splitter
                    ReorderedIPAddress = $_.ReorderedIPAddress.IPAddressToString -join $Splitter
                    EnableReordering   = $_.EnableReordering
                    Timeout            = $_.Timeout
                    UseRootHint        = $_.UseRootHint
                    ForwardersCount    = ($_.IPAddress.IPAddressToString).Count
                    GatheredFrom       = $Computer.HostName
                    GatheredDomain     = $Computer.Domain
                }
            } else {
                [PSCustomObject] @{
                    IPAddress          = $_.IPAddress.IPAddressToString
                    ReorderedIPAddress = $_.ReorderedIPAddress.IPAddressToString
                    EnableReordering   = $_.EnableReordering
                    Timeout            = $_.Timeout
                    UseRootHint        = $_.UseRootHint
                    ForwardersCount    = ($_.IPAddress.IPAddressToString).Count
                    GatheredFrom       = $Computer.HostName
                    GatheredDomain     = $Computer.Domain
                }
            }
        }
    }
}