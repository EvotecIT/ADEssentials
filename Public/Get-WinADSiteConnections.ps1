function Get-WinADSiteConnections {
    <#
    .SYNOPSIS
    Retrieves site connections within an Active Directory forest.

    .DESCRIPTION
    This cmdlet retrieves and displays site connections within an Active Directory forest. It can be used to identify the connections between sites, including their properties such as options, server names, and site names. The cmdlet can also format the output to include or exclude specific details.

    .PARAMETER Forest
    Specifies the target forest to retrieve site connections from. If not specified, the current forest is used.

    .PARAMETER Splitter
    Specifies the character to use as a delimiter when joining multiple options into a single string. If not specified, options are returned as an array.

    .PARAMETER Formatted
    A switch parameter that controls the level of detail in the output. If set, the output includes all available site connection properties in a formatted manner. If not set, the output is more concise.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .EXAMPLE
    Get-WinADSiteConnections -Forest "example.com" -Formatted
    This example retrieves all site connections within the "example.com" forest, displaying detailed information in a formatted manner.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires access to the target forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [alias('Joiner')][string] $Splitter,
        [switch] $Formatted,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    [Flags()]
    enum ConnectionOption {
        None
        IsGenerated
        TwoWaySync
        OverrideNotifyDefault = 4
        UseNotify = 8
        DisableIntersiteCompression = 16
        UserOwnedSchedule = 32
        RodcTopology = 64
    }

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation['QueryServers'][$($ForestInformation.Forest.Name)]['HostName'][0]


    $NamingContext = (Get-ADRootDSE -Server $QueryServer).configurationNamingContext
    $Connections = Get-ADObject -Searchbase $NamingContext -LDAPFilter "(objectCategory=ntDSConnection)" -Properties * -Server $QueryServer
    $FormmatedConnections = foreach ($_ in $Connections) {
        if ($null -eq $_.Options) {
            $Options = 'None'
        } else {
            $Options = ([ConnectionOption] $_.Options) -split ', '
        }
        if ($Formatted) {
            $Dictionary = [PSCustomObject] @{

                <# Regex extracts AD1 and AD2
        CN=d1695d10-8d24-41db-bb0f-2963e2c7dfcd,CN=NTDS Settings,CN=AD1,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        CN=NTDS Settings,CN=AD2,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        #>
                'CN'                 = $_.CN
                'Description'        = $_.Description
                'Display Name'       = $_.DisplayName
                'Enabled Connection' = $_.enabledConnection
                'Server From'        = if ($_.fromServer -match '(?<=CN=NTDS Settings,CN=)(.*)(?=,CN=Servers,)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                'Server To'          = if ($_.DistinguishedName -match '(?<=CN=NTDS Settings,CN=)(.*)(?=,CN=Servers,)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                <# Regex extracts KATOWICE-1
        CN=d1695d10-8d24-41db-bb0f-2963e2c7dfcd,CN=NTDS Settings,CN=AD1,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        CN=NTDS Settings,CN=AD2,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        #>
                'Site From'          = if ($_.fromServer -match '(?<=,CN=Servers,CN=)(.*)(?=,CN=Sites,CN=Configuration)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                'Site To'            = if ($_.DistinguishedName -match '(?<=,CN=Servers,CN=)(.*)(?=,CN=Sites,CN=Configuration)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                'Options'            = if ($Splitter -ne '') { $Options -Join $Splitter } else { $Options }
                #'Options'            = $_.Options
                'When Created'       = $_.WhenCreated
                'When Changed'       = $_.WhenChanged
                'Is Deleted'         = $_.IsDeleted
            }
        } else {
            $Dictionary = [PSCustomObject] @{

                <# Regex extracts AD1 and AD2
        CN=d1695d10-8d24-41db-bb0f-2963e2c7dfcd,CN=NTDS Settings,CN=AD1,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        CN=NTDS Settings,CN=AD2,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        #>
                CN                = $_.CN
                Description       = $_.Description
                DisplayName       = $_.DisplayName
                EnabledConnection = $_.enabledConnection
                ServerFrom        = if ($_.fromServer -match '(?<=CN=NTDS Settings,CN=)(.*)(?=,CN=Servers,)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                ServerTo          = if ($_.DistinguishedName -match '(?<=CN=NTDS Settings,CN=)(.*)(?=,CN=Servers,)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                <# Regex extracts KATOWICE-1
        CN=d1695d10-8d24-41db-bb0f-2963e2c7dfcd,CN=NTDS Settings,CN=AD1,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        CN=NTDS Settings,CN=AD2,CN=Servers,CN=KATOWICE-1,CN=Sites,CN=Configuration,DC=ad,DC=evotec,DC=xyz
        #>
                SiteFrom          = if ($_.fromServer -match '(?<=,CN=Servers,CN=)(.*)(?=,CN=Sites,CN=Configuration)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                SiteTo            = if ($_.DistinguishedName -match '(?<=,CN=Servers,CN=)(.*)(?=,CN=Sites,CN=Configuration)') {
                    $Matches[0]
                } else {
                    $_.fromServer
                }
                Options           = if ($Splitter -ne '') { $Options -Join $Splitter } else { $Options }
                #Options           = $_.Options
                WhenCreated       = $_.WhenCreated
                WhenChanged       = $_.WhenChanged
                IsDeleted         = $_.IsDeleted
            }

        }
        $Dictionary
    }
    $FormmatedConnections
}