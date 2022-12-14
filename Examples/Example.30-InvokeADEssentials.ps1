Import-Module .\ADEssentials.psd1 -Force

#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html
#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Users
#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type ServiceAccounts
#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type ForestACLOwners
#Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Computers, Users, ServiceAccounts, ForestACLOwners -SplitReports -HideHTML
#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Users
#
#Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Computers, Users, Groups
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Groups -Online