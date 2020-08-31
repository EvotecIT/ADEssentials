Import-Module .\ADEssentials.psd1 -Force

Show-WinADGroupMember -GroupName 'GDS-TestGroup2'

#Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins','Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html -Summary

#Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins','Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html -SummaryOnly