Import-Module .\ADEssentials.psd1 -Force

Get-WinADGroupMember -Identity 'MMM2' -All | Format-Table -AutoSize



Show-WinADGroupMember -GroupName 'MMM2', 'Domain Admins'

return

Show-WinADGroupMember -GroupName 'Domain Admins', 'Enterprise Admins' -FilePath $PSScriptRoot\Reports\GroupMembership1.html -Online -Verbose -SkipDiagram
Show-WinADGroupMember -GroupName 'MyGroup' -FilePath $PSScriptRoot\Reports\GroupMembership2.html -Online -Verbose
Show-WinADGroupMemberOf -Identity 'przemyslaw.klys' -FilePath $PSScriptRoot\Reports\GroupMembership2.html -Online -Verbose
Show-WinADGroupMemberOf -Identity 'MyGroup' -FilePath $PSScriptRoot\Reports\GroupMembership2.html -Online -Verbose
Show-WinADGroupMember -GroupName 'GDS-TestGroup4' -FilePath $PSScriptRoot\Reports\GroupMembership3.html -Summary -Online -Verbose
Show-WinADGroupMember -GroupName 'Group1' -Verbose -Online