Clear-Host
Import-Module $PSScriptRoot\..\..\ADEssentials.psd1 -Force

$ACLOutput = Get-ADACL -ADObject 'DC=ad,DC=evotec,DC=xyz' -Bundle
$ACLOutput | Format-Table
$ACLOutput.ACLAccessRules | Format-Table

$ActiveDirectoryAccessRules = Export-ADACLObject -ADObject 'DC=ad,DC=evotec,DC=xyz' -Principal 'NT AUTHORITY\NETWORK SERVICE', 'NT AUTHORITY\Authenticated Users' -Bundle
$ActiveDirectoryAccessRules | Format-Table
Add-ADACL -ADObject 'OU=Accounts01,OU=Tier2,DC=ad,DC=evotec,DC=xyz' -ActiveDirectoryAccessRule $ActiveDirectoryAccessRules[4].ActiveDirectoryAccessRule -Verbose
Add-ADACL -ADObject 'OU=Accounts01,OU=Tier2,DC=ad,DC=evotec,DC=xyz' -Principal 'S-1-5-32-554' -AccessRule 'GenericAll' -AccessControlType Allow -InheritanceType All -Verbose

foreach ($A in $ActiveDirectoryAccessRules) {
    Add-ADACL -ActiveDirectoryAccessRule $A.ActiveDirectoryAccessRule -ADObject 'OU=Accounts01,OU=Tier2,DC=ad,DC=evotec,DC=xyz' -Verbose
}