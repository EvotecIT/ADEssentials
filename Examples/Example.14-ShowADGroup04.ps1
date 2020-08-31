Import-Module .\ADEssentials.psd1 -Force

#Show-ADGroupMember -GroupName 'Test-Group', 'Domain Admins','Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html -Summary

Show-ADGroupMember -GroupName 'Test-Group', 'Domain Admins','Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html -SummaryOnly