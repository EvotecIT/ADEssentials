Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-WinADObject -Identity 'Administrators'
Get-WinADObject -Identity 'Domain Admins'
Get-WinADObject -Identity 'przemyslaw.klys'