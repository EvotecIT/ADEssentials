Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

@(
    Get-WinADObject -Identity 'TEST\Domain Admins' -Verbose
    Get-WinADObject -Identity 'EVOTEC\Domain Admins' -Verbose
    Get-WinADObject -Identity 'Domain Admins' -DomainName 'DC=AD,DC=EVOTEC,DC=PL' -Verbose
    Get-WinADObject -Identity 'Domain Admins' -DomainName 'ad.evotec.pl' -Verbose
    Get-WinADObject -Identity 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=pl'
    Get-WinADObject -Identity 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=xyz'
    Get-WinADObject -Identity 'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
    Get-WinADObject -Identity 'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
) | Format-Table *