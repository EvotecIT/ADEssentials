Import-Module .\ADEssentials.psd1 -Force

Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html
#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Users
#Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type ServiceAccounts
