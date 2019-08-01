Import-Module .\ADEssentials.psd1 -Force

Test-LDAP -ComputerName 'AD1','AD2','ADPREVIEW2019','DC1','AD4','ADRODC' -WarningAction SilentlyContinue | Format-Table