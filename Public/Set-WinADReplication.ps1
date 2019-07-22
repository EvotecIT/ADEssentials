function Set-WinADReplication {
    [CmdletBinding( )]
    param(
        [int] $ReplicationInterval = 15,
        [switch] $Instant
    )
    $NamingContext = (Get-ADRootDSE).configurationNamingContext
    Get-ADObject -LDAPFilter "(objectCategory=sitelink)" –Searchbase $NamingContext -Properties options | ForEach-Object {
        if ($Instant) {
            Set-ADObject $_ -replace @{ replInterval = $ReplicationInterval }
            Set-ADObject $_ –replace @{ options = $($_.options -bor 1) }
        } else {
            Set-ADObject $_ -replace @{ replInterval = $ReplicationInterval }
        }
    }
}