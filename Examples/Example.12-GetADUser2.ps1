Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Identity = @(
    'S-1-5-21-853615985-2870445339-3163598659-1174' # CN=GDS-TestGroup9,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz
    'S-1-5-21-1928204107-2710010574-1926425344-500' # CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl
    'S-1-5-21-1928204107-2710010574-1926425344-512' # CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl
    "S-1-5-21-853615985-2870445339-3163598659-1174"
    'CN=S-1-5-21-1928204107-2710010574-1926425344-512,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
    'CN=DnsAdmins,CN=Users,DC=ad,DC=evotec,DC=pl'
    'S-1-5-21-3661168273-3802070955-2987026695-1101' # 'CN=DnsAdmins,CN=Users,DC=ad,DC=evotec,DC=pl'
)
Get-WinADObject -Identity $Identity | Format-Table *
#Get-WinADObject -Identity $Identity | Format-List