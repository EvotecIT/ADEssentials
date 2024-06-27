function Get-WinDnsServerDsSetting {
    [CmdLetBinding()]
    param(
        [string] $ComputerName
    )

    $DnsServerDsSetting = Get-DnsServerDsSetting -ComputerName $ComputerName
    foreach ($_ in $DnsServerDsSetting) {
        [PSCustomObject] @{
            DirectoryPartitionAutoEnlistInterval = $_.DirectoryPartitionAutoEnlistInterval
            LazyUpdateInterval                   = $_.LazyUpdateInterval
            MinimumBackgroundLoadThreads         = $_.MinimumBackgroundLoadThreads
            RemoteReplicationDelay               = $_.RemoteReplicationDelay
            TombstoneInterval                    = $_.TombstoneInterval
            GatheredFrom                         = $ComputerName
        }
    }
}