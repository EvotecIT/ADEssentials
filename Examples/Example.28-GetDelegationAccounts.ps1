Import-Module .\ADEssentials.psd1 -Force

Get-WinADDelegatedAccounts | Format-Table *