Clear-Host
Import-Module .\ADEssentials.psd1 -Force

#$Users = Get-ADUser -Filter "*" | Select-Object -First 1 -Skip 1
#Show-WinADObjectDifference -Identity $Users.DistinguishedName -Verbose -GlobalCatalog


<#
$User = Get-ADUser -Identity 'Administrator' -Properties *
$User.PSObject.Properties.Name | ForEach-Object {
    "'$_'"
}
$Computer = Get-ADComputer -Identity 'DC01' -Properties *
$Computer.PSObject.Properties.Name | ForEach-Object {
    "'$_'"
}
$Object = Get-ADObject -Identity 'CN=EX2016X1,OU=Default,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz' -Properties *
$Object.PSObject.Properties.Name | ForEach-Object {
    "'$_'"
}

#>



$Properties = @(
    'accountExpires'
    'CanonicalName'
    'CN'
    'codePage'
    'countryCode'
    'Created'
    'createTimeStamp'
    'Deleted'
    'Description'
    'DisplayName'
    'DistinguishedName'
    'dNSHostName'
    'instanceType'
    'lastLogon'
    'lastLogonTimestamp'
    'localPolicyFlags'
    'msDS-SupportedEncryptionTypes'
    'Name'
    'ObjectClass'
    'operatingSystem'
    'operatingSystemVersion'
    'primaryGroupID'
    'ProtectedFromAccidentalDeletion'
    'pwdLastSet'
    'sAMAccountName'
    'sAMAccountType'
    'sDRightsEffective'
    #'servicePrincipalName'
    'userAccountControl'
    'uSNChanged'
    'uSNCreated'
    'whenChanged'
    'whenCreated'
)


$Computers = @(
    'CN=EX2016X1,OU=Default,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'CN=Test4,OU=Default,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'

)
$Computers = get-aduser 'krbtgt'
Show-WinADObjectDifference -Identity $Computers.DistinguishedName -Verbose -Properties 'PasswordLastSet','LastLogonTimestamp' -FilePath $PSScriptRoot\Reports\Comparison.html