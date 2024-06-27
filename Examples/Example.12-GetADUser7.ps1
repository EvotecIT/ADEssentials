Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force


#Get-WinADObject -Identity 'BUILTIN\Administrators' -DomainName 'test.evotec.pl' -Verbose

#return
$Object = @(
    'Administrators'
    'Domain Admins'
    'przemyslaw.klys'
    'CN=Przemysław Kłys,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'Print Operators'
    'Administrator'
    'Domain Computers'
    'Protected Users'
    'EVOWIN'
)
$Results = Get-WinADObject -Identity $Object -Verbose #-DomainName 'ad.evotec.xyz'
$Results | Format-Table
$Results.Count
$Object.Count