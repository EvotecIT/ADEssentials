
# Get-ADObject -Identity "__value__" | Select-Object -Property ObjectGUID

# $dn = 'CN=AD0,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz'
# $dn = 'CN=AD1,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz'

# $Forest = Get-WinADForestDetails -Extended
# $Forest
# return

#return

# # Get the DNS domain name for constructing the _msdcs DNS name
# # Get the DNS domain name for constructing the _msdcs DNS name
# $dnsDomain = (Get-ADDomain).DNSRoot

# # Get the list of all domain controllers in the current domain
# $domainControllers = Get-ADDomainController -Filter *

# foreach ($dc in $domainControllers) {
#     # Get the domain controller's computer object to access the objectGUID
#     $dcObject = Get-ADComputer -Identity $DC.ComputerObjectDN -Properties objectGUID

#     # Convert the objectGUID to a byte array, then to a string format
#     $guidByteArray = $dcObject.objectGUID
#     $guidString = (New-Object Guid($guidByteArray)).ToString()

#     # Construct the DNS name in the required format
#     $dnsName = "$guidString._msdcs.$dnsDomain"

#     # Output the DNS name
#     Write-Output $dnsName
# }

#$ForestInformation = Get-WinADForestDetails
#$ForestInformation.ForestDomainControllers | Format-Table domain, hostname, dsaguid, dsaguidname

repadmin /removelingeringobjects AD1 '653c120c-7523-439c-9f38-2acbf71bde31' 'DC=ad,DC=evotec,DC=xyz' /ADVISORY_MODE

#repadmin /removelingeringobjects AD1 '62a87a24-b9dd-46e7-a1bf-304a2b4a567c' 'DC=ad,DC=evotec,DC=xyz' /ADVISORY_MODE

