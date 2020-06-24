function Get-WinADWellKnownFolders {
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