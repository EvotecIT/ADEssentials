function Set-WinADReplicationConnections {
    <#
    .SYNOPSIS
    Modifies the replication connections within an Active Directory forest.

    .DESCRIPTION
    This cmdlet updates the replication connections within a specified Active Directory forest. It can be used to enable or disable specific connection options for each connection. The cmdlet supports modifying connections that are automatically generated or manually created.

    .PARAMETER Forest
    Specifies the name of the Active Directory forest for which to modify the replication connections.

    .PARAMETER Force
    Forces the modification of all replication connections, including those that are automatically generated.

    .PARAMETER ExtendedForestInformation
    Provides additional information about the forest that can be used to facilitate the operation.

    .EXAMPLE
    Set-WinADReplicationConnections -Forest 'example.com' -Force
    This example modifies all replication connections within the 'example.com' forest, including automatically generated ones.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and configured.
    #>
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
    $Connections = Get-ADObject -Searchbase $NamingContext -LDAPFilter "(objectCategory=ntDSConnection)" -Properties * -Server $QueryServer
    foreach ($_ in $Connections) {
        $OptionsTranslated = [ConnectionOption] $_.Options
        if ($OptionsTranslated -like '*IsGenerated*' -and -not $Force) {
            Write-Verbose "Set-WinADReplicationConnections - Skipping $($_.CN) automatically generated link"
        } else {
            Write-Verbose "Set-WinADReplicationConnections - Changing $($_.CN)"
            Set-ADObject $_ -replace @{ options = $($_.options -bor 8) } -Server $QueryServer
        }
    }
}