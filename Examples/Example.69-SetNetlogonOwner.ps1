Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Path = '\\ad.evotec.xyz\SYSVOL\ad.evotec.xyz\scripts'

Set-WinADShare -Path $Path -Owner -Type Default -Verbose