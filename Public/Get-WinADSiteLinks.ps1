function Get-WinADSiteLinks {
    <#
    .SYNOPSIS
    Retrieves site links within an Active Directory forest.

    .DESCRIPTION
    This cmdlet retrieves and displays site links within an Active Directory forest. It can be used to identify the site links between sites, including their properties such as cost, replication frequency, and options. The cmdlet can also format the output to include or exclude specific details.

    .PARAMETER Forest
    Specifies the target forest to retrieve site links from. If not specified, the current forest is used.

    .PARAMETER Splitter
    Specifies the character to use as a delimiter when joining multiple options into a single string. If not specified, options are returned as an array.

    .PARAMETER Formatted
    A switch parameter that controls the level of detail in the output. If set, the output includes all available site link properties in a formatted manner. If not set, the output is more concise.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .EXAMPLE
    Get-WinADSiteLinks -Forest "example.com" -Formatted
    This example retrieves all site links within the "example.com" forest, displaying detailed information in a formatted manner.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires access to the target forest.
    #>
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