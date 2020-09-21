Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

Get-ADACL -ADObject 'CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz' -IncludeActiveDirectoryRights 'GenericAll', 'CreateChild', 'WriteOwner', 'WriteDACL' -IncludeObjectTypeName All -ADRightsAsArray -ResolveTypes | Format-Table
Get-ADACL -ADObject 'CN=Policies,CN=System,DC=ad,DC=evotec,DC=pl' -IncludeActiveDirectoryRights 'GenericAll', 'CreateChild', 'WriteOwner', 'WriteDACL' -IncludeObjectTypeName All -ADRightsAsArray -ResolveTypes | Format-Table
#Get-ADACLOwner -ADObject 'CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz' -Resolve | Format-Table
#Get-ADObject -SearchBase 'CN=System,DC=ad,DC=evotec,DC=xyz' -Filter { ObjectClass -eq 'container' } | ForEach-Object {}