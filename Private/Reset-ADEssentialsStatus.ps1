function Reset-ADEssentialsStatus {
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