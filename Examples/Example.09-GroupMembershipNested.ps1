Import-Module .\ADEssentials.psd1 -Force

# Lets check only two groups
Get-WinADGroupMember -Group 'Test Local Group', 'GDS-TestGroup5' -Cache | Format-Table *

# How about all groups
$Groups = Get-ADGroup -Filter "*"
$AllGroups = $Groups | Get-WinADGroupMember -Cache
$AllGroups | Out-HtmlView -ScrollX -DisablePaging -Filtering

# Please notice we are using cache parameter, however that can slow things down if you're not going to ask for whole domain
# It's often better to skip -Cache and still the script would keep cache on per query basis