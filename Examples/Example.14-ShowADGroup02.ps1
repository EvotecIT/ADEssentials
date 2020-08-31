Import-Module .\ADEssentials.psd1 -Force

Show-ADGroupMember -GroupName 'Domain Admins', 'Enterprise Admins', 'Administrators', 'Account Operators', 'Backup Operators' -FilePath $PSScriptRoot\Reports\GroupMembership.html -RemoveUsers
Show-ADGroupMember -GroupName 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership.html #-RemoveUser