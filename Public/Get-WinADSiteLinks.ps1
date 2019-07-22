function Get-WinADSiteLinks {
    [CmdletBinding()]
    param(

    )
    $NamingContext = (Get-ADRootDSE).configurationNamingContext
    $SiteLinks = Get-ADObject -LDAPFilter "(objectCategory=sitelink)" –Searchbase $NamingContext -Properties *
    foreach ($_ in $SiteLinks) {
        [PSCustomObject] @{
            Name                            = $_.CN
            Cost                            = $_.Cost
            ReplicationFrequencyInMinutes   = $_.ReplInterval
            Options                         = $_.Options
            #ReplInterval                    : 15
            Created                         = $_.WhenCreated
            Modified                        = $_.WhenChanged
            #Deleted                         :
            #InterSiteTransportProtocol      : IP
            ProtectedFromAccidentalDeletion = $_.ProtectedFromAccidentalDeletion
        }
    }
}