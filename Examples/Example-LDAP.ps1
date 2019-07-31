Import-Module .\ADEssentials.psd1 -Force

Test-LDAP -ComputerName 'AD1','AD2' | Format-Table