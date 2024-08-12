Clear-Host
Import-Module .\ADEssentials.psd1 -Force


Test-LDAP -IncludeDomainControllers 'ad1.ad.evotec.xyz' -Identity "krbtgt" -Verbose -RetryCount 3 | Format-list *

Test-LDAP -ComputerName 'ad.evotec.xyz' -VerifyCertificate -Verbose | Format-Table

Test-LDAP -VerifyCertificate -Verbose  | Format-Table

Test-LDAP -VerifyCertificate -Verbose -IncludeDomains 'ad.evotec.pl' | Format-Table