Import-Module .\ADEssentials.psd1 -Force

Get-WinADObjectMember -Identity 'przemyslaw.klys' -AddSelf | Format-Table *
Get-WinADObjectMember -Identity 'adm.pklys' -AddSelf | Format-Table *