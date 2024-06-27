function Get-WinDnsServerRecursion {
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $DnsServerRecursion = Get-DnsServerRecursion -ComputerName $Computer
        foreach ($_ in $DnsServerRecursion) {
            [PSCustomObject] @{
                AdditionalTimeout = $_.AdditionalTimeout
                Enable            = $_.Enable
                RetryInterval     = $_.RetryInterval
                SecureResponse    = $_.SecureResponse
                Timeout           = $_.Timeout
                GatheredFrom      = $Computer
            }
        }
    }
}
