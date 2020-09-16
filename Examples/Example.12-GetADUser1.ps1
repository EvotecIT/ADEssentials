Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Users = @(
    'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
    'S-1-5-21-1928204107-2710010574-1926425344-500' # CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl
    'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
    'S-1-5-21-1928204107-2710010574-1926425344-512' # CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl
    'Test Local Group'
    'przemyslaw.klys'
    'EVOWIN'
    'CN=Przemysław Kłys,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'GDS-TestGroup5'
    'TEST\Domain Admins'
    'S-1-5-21-1928204107-2710010574-1926425344-512'
    'CN=S-1-5-21-1928204107-2710010574-1926425344-512,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
    'CN=Przemysław Kłys,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'CN=Test1,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'CN=GDS-TestGroup9,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'S-1-5-21-853615985-2870445339-3163598659-1174' # CN=GDS-TestGroup9,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz
    'S-1-5-21-1928204107-2710010574-1926425344-500' # CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl
    'S-1-5-21-3661168273-3802070955-2987026695-512' # CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=pl
    'EVOTECPL\Domain Admins'
)

$Output = Get-WinADObject -Identity $Users -Verbose
$Output | Format-Table *
$Users.Count
$Output.Count