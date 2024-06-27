function Set-WinADReplication {
    [CmdletBinding( )]
    param(
        [alias('ForestName')][string] $Forest,
        [int] $ReplicationInterval = 15,
        [switch] $Instant,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers['Forest']['HostName'][0]
    $NamingContext = (Get-ADRootDSE -Server $QueryServer).configurationNamingContext
    Get-ADObject -LDAPFilter "(objectCategory=sitelink)" –Searchbase $NamingContext -Properties options,replInterval -Server $QueryServer | ForEach-Object {
        if ($Instant) {
            Set-ADObject $_ -replace @{ replInterval = $ReplicationInterval } -Server $QueryServer
            Set-ADObject $_ –replace @{ options = $($_.options -bor 1) } -Server $QueryServer
        } else {
            Set-ADObject $_ -replace @{ replInterval = $ReplicationInterval } -Server $QueryServer
        }
    }
}