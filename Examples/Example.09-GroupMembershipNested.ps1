Import-Module .\ADEssentials.psd1 -Force

# Lets check only two groups
Get-WinADGroupMember -Group 'Test Local Group', 'GDS-TestGroup5' -Cache | Format-Table *

# How about all groups
$Groups = Get-ADGroup -Filter *
$AllGroups = $Groups | Get-WinADGroupMember -Cache
$AllGroups | Out-HtmlView -ScrollX -DisablePaging -Filtering