Import-Module .\ADEssentials.psd1 -Force

Show-WinADGroupMember -GroupName 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership.html
Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership.html
Show-WinADGroupMember -GroupName 'GDS-TestGroup4' -FilePath $PSScriptRoot\Reports\GroupMembership.html
