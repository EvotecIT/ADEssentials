function Get-WinADForestOptionalFeatures {
    <#
    .SYNOPSIS
    Retrieves optional features information for a specified Active Directory forest.

    .DESCRIPTION
    Retrieves detailed information about optional features within the specified Active Directory forest.

    .PARAMETER Forest
    Specifies the target forest to retrieve optional features information from.

    .PARAMETER ComputerProperties
    Specifies an array of computer properties to check for specific features.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest for retrieving optional features.

    .EXAMPLE
    Get-WinADForestOptionalFeatures -Forest "example.com" -ComputerProperties @("ms-Mcs-AdmPwd", "msLAPS-Password")

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [Array] $ComputerProperties,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    if (-not $ComputerProperties) {
        $ComputerProperties = Get-WinADForestSchemaProperties -Schema 'Computers' -Forest $Forest -ExtendedForestInformation $ForestInformation
    }
    $QueryServer = $ForestInformation['QueryServers']["Forest"].HostName[0]
    $LapsProperties = 'ms-Mcs-AdmPwd'
    $WindowsLapsProperties = 'msLAPS-Password'
    $OptionalFeatures = $(Get-ADOptionalFeature -Filter "*" -Server $QueryServer)
    $Optional = [ordered]@{
        'Recycle Bin Enabled'                          = $false
        'Privileged Access Management Feature Enabled' = $false
        'LAPS Enabled'                                 = ($ComputerProperties.Name -contains $LapsProperties)
        'Windows LAPS Enabled'                         = ($ComputerProperties.Name -contains $WindowsLapsProperties)
    }
    foreach ($Feature in $OptionalFeatures) {
        if ($Feature.Name -eq 'Recycle Bin Feature') {
            $Optional.'Recycle Bin Enabled' = $Feature.EnabledScopes.Count -gt 0
        }
        if ($Feature.Name -eq 'Privileged Access Management Feature') {
            $Optional.'Privileged Access Management Feature Enabled' = $Feature.EnabledScopes.Count -gt 0
        }
    }
    $Optional
}