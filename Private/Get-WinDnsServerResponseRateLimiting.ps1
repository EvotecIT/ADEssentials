function Get-WinDnsServerResponseRateLimiting {
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $DnsServerResponseRateLimiting = Get-DnsServerResponseRateLimiting -ComputerName $Computer
        foreach ($_ in $DnsServerResponseRateLimiting) {
            [PSCustomObject] @{
                ResponsesPerSec           = $_.ResponsesPerSec
                ErrorsPerSec              = $_.ErrorsPerSec
                WindowInSec               = $_.WindowInSec
                IPv4PrefixLength          = $_.IPv4PrefixLength
                IPv6PrefixLength          = $_.IPv6PrefixLength
                LeakRate                  = $_.LeakRate
                TruncateRate              = $_.TruncateRate
                MaximumResponsesPerWindow = $_.MaximumResponsesPerWindow
                Mode                      = $_.Mode
                GatheredFrom              = $Computer
            }
        }
    }
}