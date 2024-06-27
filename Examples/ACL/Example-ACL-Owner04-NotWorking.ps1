Import-Module .\ADEssentials.psd1 -Force

$DN = 'OU=ITR01,DC=ad,DC=evotec,DC=xyz'

$ADObject = Get-ADObject -Properties ntSecurityDescriptor -Identity $DN
$ADObject.ntSecurityDescriptor | Format-Table

[System.Security.Principal.IdentityReference] $PrincipalIdentity = [System.Security.Principal.NTAccount]::new('AD.EVOTEC.XYZ', 'Enterprise Admins')
$ADObject = Get-ADObject -Properties ntSecurityDescriptor -Identity $DN
$ADObject.ntSecurityDescriptor.SetOwner($PrincipalIdentity)
#$ADObject.ntSecurityDescriptor.GetSecurityDescriptorSddlForm('Owner')
#$ADObject.ntSecurityDescriptor.SetSecurityDescriptorSddlForm('O:S-1-5-21-853615985-2870445339-3163598659-519','Owner')
Set-ADObject -PassThru -Replace @{
    ntSecurityDescriptor = $ADObject.ntSecurityDescriptor
    #Description          = 'ttest1'
} -Identity $DN


$ADObject = Get-ADObject -Properties ntSecurityDescriptor -Identity $DN
$ADObject.ntSecurityDescriptor | Format-Table