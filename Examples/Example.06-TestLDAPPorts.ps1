Clear-Host
Import-Module .\ADEssentials.psd1 -Force

#Test-LDAP -ComputerName 'AD1', 'AD2', 'DC1', 'AD3', 'ADRODC', 'ad1.ad.evotec.xyz', 'ad.evotec.xyz', '192.168.240.189' -Verify | Format-Table * #-WarningAction SilentlyContinue | Format-Table *
#Test-LDAP -ComputerName 'AD1', 'DC1' -Verify | Format-List * #-WarningAction SilentlyContinue | Format-Table *
#Test-LDAP -ComputerName 'AD1', '192.168.240.189', DC1, 'ADRODC','Mmm' -Verify | Format-Table * #-WarningAction SilentlyContinue | Format-Table *
#Test-LDAP -ComputerName 'AD1' -VerifyCertificate | Format-Table *
#Test-LDAP -IncludeDomains 'ad.evotec.xyz' -VerifyCertificate | Format-Table *
#Test-LDAP -SkipRODC | Format-Table *

#Test-LDAP -ComputerName 'AD1', '192.168.241.6' -VerifyCertificate -Identity 'Administrator' | Format-List *
#Test-LDAP -ComputerName 'AD1', '192.168.241.6' -Identity 'Administrator' -Verbose -VerifyCertificate -Extended | Format-List *

#Measure-Command {
#Test-LDAP -Identity 'Administrator' -VerifyCertificate | Format-Table *
#}


Test-LDAP -ComputerName 'ad.evotec.xyz' -VerifyCertificate -Verbose | Format-Table



$Domain = Get-ADDomain
$Path = "C:\Temp\Trusts_$($Domain.DNSRoot)-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').html"
$TargetPath = "\\xe-s-admgmt01.xe.abb.com\Reports$\Trusts"
Show-WinADTrust -Recursive -FilePath $Path -HideHTML
Move-Item -LiteralPath $Path -Destination $TargetPath -Force