Import-Module .\ADEssentials.psd1 -Force

Show-WinADTrust -Online -FilePath $PSScriptRoot\Reports\TrustsWithColors.html -Verbose {
    TableHeader -Names 'TrustBase', 'TrustType', 'TrustTypeAD' -Color Blue -Title 'Types'
    TableCondition -Name 'TrustDirection' -BackgroundColor red -Color white -Value 'Bidirectional' -Operator eq -ComparisonType string
    TableCondition -Name 'Level' -BackgroundColor blue -Color white -Value 0 -Operator eq -ComparisonType number
} -DisableBuiltinConditions