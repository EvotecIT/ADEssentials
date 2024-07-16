function Get-WinADWellKnownFolders {
    <#
    .SYNOPSIS
    Retrieves well-known folders for each domain in a forest.

    .DESCRIPTION
    This cmdlet retrieves the well-known folders for each domain in a specified forest. It supports the option to include or exclude specific domains and returns the results as a custom object or a hashtable.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve well-known folders from.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the retrieval process. If not specified, all domains in the forest will be included.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the retrieval process.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest to aid in the retrieval process.

    .PARAMETER AsCustomObject
    If specified, the cmdlet returns the results as a custom object. Otherwise, it returns a hashtable.

    .EXAMPLE
    Get-WinADWellKnownFolders -Forest "example.com" -IncludeDomains "example.com", "subdomain.example.com"

    This example retrieves the well-known folders for the "example.com" and "subdomain.example.com" domains in the "example.com" forest.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported.
    #>
    [cmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $AsCustomObject
    )
    $ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $DomainInformation = Get-ADDomain -Server $Domain
        $WellKnownFolders = $DomainInformation | Select-Object -Property UsersContainer, ComputersContainer, DomainControllersContainer, DeletedObjectsContainer, SystemsContainer, LostAndFoundContainer, QuotasContainer, ForeignSecurityPrincipalsContainer
        $CurrentWellKnownFolders = [ordered] @{ }
        foreach ($_ in $WellKnownFolders.PSObject.Properties.Name) {
            $CurrentWellKnownFolders[$_] = $DomainInformation.$_
        }
        <#
        $DomainDistinguishedName = $DomainInformation.DistinguishedName
        $DefaultWellKnownFolders = [ordered] @{
            UsersContainer                     = "CN=Users,$DomainDistinguishedName"
            ComputersContainer                 = "CN=Computers,$DomainDistinguishedName"
            DomainControllersContainer         = "OU=Domain Controllers,$DomainDistinguishedName"
            DeletedObjectsContainer            = "CN=Deleted Objects,$DomainDistinguishedName"
            SystemsContainer                   = "CN=System,$DomainDistinguishedName"
            LostAndFoundContainer              = "CN=LostAndFound,$DomainDistinguishedName"
            QuotasContainer                    = "CN=NTDS Quotas,$DomainDistinguishedName"
            ForeignSecurityPrincipalsContainer = "CN=ForeignSecurityPrincipals,$DomainDistinguishedName"
        }
        #>
        #Compare-MultipleObjects -Object @($DefaultWellKnownFolders, $CurrentWellKnownFolders) -SkipProperties
        if ($AsHashtable) {
            $CurrentWellKnownFolders
        } else {
            [PSCustomObject] $CurrentWellKnownFolders
        }
    }
}

#Get-WinADWellKnownFolders -IncludeDomains 'ad.evotec.xyz'