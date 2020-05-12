Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force
Clear-Host
Remove-WinADSharePermission -Path '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\scripts\' -Verbose #-LimitProcessing 1 #-WhatIf | Format-Table

#Get-WinADSharePermission -Path '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\scripts\' | Out-HtmlView -ScrollX -Filtering -DisablePaging