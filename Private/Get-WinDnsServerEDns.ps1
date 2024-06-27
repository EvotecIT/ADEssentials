function Get-WinDnsServerEDns {
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