function Get-WinDnsServerDirectoryPartition {
    [CmdLetBinding()]
    param(
        [string] $ComputerName,
        [string] $Splitter
    )
    $DnsServerDirectoryPartition = Get-DnsServerDirectoryPartition -ComputerName $ComputerName
    foreach ($_ in $DnsServerDirectoryPartition) {
        [PSCustomObject] @{
            DirectoryPartitionName              = $_.DirectoryPartitionName
            CrossReferenceDistinguishedName     = $_.CrossReferenceDistinguishedName
            DirectoryPartitionDistinguishedName = $_.DirectoryPartitionDistinguishedName
            Flags                               = $_.Flags
            Replica                             = if ($Splitter -ne '') { $_.Replica -join $Splitter } else { $_.Replica }
            State                               = $_.State
            ZoneCount                           = $_.ZoneCount
            GatheredFrom                        = $ComputerName
        }
    }
}