function Set-WinADReplicationConnections {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [switch] $Force,
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
    $QueryServer = $ForestInformation.QueryServers['Forest']['HostName'][0]

    $NamingContext = (Get-ADRootDSE -Server $QueryServer).configurationNamingContext
    $Connections = Get-ADObject –Searchbase $NamingContext -LDAPFilter "(objectCategory=ntDSConnection)" -Properties * -Server $QueryServer
    foreach ($_ in $Connections) {
        $OptionsTranslated = [ConnectionOption] $_.Options
        if ($OptionsTranslated -like '*IsGenerated*' -and -not $Force) {
            Write-Verbose "Set-WinADReplicationConnections - Skipping $($_.CN) automatically generated link"
        } else {
            Write-Verbose "Set-WinADReplicationConnections - Changing $($_.CN)"
            Set-ADObject $_ –replace @{ options = $($_.options -bor 8) } -Server $QueryServer
        }
    }
}