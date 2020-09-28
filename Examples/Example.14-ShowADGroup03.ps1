Import-Module .\ADEssentials.psd1 -Force

# Don't do it for large domains, even small ones may be problematic
$Groups = Get-ADGroup -Filter *
Show-WinADGroupMember -GroupName $Groups -FilePath $PSScriptRoot\Reports\GroupMembership.html -HideUsers -Verbose