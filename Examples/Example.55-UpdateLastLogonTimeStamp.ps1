Import-Module .\ADEssentials.psd1 -Force

# check current timestamps
$DCs = Get-ADDomainController -Filter "*" -Server 'ad.evotec.xyz'
$All = foreach ($DC in $DCs) {
    Get-ADUser -Identity 'PUID' -Server $DC.Hostname -Properties *
}
$All | Format-Table Name, DIsplayName, UserPrincipalName, LastLogonDate, LastLogon, LastLogonTimestamp

# update the last logon timestamp
Update-LastLogonTimestamp -UserName 'PUID' -WhatIf

# check again
$All = foreach ($DC in $DCs) {
    Get-ADUser -Identity 'PUID' -Server $DC.Hostname -Properties *
}
$All | Format-Table Name, DIsplayName, UserPrincipalName, LastLogonDate, LastLogon, LastLogonTimestamp