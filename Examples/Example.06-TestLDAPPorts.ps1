Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

#Test-LDAP -ComputerName 'AD1', 'AD2', 'DC1', 'AD3', 'ADRODC', 'ad1.ad.evotec.xyz', 'ad.evotec.xyz', '192.168.240.189' -Verify | Format-Table * #-WarningAction SilentlyContinue | Format-Table *
#Test-LDAP -ComputerName 'AD1', 'DC1' -Verify | Format-List * #-WarningAction SilentlyContinue | Format-Table *
#Test-LDAP -ComputerName 'AD1', '192.168.240.189', DC1, 'ADRODC','Mmm' -Verify | Format-Table * #-WarningAction SilentlyContinue | Format-Table *
#Test-LDAP -ComputerName 'AD1' -Verify | Format-Table *
Test-LDAP -VerifyCertificate -SkipRODC | Format-Table *