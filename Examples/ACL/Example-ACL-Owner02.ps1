Import-Module .\ADEssentials.psd1 -Force

# With split per sheet
$Owners = Get-WinADACLForest -Verbose -Separate -Owner
foreach ($Domain in $Owners.Keys) {
    $FilePath = "$PSScriptRoot\OwnersOutputPerSheet_$Domain.xlsx"
    foreach ($Owner in $Owners[$Domain].Keys) {
        $Owners[$Domain][$Owner] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Owner -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
}
$Owners | Format-Table *

# With owners in one sheet
$FilePath = "$PSScriptRoot\OwnersOutput.xlsx"
$OwnersArray = Get-WinADACLForest -Verbose -Owner
$OwnersArray | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'Owners' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
$OwnersArray | Format-Table *