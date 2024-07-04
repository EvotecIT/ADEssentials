function Get-WinDnsServerEDns {
    <#
    .SYNOPSIS
    Retrieves DNS server EDNS settings for a specified computer.

    .DESCRIPTION
    This function retrieves DNS server EDNS settings for the specified computer. It provides details about various settings related to EDNS, including Cache Timeout, Enable Probes, Enable Reception, and the computer from which the settings were gathered.

    .PARAMETER ComputerName
    Specifies the name of the computer for which DNS server EDNS settings are to be retrieved.

    .EXAMPLE
    Get-WinDnsServerEDns -ComputerName "Server01"
    Retrieves DNS server EDNS settings from Server01.

    .EXAMPLE
    Get-WinDnsServerEDns -ComputerName "Server02"
    Retrieves DNS server EDNS settings from Server02.
    #>
    [CmdLetBinding()]
    param(
        [string] $ComputerName
    )
    $DnsServerDsSetting = Get-DnsServerEDns -ComputerName $ComputerName
    foreach ($_ in $DnsServerDsSetting) {
        [PSCustomObject] @{
            CacheTimeout    = $_.CacheTimeout
            EnableProbes    = $_.EnableProbes
            EnableReception = $_.EnableReception
            GatheredFrom    = $ComputerName
        }
    }
}