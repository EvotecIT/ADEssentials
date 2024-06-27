Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

# Step 1 - Asses the current permissions on share
$Forest = Get-ADForest
foreach ($Domain in $Forest.Domains) {
    $Report = Get-WinADSharePermission -Path "\\$Domain\SYSVOL\$Domain\scripts\"
    $Report | ConvertTo-Excel -FilePath $Env:UserProfile\Desktop\NetlogonOutputBefore.xlsx -ExcelWorkSheetName $Domain -AutoFilter -AutoFit
}

# Step 2

$Forest = Get-ADForest
foreach ($Domain in $Forest.Domains) {
    $Path = "\\$Domain\SYSVOL\$Domain\scripts"#
    Remove-WinADSharePermission -Type Unknown -Path $Path -Verbose -LimitProcessing 100 -WhatIf
}


# Step 3 - Asses the after permissions on share
$Forest = Get-ADForest
foreach ($Domain in $Forest.Domains) {
    $Report = Get-WinADSharePermission -Path "\\$Domain\SYSVOL\$Domain\scripts\"
    $Report | ConvertTo-Excel -FilePath $Env:UserProfile\Desktop\NetlogonOutputAfter.xlsx -ExcelWorkSheetName $Domain -AutoFilter -AutoFit
}