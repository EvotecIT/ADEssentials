function Reset-ADEssentialsStatus {
    <#
    .SYNOPSIS
    Resets the status of ADEssentialsConfiguration based on DefaultTypes.

    .DESCRIPTION
    This function resets the status of ADEssentialsConfiguration based on DefaultTypes. It enables the types specified in DefaultTypes and disables the rest.

    .PARAMETER DefaultTypes
    Specifies the default types to be enabled.

    .EXAMPLE
    Reset-ADEssentialsStatus -DefaultTypes 'Type1', 'Type2'
    Resets the status of ADEssentialsConfiguration enabling 'Type1' and 'Type2' and disabling the rest.

    .NOTES
    Author: [Author Name]
    Date: [Date]
    Version: [Version]
    #>
    [cmdletBinding()]
    param(

    )
    if (-not $Script:DefaultTypes) {
        $Script:DefaultTypes = foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
            if ($Script:ADEssentialsConfiguration[$T].Enabled) {
                $T
            }
        }
    } else {
        foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
            if ($Script:ADEssentialsConfiguration[$T]) {
                $Script:ADEssentialsConfiguration[$T]['Enabled'] = $false
            }
        }
        foreach ($T in $Script:DefaultTypes) {
            if ($Script:ADEssentialsConfiguration[$T]) {
                $Script:ADEssentialsConfiguration[$T]['Enabled'] = $true
            }
        }
    }
}