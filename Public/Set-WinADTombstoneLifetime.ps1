function Set-WinADTombstoneLifetime {
    <#
    .SYNOPSIS
    Sets the tombstone lifetime for a specified Active Directory forest.

    .DESCRIPTION
    This cmdlet sets the tombstone lifetime for a specified Active Directory forest. The tombstone lifetime determines how long a deleted object is retained in the Active Directory database before it is permanently removed.

    .PARAMETER Forest
    The name of the Active Directory forest for which to set the tombstone lifetime.

    .PARAMETER Days
    The number of days to set as the tombstone lifetime. The default is 180 days.

    .PARAMETER ExtendedForestInformation
    Additional information about the forest that can be used to facilitate the operation.

    .EXAMPLE
    Set-WinADTombstoneLifetime -Forest 'example.com' -Days 365
    This example sets the tombstone lifetime for the 'example.com' forest to 365 days.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and configured.
    #>
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [int] $Days = 180,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers['Forest']['HostName'][0]

    $Partition = $((Get-ADRootDSE -Server $QueryServer).configurationNamingContext)
    Set-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$Partition" -Partition $Partition -Replace @{ tombstonelifetime = $Days } -Server $QueryServer
}