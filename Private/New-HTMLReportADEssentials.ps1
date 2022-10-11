function New-HTMLReportADEssentials {
    [cmdletBinding()]
    param(
        [Array] $Type,
        [switch] $Online,
        [switch] $HideHTML,
        [string] $FilePath
    )

    New-HTML -Author 'Przemysław Kłys' -TitleText 'ADEssentials Report' {
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLPanelStyle -BorderRadius 0px
        New-HTMLTableOption -DataStore JavaScript -BoolAsString -ArrayJoinString ', ' -ArrayJoin

        New-HTMLHeader {
            New-HTMLSection -Invisible {
                New-HTMLSection {
                    New-HTMLText -Text "Report generated on $(Get-Date)" -Color Blue
                } -JustifyContent flex-start -Invisible
                New-HTMLSection {
                    New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                } -JustifyContent flex-end -Invisible
            }
        }

        if ($Type.Count -eq 1) {
            foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
                if ($Script:ADEssentialsConfiguration[$T].Enabled -eq $true) {
                    if ($Script:ADEssentialsConfiguration[$T]['Summary']) {
                        $Script:Reporting[$T]['Summary'] = Invoke-Command -ScriptBlock $Script:ADEssentialsConfiguration[$T]['Summary']
                    }
                    & $Script:ADEssentialsConfiguration[$T]['Solution']
                }
            }
        } else {
            foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
                if ($Script:ADEssentialsConfiguration[$T].Enabled -eq $true) {
                    if ($Script:ADEssentialsConfiguration[$T]['Summary']) {
                        $Script:Reporting[$T]['Summary'] = Invoke-Command -ScriptBlock $Script:ADEssentialsConfiguration[$T]['Summary']
                    }
                    New-HTMLTab -Name $Script:ADEssentialsConfiguration[$T]['Name'] {
                        & $Script:ADEssentialsConfiguration[$T]['Solution']
                    }
                }
            }
        }
    } -Online:$Online.IsPresent -ShowHTML:(-not $HideHTML) -FilePath $FilePath
}