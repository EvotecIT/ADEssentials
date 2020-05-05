Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-WinADShare -ShareType SYSVOL -Owner | Format-Table