Import-Module .\ADEssentials.psd1 -Force


Get-WinDnsServerForwarder

#Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Laps,LapsAndBitLocker -Verbose
return

Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html
Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Computers, Groups, Users, ServiceAccounts
Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type ForestACLOwners
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Computers, Users, ServiceAccounts, ForestACLOwners -SplitReports -HideHTML
Invoke-ADEssentials -Online -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Users
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Computers, Users, Groups, LAPS, LapsACL
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type AccountDelegation -Online -SplitReports
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Laps, LapsAndBitLocker, BitLocker -Online
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Laps, LapsAndBitLocker, BitLocker -Online
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type Laps -Online -SplitReports
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type LapsAndBitLocker, BitLocker -Online
Invoke-ADEssentials -FilePath $PSScriptRoot\Reports\ADEssentials.html -Type LapsACL -Online