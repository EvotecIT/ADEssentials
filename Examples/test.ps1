Clear-Host
$ServerName = 'XP-S-EUR0555.europe.abb.com'
$ServerName = 'xf-s-nme0004.nmea.abb.com'
#$ServerName = 'XE-S-NME0002.nmea.abb.com'

$Port = '3269'
#$Identity = 'CN=Marcin D. Robak,OU=External,OU=Users,OU=PLABB,OU=PL,DC=europe,DC=abb,DC=com'
$Identity = 'marcin.d.robak@pl.abb.com'
#$Identity = 'CN=ABBAdmin,CN=Users,DC=nmea,DC=abb,DC=com'
#$Identity = 'CN=ADFRecovery,CN=Users,DC=europe,DC=abb,DC=com'
#$Identity = 'CN=krbtgt,CN=Users,DC=europe,DC=abb,DC=com'
#$Identity = 'PLMAROB'
$LDAP = "LDAP://" + $ServerName + ':' + $Port + "/DC=ABB,DC=COM"
if ($Credential) {
    $Connection = [ADSI]::new($LDAP, $Credential.UserName, $Credential.GetNetworkCredential().Password)
} else {
    $Connection = [ADSI]($LDAP)
}

$Searcher = [System.DirectoryServices.DirectorySearcher]$Connection
$Searcher.Filter = "(|(DistinguishedName=$Identity)(Name=$Identity)(SamAccountName=$Identity)(UserPrincipalName=$Identity)(objectGUID=$Identity)(objectSid=$Identity))"
$SearchResult = $Searcher.FindAll()
$SearchResult