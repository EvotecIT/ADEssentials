function Set-WinADReplication {
    <#
    .SYNOPSIS
    Sets the replication interval for site links in an Active Directory forest.

    .DESCRIPTION
    This cmdlet sets the replication interval for site links within a specified Active Directory forest. It can also enable instant replication for site links if desired. The cmdlet supports setting a custom replication interval and provides an option to force instant replication.

    .PARAMETER Forest
    The name of the Active Directory forest for which to set the replication interval.

    .PARAMETER ReplicationInterval
    The interval in minutes to set for replication. The default is 15 minutes.

    .PARAMETER Instant
    Switch parameter to enable instant replication for site links.

    .PARAMETER ExtendedForestInformation
    Additional information about the forest that can be used to facilitate the operation.

    .EXAMPLE
    Set-WinADReplication -Forest 'example.com' -ReplicationInterval 30
    This example sets the replication interval for site links in the 'example.com' forest to 30 minutes.

    .EXAMPLE
    Set-WinADReplication -Forest 'example.com' -Instant
    This example enables instant replication for site links in the 'example.com' forest.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and configured.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [int] $ReplicationInterval = 15,
        [switch] $Instant,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers['Forest']['HostName'][0]
    $NamingContext = (Get-ADRootDSE -Server $QueryServer).configurationNamingContext
    Get-ADObject -LDAPFilter "(objectCategory=sitelink)" -Searchbase $NamingContext -Properties options,replInterval -Server $QueryServer | ForEach-Object {
        if ($Instant) {
            Set-ADObject $_ -replace @{ replInterval = $ReplicationInterval } -Server $QueryServer
            Set-ADObject $_ -replace @{ options = $($_.options -bor 1) } -Server $QueryServer
        } else {
            Set-ADObject $_ -replace @{ replInterval = $ReplicationInterval } -Server $QueryServer
        }
    }
}