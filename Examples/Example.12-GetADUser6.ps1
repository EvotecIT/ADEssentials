Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Object = @(
    'Administrators'
    'Domain Admins'
    'przemyslaw.klys'
    'EVOTECPL\Print Operators'
    'EVOTEC\Administrator'
    'EVOTECPL\Domain Computers'
    'EVOTECPL\Protected Users'
)
$Results = Get-WinADObject -Identity $Object
$Results | Format-Table
$Results.Count
$Object.Count