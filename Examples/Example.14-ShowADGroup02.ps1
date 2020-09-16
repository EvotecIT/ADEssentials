Import-Module .\ADEssentials.psd1 -Force
Import-Module 'C:\Users\przemyslaw.klys\OneDrive - Evotec\Support\GitHub\PSWriteHTML\PSWriteHTML.psd1' -Force

Show-WinADGroupMember 'Domain Admins' {
    TableCondition -Name 'SamAccountName' -BackgroundColor red -Color white -Value '^adm_' -Operator notlike -ComparisonType string
    TableCondition -Name 'Type' -BackgroundColor red -Color white -Value 'group' -Operator eq -ComparisonType string
    TableCondition -Name 'Nesting' -BackgroundColor red -Color white -Value 0 -Operator gt -ComparisonType number -Row
} -FilePath $PSScriptRoot\Reports\GroupMembership.html -Online
#Show-WinADGroupMember -GroupName 'Domain Admins', 'Enterprise Admins', 'Administrators', 'Account Operators', 'Backup Operators' -Online #-HideUsers
#Show-WinADGroupMember -GroupName 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership.html #-RemoveUser