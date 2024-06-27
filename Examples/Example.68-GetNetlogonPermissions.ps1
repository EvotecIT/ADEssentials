Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-WinADShare -ShareType SYSVOL | Format-Table

Get-WinADShare -Path '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\Policies\' -Owner | ft

Get-WinADSharePermission -Path '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\Policies\{64AD41CA-BF07-4DB3-BFC0-20F9999ADAD6}' -Owner | Format-Table