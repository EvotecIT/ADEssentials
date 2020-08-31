Import-Module .\ADEssentials.psd1 -Force

Show-ADGroupMember -GroupName 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership.html
Show-ADGroupMember -GroupName 'Test-Group', 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership.html
Show-ADGroupMember -GroupName 'GDS-TestGroup4' -FilePath $PSScriptRoot\Reports\GroupMembership.html
