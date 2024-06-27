Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Object = @(
    'Administrators'
    'Domain Admins'
    'Print Operators'
    'Administrator'
    'Domain Computers'
    'Protected Users'
)
$Results = Get-WinADObject -Identity $Object #-DomainName 'test.evotec.pl'
$Results | Format-Table
$Results.Count
$Object.Count