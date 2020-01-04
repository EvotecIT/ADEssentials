function Get-WinADTombstoneLifetime {
    [cmdletBinding()]
    param(

    )
    $Partition = $((Get-ADRootDSE).configurationNamingContext)
    (Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$Partition" -Properties tombstoneLifetime).tombstoneLifetime
}