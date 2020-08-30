Import-Module .\ADEssentials.psd1 -Force

Get-WinADGroupMember -Group 'CN=Users,CN=Builtin,DC=ad,DC=evotec,DC=xyz' | Format-Table *
Get-WinADGroupMember -Group 'Test-Group' | Format-Table *
