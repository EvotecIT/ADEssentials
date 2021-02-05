Import-Module .\ADEssentials.psd1 -Force

Get-WinADPrivilegedObjects -Verbose | Format-Table *