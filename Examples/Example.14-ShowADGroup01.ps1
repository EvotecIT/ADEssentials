Import-Module .\ADEssentials.psd1 -Force

#Show-WinADGroupMember -GroupName 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership1.html #-Online
#Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership2.html #-Online
Show-WinADGroupMember -GroupName 'GDS-TestGroup4' -FilePath $PSScriptRoot\Reports\GroupMembership3.html -Summary -Online