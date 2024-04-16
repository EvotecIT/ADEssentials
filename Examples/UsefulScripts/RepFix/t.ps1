$Object0 = Get-ADObject -Identity "CN=Class Store\0ADEL:4f56aca0-9acc-4f19-a492-d54011cc3df9,CN=Deleted Objects,DC=abb,DC=com" -IncludeDeletedObjects -Properties *
$Object0 | Format-Table *
$Object1 = Get-ADObject -Identity "CN=Packages\0ADEL:9c7d2b96-7a25-42a3-88d5-3c411cef6df7,CN=Deleted Objects,DC=abb,DC=com" -IncludeDeletedObjects -Properties *
$Object1 | Format-Table *
Remove-ADObject -Identity "CN=Packages\0ADEL:9c7d2b96-7a25-42a3-88d5-3c411cef6df7,CN=Deleted Objects,DC=abb,DC=com" -IncludeDeletedObjects -Recursive
Remove-ADObject -Identity "CN=Packages\0ADEL:9c7d2b96-7a25-42a3-88d5-3c411cef6df7,CN=Deleted Objects,DC=abb,DC=com" -IncludeDeletedObjects -Recursive