Import-Module .\ADEssentials.psd1 -Force

#$Objects = Get-WinADBrokenProtectedFromDeletion -Verbose -Type All -LimitProcessing 3 -ReturnBrokenOnly
#$Objects | Format-Table -AutoSize *

#Repair-WinADBrokenProtectedFromDeletion -Type All -LimitProcessing 5 -Verbose -WhatIf

Invoke-ADEssentials -Type BrokenProtectedFromDeletion #-Verbose