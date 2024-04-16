
<#
$DCs = Get-ADDomainController -Filter "*" -Server 'ad.evotec.xyz'
$All = foreach ($DC in $DCs) {
    Get-ADUser -Identity 'PUID' -Server $DC.Hostname -Properties *
}
$All | Format-Table Name, DIsplayName, UserPrincipalName, LastLogonDate, LastLogon, LastLogonTimestamp, DistinguishedName

#>

Move-ADObject -Identity 'CN=Brian Williams,OU=SE,OU=ITR01,DC=ad,DC=evotec,DC=xyz' -TargetPath "OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=pl" -TargetServer "DC1.AD.EVOTEC.PL" -Server "AD1.AD.EVOTEC.XYZ"
#Move-ADObject -Identity 'CN=Brian Williams,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=pl' -TargetPath "OU=SE,OU=ITR01,DC=ad,DC=evotec,DC=xyz" -TargetServer "AD1.AD.EVOTEC.XYZ" -Server "DC1.AD.EVOTEC.PL"