function Remove-WinADDuplicateObject {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        # This may not work for all types of objects. Please make sure to understand what it does first.
        $CNF = Get-ADObject -LDAPFilter "(|(cn=*\0ACNF:*)(ou=*OACNF:*))" -SearchScope Subtree -Server $QueryServer
        foreach ($_ in $CNF) {
            try {
                Remove-ADObject -Identity $_ -Recursive
            } catch {
                Write-Warning "Remove-WinADDuplicateObjects - Failed for $($_.DistinguishedName) with error: $($_.Exception.Message)"
            }
        }
    }
}