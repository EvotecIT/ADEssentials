Import-Module .\ADEssentials.psd1 -Force

# Don't do it for large domains, even small ones may be problematic
$Groups = Get-ADGroup -Filter *
Show-ADGroupMember -GroupName $Groups -FilePath $PSScriptRoot\Reports\GroupMembership.html -RemoveUsers