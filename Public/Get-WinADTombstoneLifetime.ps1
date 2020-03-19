function Get-WinADTomebstoneLifetime {
    [Alias('Get-WinADForestTomebstoneLifetime')]
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
    if ($null -eq $Output) {
        [PSCustomObject] @{
            TombstoneLifeTime = 60
        }
    } else {
        [PSCustomObject] @{
            TombstoneLifeTime = $Output.tombstoneLifetime
        }
    }
}