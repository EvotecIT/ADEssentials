Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-WinADSharePermission -Path '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\scripts\' | Out-HtmlView -ScrollX -Filtering -DisablePaging