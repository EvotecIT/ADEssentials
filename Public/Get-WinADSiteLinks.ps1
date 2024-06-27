function Get-WinADSiteLinks {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [alias('Joiner')][string] $Splitter,
        [string] $Formatted,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    [Flags()]
    enum SiteLinksOptions {
        None = 0
        UseNotify = 1
        TwoWaySync = 2
        DisableCompression = 4
    }

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $NamingContext = (Get-ADRootDSE -Server $QueryServer).configurationNamingContext
    $SiteLinks = Get-ADObject -LDAPFilter "(objectCategory=sitelink)" –Searchbase $NamingContext -Properties * -Server $QueryServer
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