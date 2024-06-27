Import-Module .\ADEssentials.psd1 -Force

Get-WinADACLForest -Owner -IncludeOwnerType Unknown,NotAdministrative | Format-Table
Get-WinADACLForest -Owner -ExcludeOwnerType Administrative,WellKnownAdministrative | Format-Table
