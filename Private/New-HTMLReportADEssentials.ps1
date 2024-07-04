function New-HTMLReportADEssentials {
    <#
    .SYNOPSIS
    Generates an HTML report for ADEssentials.

    .DESCRIPTION
    This function generates an HTML report for ADEssentials based on the specified type. It provides options to generate the report online and hide the HTML output.

    .PARAMETER Type
    Specifies the type of report to generate.

    .PARAMETER Online
    Switch to indicate if the report should be generated online.

    .PARAMETER HideHTML
    Switch to hide the HTML output.

    .PARAMETER FilePath
    Specifies the file path where the report will be saved.

    .EXAMPLE
    New-HTMLReportADEssentials -Type @('Type1') -Online -HideHTML -FilePath "C:\Reports\"
    Generates an HTML report for 'Type1', hides the HTML output, and saves the report in the specified file path.

    .NOTES
    Ensure that the necessary permissions are in place to generate the report.
    #>
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