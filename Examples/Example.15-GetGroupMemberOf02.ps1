Import-Module .\ADEssentials.psd1 -Force

# Testing something, doesn't work

#Get-WinADObjectMember -Identity 'przemyslaw.klys' -AddSelf | Format-Table *
#Get-WinADObjectMember -Identity 'adm.pklys' -AddSelf | Format-Table *

$Object = Get-WinADObject -Identity 'przemyslaw.klys'
#$Object = Get-WinADObject -Identity 'adm.pklys'

#Get-ADSIObject -Identity $Object.ObjectSID -DomainDistinguishedName 'test.evotec.pl'

$TemporaryDomainName = 'test.evotec.pl'
$Ident = $Object.ObjectSID

$Ident = 'CN=S-1-5-21-853615985-2870445339-3163598659-1105,CN=ForeignSecurityPrincipals,DC=test,DC=evotec,DC=pl'
# Building the basic search object with some parameters
$Search = [System.DirectoryServices.DirectorySearcher]::new()
$Search.SizeLimit = $SizeLimit
Write-Verbose -Message "Different Domain specified: $TemporaryDomainName"
$Search.SearchRoot = "LDAP://$TemporaryDomainName"


$IdentityGUID = ""
Try {
    ([System.Guid]$Ident).ToByteArray() | ForEach-Object { $IdentityGUID += $("\{0:x2}" -f $_) }
} Catch {
    $IdentityGUID = "null"
}

#if ($PSBoundParameters['Identity']) {
#   if ($PSBoundParameters['DeletedOnly']) {
#      $Search.filter = "(&(isDeleted=True)(|(DistinguishedName=$Ident)(Name=$Ident)(SamAccountName=$Ident)(UserPrincipalName=$Ident)(objectGUID=$IdentityGUID)(objectSid=$Ident)))"
# } else {
$Search.filter = "(|(DistinguishedName=$Ident)(Name=$Ident)(SamAccountName=$Ident)(UserPrincipalName=$Ident)(objectGUID=$IdentityGUID)(objectSid=$Ident))"
#

$Test = $Search.FindAll()
$Test.properties | Format-Table *