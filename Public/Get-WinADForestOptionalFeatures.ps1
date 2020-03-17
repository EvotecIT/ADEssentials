function Get-WinADForestOptionalFeatures {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [Array] $ComputerProperties,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    if (-not $ComputerProperties) {
        $ComputerProperties = Get-WinADForestSchemaProperties -Schema 'Computers' -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    }
    $LapsProperties = 'ms-Mcs-AdmPwd'
    $OptionalFeatures = $(Get-ADOptionalFeature -Filter * )
    $Optional = [ordered]@{
        'Recycle Bin Enabled'                          = $false
        'Privileged Access Management Feature Enabled' = $false
        'Laps Enabled'                                 = ($ComputerProperties.Name -contains $LapsProperties)
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