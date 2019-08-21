function Get-WinADSiteConnections {
    [CmdletBinding()]
    param(
        [alias('Joiner')][string] $Splitter,
        [string] $Formatted
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

    $NamingContext = (Get-ADRootDSE).configurationNamingContext
    $Connections = Get-ADObject –Searchbase $NamingContext -LDAPFilter "(objectCategory=ntDSConnection)" -Properties *
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