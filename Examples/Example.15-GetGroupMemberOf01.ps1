Import-Module .\ADEssentials.psd1 -Force

#Get-WinADGroupMemberOf -Identity 'przemyslaw.klys' -AddSelf -Verbose | Format-Table *
#Show-WinADGroupMemberOf -Identity 'przemyslaw.klys' -Verbose -Summary
Show-WinADGroupMemberOf -Identity 'przemyslaw.klys' -Verbose -Summary
#Show-WinADGroupMember -Identity 'Domain Admins' -Verbose -Summary -Online
#return
#Get-WinADGroupMemberOf -Identity 'adm.pklys' -AddSelf | Format-Table *
#(Get-WinADGroupMemberOf -Identity 'przemyslaw.klys' -AddSelf)[1]