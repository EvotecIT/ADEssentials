# Load the required assembly
Add-Type -AssemblyName System.DirectoryServices.Protocols



# LDAP connection parameters
$ldapServer = "AD1.ad.evotec.xyz"
$ldapContainer = "DC=ad,DC=evotec,DC=pl" # Adjust for your domain

# Create LDAP connection and set options
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($ldapServer)
$ldapConnection.SessionOptions.ProtocolVersion = 3

# Create a SearchRequest object
$searchFilter = "(isDeleted=true)" # Search filter to find deleted objects
$searchBase = "CN=Deleted Objects,$ldapContainer"
$searchScope = [System.DirectoryServices.Protocols.SearchScope]::Subtree

# Including ShowDeletedControl to the search request to see deleted objects
$showDeletedControl = New-Object System.DirectoryServices.Protocols.ShowDeletedControl
$searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest($ldapContainer, $searchFilter, $searchScope, "dn")
$searchRequest.Controls.Add($showDeletedControl)

# Perform the search
$searchResponse = $ldapConnection.SendRequest($searchRequest)

# Display the results
foreach ($entry in $searchResponse.Entries)
{
    Write-Host "DN: $($entry.DistinguishedName)"
    # Extract and display additional attributes as necessary
}

# Cleanup
$ldapConnection.Dispose()
