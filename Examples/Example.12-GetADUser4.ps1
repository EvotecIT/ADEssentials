Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Object = @(
    'CN=S-1-5-4,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
    'NT AUTHORITY\INTERACTIVE'
    'INTERACTIVE' # this will not be resolved
    'NT AUTHORITY\IUSR'
    'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
    'S-1-5-4'
    'S-1-5-11'
    'EVOTEC\Domain Admins'
    'EVOTECPL\Domain Admins'
    'EVOTECPL\Domain Admins'
    'EVOTECPL\Domain Admins'
    'EVOTECPL\Protected Users'
    'EVOTECPL\Print Operators'
    'EVOTEC\Protected Users'
    'EVOTEC\Print Operators'
    'TEST\Protected Users'
    'TEST\Print Operators'
)

$Results = Get-WinADObject -Identity $Object #-ErrorAction Stop
$Results | Format-Table
$Results.Count
$Object.Count