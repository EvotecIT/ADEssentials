function Get-WinDnsServerGlobalQueryBlockList {
    <#
    .SYNOPSIS
    Retrieves the global query block list from DNS servers.

    .DESCRIPTION
    This function retrieves the global query block list from DNS servers specified by the ComputerName parameter.

    .PARAMETER ComputerName
    Specifies the DNS server(s) from which to retrieve the global query block list.

    .PARAMETER Domain
    Specifies the domain to query for DNS servers. Defaults to the current user's DNS domain.

    .PARAMETER Formatted
    Indicates whether the output should be formatted.

    .PARAMETER Splitter
    Specifies the delimiter to use when formatting the output list.

    .EXAMPLE
    Get-WinDnsServerGlobalQueryBlockList -ComputerName "dns-server1", "dns-server2" -Formatted -Splitter ";"
    Retrieves the global query block list from "dns-server1" and "dns-server2" and formats the output with ";" as the delimiter.

    #>
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN,
        [switch] $Formatted,
        [string] $Splitter = ', '
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $ServerGlobalQueryBlockList = Get-DnsServerGlobalQueryBlockList -ComputerName $Computer
        foreach ($_ in $ServerGlobalQueryBlockList) {
            if ($Formatted) {
                [PSCustomObject] @{
                    Enable       = $_.Enable
                    List         = $_.List -join $Splitter
                    GatheredFrom = $Computer
                }
            } else {
                [PSCustomObject] @{
                    Enable       = $_.Enable
                    List         = $_.List
                    GatheredFrom = $Computer
                }
            }
        }
    }
}