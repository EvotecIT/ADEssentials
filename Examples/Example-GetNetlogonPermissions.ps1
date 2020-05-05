Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-WinADShare -ShareType NetLogon | Format-Table