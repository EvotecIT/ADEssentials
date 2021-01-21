Import-Module .\ADEssentials.psd1 -Force

Get-WinADForestControllerInformation -Verbose | Format-Table *

Repair-WinADForestControllerInformation -Verbose -LimitProcessing 10 -Type Manager, Owner -WhatIf