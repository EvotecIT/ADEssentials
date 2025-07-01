Import-Module .\ADEssentials.psd1 -Force

# https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.nativeobjectsecurity?view=net-8.0

Clear-Host
$DomainDN = (Get-ADDomain).DistinguishedName
$FindDN = "CN=Group-Policy-Container,CN=Schema,CN=Configuration,$DomainDN"
$ADObject = Get-ADObject -Identity $FindDN -Properties *
$SecurityDescriptor = Convert-ADSecurityDescriptor -SDDL $ADObject.defaultSecurityDescriptor -DistinguishedName $FindDN -Resolve
$SecurityDescriptor | Format-Table *

$ADObject1 = Get-ADObject -Identity "CN=ms-Exch-Recipient-Template,CN=Schema,CN=Configuration,DC=ad,DC=evotec,DC=xyz" -Properties *
$SecurityDescriptor1 = Convert-ADSecurityDescriptor -SDDL $ADObject1.defaultSecurityDescriptor -DistinguishedName $ADObject1.DistinguishedName -Resolve
$SecurityDescriptor1 | Format-Table