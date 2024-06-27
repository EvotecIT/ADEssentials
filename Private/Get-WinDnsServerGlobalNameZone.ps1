function Get-WinDnsServerGlobalNameZone {
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $DnsServerGlobalNameZone = Get-DnsServerGlobalNameZone -ComputerName $Computer
        foreach ($_ in $DnsServerGlobalNameZone) {
            [PSCustomObject] @{
                AlwaysQueryServer   = $_.AlwaysQueryServer
                BlockUpdates        = $_.BlockUpdates
                Enable              = $_.Enable
                EnableEDnsProbes    = $_.EnableEDnsProbes
                GlobalOverLocal     = $_.GlobalOverLocal
                PreferAaaa          = $_.PreferAaaa
                SendTimeout         = $_.SendTimeout
                ServerQueryInterval = $_.ServerQueryInterval
                GatheredFrom        = $Computer
            }
        }
    }
}

#Get-WinDnsServerGlobalNameZone -ComputerName 'AD1'