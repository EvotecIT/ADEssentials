Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

# With split per sheet
$Permissions = Get-WinADACLForest -Verbose -Separate
foreach ($Domain in $Permissions.Keys) {
    $FilePath = "$Env:USERPROFILE\Desktop\PermissionsOutputPerSheet_$Domain.xlsx"
    foreach ($Perm in $Permissions[$Domain].Keys) {
        $Permissions[$Domain][$Perm] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Perm -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
}
$Permissions | Format-Table *

# With permissions in one sheet
$FilePath = "$Env:USERPROFILE\Desktop\PermissionsOutput.xlsx"
$PermissionsArray = Get-WinADACLForest -Verbose
$PermissionsArray | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'Permissions' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
$PermissionsArray | Format-Table *