Import-Module .\ADEssentials.psd1 -Force

# With split per sheet
$Permissions = Get-WinADACLForest -Verbose -Separate
foreach ($Domain in $Permissions.Keys) {
    $FilePath = "$PSSCriptRoot\PermissionsOutputPerSheet_$Domain.xlsx"
    foreach ($Perm in $Permissions[$Domain].GetEnumerator().Name) {
        $Permissions[$Domain][$Perm] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Perm -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
}
$Permissions | Format-Table *

# With permissions in one sheet
$FilePath = "$PSSCriptRoot\PermissionsOutput.xlsx"
$PermissionsArray = Get-WinADACLForest -Verbose
$PermissionsArray | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'Permissions' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
$PermissionsArray | Format-Table *