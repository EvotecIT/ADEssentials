Import-Module .\ADEssentials.psd1 -Force

#$AccountData = Get-WinADKerberosAccount
#$AccountData | Format-Table

Show-WinADKerberosAccount -Verbose -FilePath $PSScriptRoot\Kerberos.html #-IncludeDomains 'ad.evotec.xyz'