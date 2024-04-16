

$Forest = Get-ADForest
$dc = 'XB-S-ABB0023.ABB.COM'
#$DC = 'ad0'

foreach ($Partition in $Forest.ApplicationPartitions) {
    $getADObjectSplat = @{
        LDAPFilter  = "(|(cn=*\0ACNF:*)(ou=*CNF:*))"
        Properties  = 'DistinguishedName', 'ObjectClass', 'DisplayName', 'SamAccountName', 'Name', 'ObjectCategory', 'WhenCreated', 'WhenChanged', 'ProtectedFromAccidentalDeletion', 'ObjectGUID'
        Server      = $DC
        SearchScope = 'Subtree'
    }
    Write-Color "Processing $($Partition)" -Color Green -NoNewline
    $Objects = Get-ADObject @getADObjectSplat -SearchBase $Partition
    $Objects | Format-Table
}
