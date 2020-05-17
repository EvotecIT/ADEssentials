Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Path = '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\scripts'

Remove-WinADSharePermission -Type Unknown -Path $Path -Verbose -LimitProcessing 1 -WhatIf