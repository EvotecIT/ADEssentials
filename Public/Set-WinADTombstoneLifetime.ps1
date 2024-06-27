function Set-WinADTombstoneLifetime {
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