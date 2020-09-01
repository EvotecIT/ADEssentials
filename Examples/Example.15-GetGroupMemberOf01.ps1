Import-Module .\ADEssentials.psd1 -Force

Get-WinADGroupMemberOf -Identity 'przemyslaw.klys' -AddSelf | Format-Table *
Get-WinADGroupMemberOf -Identity 'adm.pklys' -AddSelf | Format-Table *