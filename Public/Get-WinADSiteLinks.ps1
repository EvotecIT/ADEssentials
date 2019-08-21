function Get-WinADSiteLinks {
    [CmdletBinding()]
    param(
        [alias('Joiner')][string] $Splitter,
        [string] $Formatted
    )
    [Flags()]
    enum SiteLinksOptions {
        None = 0
        UseNotify = 1
        TwoWaySync = 2
        DisableCompression = 4
    }

    $NamingContext = (Get-ADRootDSE).configurationNamingContext
    $SiteLinks = Get-ADObject -LDAPFilter "(objectCategory=sitelink)" –Searchbase $NamingContext -Properties *
    foreach ($_ in $SiteLinks) {

        if ($null -eq $_.Options) {
            $Options = 'None'
        } else {
            $Options = ([SiteLinksOptions] $_.Options) -split ', '
        }

        if ($Formatted) {
            [PSCustomObject] @{
                Name                                 = $_.CN
                Cost                                 = $_.Cost
                'Replication Frequency In Minutes'   = $_.ReplInterval
                Options                              = if ($Splitter -ne '') { $Options -Join $Splitter } else { $Options }
                #ReplInterval                    : 15
                Created                              = $_.WhenCreated
                Modified                             = $_.WhenChanged
                #Deleted                         :
                #InterSiteTransportProtocol      : IP
                'Protected From Accidental Deletion' = $_.ProtectedFromAccidentalDeletion
            }
        } else {
            [PSCustomObject] @{
                Name                            = $_.CN
                Cost                            = $_.Cost
                ReplicationFrequencyInMinutes   = $_.ReplInterval
                Options                         = if ($Splitter -ne '') { $Options -Join $Splitter } else { $Options }
                #ReplInterval                    : 15
                Created                         = $_.WhenCreated
                Modified                        = $_.WhenChanged
                #Deleted                         :
                #InterSiteTransportProtocol      : IP
                ProtectedFromAccidentalDeletion = $_.ProtectedFromAccidentalDeletion
            }
        }
    }
}