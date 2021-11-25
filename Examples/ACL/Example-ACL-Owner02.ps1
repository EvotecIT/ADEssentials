Import-Module .\ADEssentials.psd1 -Force

# With split per sheet
$Server = 'ad.evotec.pl'
$SearchBases = @(
    Get-ADObject -Filter * -Properties canonicalName, ntSecurityDescriptor -SearchScope Base -Server $Server
    Get-ADObject -Filter * -Properties canonicalName, ntSecurityDescriptor -SearchScope OneLevel -Server $Server
)
foreach ($Search in $SearchBases) {
    $Owners = Get-WinADACLForest -Verbose -Separate -Owner -SearchBase $Search.DistinguishedName
    foreach ($Domain in $Owners.Keys) {
        $FilePath = "$PSScriptRoot\OwnersOutputPerSheet_$Domain.xlsx"
        foreach ($Owner in $Owners[$Domain].GetEnumerator().Name) {
            $Owners[$Domain][$Owner] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Owner -AutoFilter -AutoFit -FreezeTopRowFirstColumn
        }
    }
}

return

# with split per sheet but searches all
$Owners = Get-WinADACLForest -Verbose -Separate -Owner
foreach ($Domain in $Owners.Keys) {
    $FilePath = "$PSScriptRoot\OwnersOutputPerSheet_$Domain.xlsx"
    foreach ($Owner in $Owners[$Domain].GetEnumerator().Name) {
        $Owners[$Domain][$Owner] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Owner -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
}
$Owners | Format-Table *

# With owners in one sheet
$FilePath = "$PSScriptRoot\OwnersOutput.xlsx"
$OwnersArray = Get-WinADACLForest -Verbose -Owner
$OwnersArray | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'Owners' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
$OwnersArray | Format-Table *


# With split per sheet but just one OU
$Owners = Get-WinADACLForest -Verbose -Separate -Owner -SearchBase "OU=Administration,DC=ad,DC=evotec,DC=xyz"
foreach ($Domain in $Owners.Keys) {
    $FilePath = "$PSScriptRoot\OwnersOutputPerSheet_1_$Domain.xlsx"
    foreach ($Owner in $Owners[$Domain].GetEnumerator().Name) {
        $Owners[$Domain][$Owner] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Owner -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
}
$Owners | Format-Table *

# With owners in one sheet
$FilePath = "$PSScriptRoot\OwnersOutput_2.xlsx"
$OwnersArray = Get-WinADACLForest -Verbose -Owner -SearchBase "OU=Administration,DC=ad,DC=evotec,DC=xyz"
$OwnersArray | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'Owners' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
$OwnersArray | Format-Table *