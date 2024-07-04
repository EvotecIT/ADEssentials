function Get-WinDnsServerDsSetting {
    <#
    .SYNOPSIS
    Retrieves DNS server Directory Services settings for a specified computer.

    .DESCRIPTION
    This function retrieves DNS server Directory Services settings for the specified computer. It provides details about various settings related to Directory Services, including Directory Partition Auto Enlist Interval, Lazy Update Interval, Minimum Background Load Threads, Remote Replication Delay, Tombstone Interval, and the computer from which the settings were gathered.

    .PARAMETER ComputerName
    Specifies the name of the computer for which DNS server Directory Services settings are to be retrieved.

    .EXAMPLE
    Get-WinDnsServerDsSettings -ComputerName "Server01"
    Retrieves DNS server Directory Services settings from Server01.

    .EXAMPLE
    Get-WinDnsServerDsSettings -ComputerName "Server02"
    Retrieves DNS server Directory Services settings from Server02.
    #>
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