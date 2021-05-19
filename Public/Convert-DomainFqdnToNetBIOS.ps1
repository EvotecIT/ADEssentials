Function Convert-DomainFqdnToNetBIOS {
    <#
    .SYNOPSIS
    Converts FQDN to NetBIOS name for Active Directory Domain

    .DESCRIPTION
    Converts FQDN to NetBIOS name for Active Directory Domain

    .PARAMETER DomainName
    DomainName for current forest or trusted forest

    .EXAMPLE
    Convert-DomainFqdnToNetBIOS -Domain 'ad.evotec.xyz'

    .EXAMPLE
    Convert-DomainFqdnToNetBIOS -Domain 'ad.evotec.pl'

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param (
        [string] $DomainName
    )
    if (-not $Script:CacheFQDN) {
        $Script:CacheFQDN = @{}
    }
    if ($Script:CacheFQDN[$DomainName]) {
        $Script:CacheFQDN[$DomainName]
    } else {
        $objRootDSE = [System.DirectoryServices.DirectoryEntry] "LDAP://$DomainName/RootDSE"
        $ConfigurationNC = $objRootDSE.configurationNamingContext
        $Searcher = [System.DirectoryServices.DirectorySearcher] @{
            SearchScope = "subtree"
            SearchRoot  = "LDAP://cn=Partitions,$ConfigurationNC"
            Filter      = "(&(objectcategory=Crossref)(dnsRoot=$DomainName)(netbiosname=*))"
        }
        $null = $Searcher.PropertiesToLoad.Add("netbiosname")
        $Script:CacheFQDN[$DomainName] = ($Searcher.FindOne()).Properties.Item("netbiosname")
        $Script:CacheFQDN[$DomainName]
    }
}