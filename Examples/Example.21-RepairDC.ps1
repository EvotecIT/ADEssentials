Import-Module .\ADEssentials.psd1 -Force

Get-WinADForestControllerInformation | Format-Table *

#Repair-WinADForestControllerInformation -Verbose -LimitProcessing 10 -Type Manager, Owner -WhatIf