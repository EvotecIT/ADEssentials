Import-Module .\ADEssentials.psd1 -Force

Set-ADKerberosPassword -All | Format-Table