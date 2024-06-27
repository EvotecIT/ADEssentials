Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-WinADSharePermission -ShareType SYSVOL -Owner | Format-Table