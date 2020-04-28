Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

#$T = Get-ADACLOwner -ADObject 'CN={051BCDDF-CC11-427B-BDF0-684C0A6E3DDB},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz','CN={051BCDDF-CC11-427B-BDF0-684C0A6E3DDB},CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz'
$T[0].Acls.Sddl

ConvertFrom-SddlString $T[0].Acls.Sddl
