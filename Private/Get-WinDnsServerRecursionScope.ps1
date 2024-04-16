function Get-WinDnsServerRecursionScope {
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $DnsServerRecursionScope = Get-DnsServerRecursionScope -ComputerName $Computer
        foreach ($_ in $DnsServerRecursionScope) {
            [PSCustomObject] @{
                Name            = $_.Name
                Forwarder       = $_.Forwarder
                EnableRecursion = $_.EnableRecursion
                GatheredFrom    = $Computer
            }
        }
    }
}
