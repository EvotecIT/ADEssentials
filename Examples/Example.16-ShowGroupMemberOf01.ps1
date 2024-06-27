Import-Module .\ADEssentials.psd1 -Force

Show-WinADGroupMemberOf -Identity 'przemyslaw.klys', 'adm.pklys' -Summary -Verbose
Show-WinADGroupMemberOf -Identity 'CN=My N@me,OU=UsersNoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz' -Summary -Verbose

Get-WinADObject -Identity 'UsersNoSync' # | Format-Table