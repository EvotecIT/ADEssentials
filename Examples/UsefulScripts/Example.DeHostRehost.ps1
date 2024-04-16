
#Get-ADComputer -Server "DC1.AD.EVOTEC.PL" -Identity "CN=sdfsdfsf,OU=Pending Deletion,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=pl" | Format-Table
#Get-ADComputer -Server "AD0.AD.EVOTEC.XYZ:3268" -Identity "CN=sdfsdfsf,OU=Pending Deletion,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=pl" | Format-Table

#Get-ADComputer -Server "DC1.AD.EVOTEC.PL:3268" -Identity "CN=AD1,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz" | Format-Table
#return
<#
$Server = "ad0.ad.evotec.xyz"
$Partition = 'DC=AD,DC=EVOTEC,DC=XYZ'
$Domains = 'ad.evotec.pl'
foreach ($Domain in $Domains) {
    foreach ($DomainController in (Get-ADDomainController -Filter "*" -Server $Domain)) {
       # Write-Host "Unhosting $DomainController for $Partition"
       # repadmin /unhost $DomainController $Partition

        Write-Host "Rehosting $($DomainController.HostName) for $Partition" -ForegroundColor Green
        repadmin /rehost $DomainController.HostName $Partition $Server
    }
}
#>
Clear-Host
Get-ADComputer -Server "ADRODC.AD.EVOTEC.PL:3268" -Identity "CN=AD1,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz" | Format-Table
Get-ADComputer -Server "DC1.AD.EVOTEC.PL:3268" -Identity "CN=AD1,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz" | Format-Table

repadmin /unhost 'ADRODC.ad.evotec.pl' "DC=AD,DC=EVOTEC,DC=XYZ"
repadmin /unhost 'DC1.ad.evotec.pl' "DC=AD,DC=EVOTEC,DC=XYZ"
#Get-ADComputer -Server "DC1.AD.EVOTEC.PL:3268" -Identity "CN=AD1,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz" | Format-Table


repadmin /rehost 'DC1.ad.evotec.pl' "DC=AD,DC=EVOTEC,DC=XYZ" "AD0.AD.EVOTEC.XYZ"

repadmin /showrepl "DC1.ad.evotec.pl" "DC=AD,DC=EVOTEC,DC=XYZ" /v

repadmin /showattr gc: "DC=AD,DC=EVOTEC,DC=XYZ" /gc /atts:partialattributeset #>pas_domain.txt
repadmin /showattr fsmo_schema: ncobj:schema: /filter:"(ismemberofpartialattributeset=TRUE)" /subtree /atts:dn #>pas.txt


