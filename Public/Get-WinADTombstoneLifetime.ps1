function Get-WinADTombstoneLifetime {
    <#
    .SYNOPSIS
    Retrieves the tombstone lifetime for a specified Active Directory forest.

    .DESCRIPTION
    This function retrieves the tombstone lifetime for a specified Active Directory forest. If the tombstone lifetime is not explicitly set, it defaults to 60 days. The recommended value is 720 days, and the minimum value is 180 days.

    .PARAMETER Forest
    Specifies the name of the Active Directory forest to retrieve the tombstone lifetime for. If not specified, the current forest is used.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest to aid in the retrieval process.

    .EXAMPLE
    Get-WinADTombstoneLifetime -Forest "example.com"
    This example retrieves the tombstone lifetime for the "example.com" forest.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires access to the target forest.
    #>
    [Alias('Get-WinADForestTombstoneLifetime')]
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    # Check tombstone lifetime (if blank value is 60)
    # Recommended value 720
    # Minimum value 180
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $RootDSE = Get-ADRootDSE -Server $QueryServer
    $Output = (Get-ADObject -Server $QueryServer -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$(($RootDSE).configurationNamingContext)" -Properties tombstoneLifetime)
    if ($null -eq $Output -or $null -eq $Output.tombstoneLifetime) {
        [PSCustomObject] @{
            TombstoneLifeTime = 60
        }
    } else {
        [PSCustomObject] @{
            TombstoneLifeTime = $Output.tombstoneLifetime
        }
    }
}
