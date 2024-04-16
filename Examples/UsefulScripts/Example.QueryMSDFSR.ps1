

$ForestInformation = Get-WinADForestDetails

foreach ($Domain in $ForestInformation.Domains) {
    $DomainDN = ConvertTo-DistinguishedName -CanonicalName $Domain -ToDomain
    $QueryServer = $ForestInformation['QueryServers'][$Domain].HostName[0]
    $ObjectsInOu = Get-ADObject -LDAPFilter "(ObjectClass=msDFSR-Member)" -Properties * -SearchBase "CN=Topology,CN=Domain System Volume,CN=DFSR-GlobalSettings,CN=System,$DomainDN" -Server $QueryServer
    $ObjectsInOu | Format-Table Name, msDFSR-ComputerReference,msDFSR-MemberReferenceBL,ProtectedFromAccidentalDeletion,serverReference, WhenChanged, WhenCreated, DistinguishedName
}


#$ObjectsInOu = Get-ADObject -LDAPFilter "(ObjectClass=msDFSR-Member)" -Properties * -SearchBase "CN=Topology,CN=Domain System Volume,CN=DFSR-GlobalSettings,CN=System,DC=ad,DC=evotec,DC=xyz"
#$ObjectsInOu