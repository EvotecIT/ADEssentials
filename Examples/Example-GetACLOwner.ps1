Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$T = Get-ADACLOwner -ADObject 'CN={051BCDDF-CC11-427B-BDF0-684C0A6E3DDB},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz', 'CN={051BCDDF-CC11-427B-BDF0-684C0A6E3DDB},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz'
$T | Format-Table

$T = Get-ADACLOwner -ADObject 'CN={051BCDDF-CC11-427B-BDF0-684C0A6E3DDB},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz', 'CN={051BCDDF-CC11-427B-BDF0-684C0A6E3DDB},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz' -Resolve
$T | Format-Table

Get-ADACLOwner -ADObject 'CN={31B2F340-016D-11D2-945F-00C04FB984F9},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz' -Resolve | Format-Table