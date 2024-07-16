function Get-WinDnsServerDirectoryPartition {
    <#
    .SYNOPSIS
    Retrieves directory partition information for a specified DNS server.

    .DESCRIPTION
    This function retrieves directory partition information for the specified DNS server. It provides details about different directory partitions, including their names, distinguished names, flags, replicas, state, and zone count.

    .PARAMETER ComputerName
    Specifies the name of the DNS server for which directory partition information is to be retrieved.

    .PARAMETER Splitter
    Specifies a character to use for splitting replica information if needed.

    .NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
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