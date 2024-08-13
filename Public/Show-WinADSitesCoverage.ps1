function Show-WinADSitesCoverage {
    [alias('Show-WinADSiteCoverage')]
    [CmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [string[]] $ExcludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [string] $FilePath,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $PassThru
    )

    $Today = Get-Date
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    $SiteCoverage = Get-WinADSiteCoverage -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation

    New-HTML -TitleText "Active Directory Site Coverage" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString "," -BoolAsString
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        New-HTMLHeader {
            New-HTMLSection -Invisible {
                New-HTMLSection {
                    New-HTMLText -Text "Report generated on $($Today)" -Color Blue
                } -JustifyContent flex-start -Invisible
                New-HTMLSection {
                    New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                } -JustifyContent flex-end -Invisible
            }
        }

        New-HTMLSection -HeaderText "Active Directory Site Coverage" {
            New-HTMLTable -DataTable $SiteCoverage -Filtering {
                New-TableCondition -BackgroundColor CoralRed -ComparisonType number -Value 0 -Name NonExistingSiteCoverageCount -Operator gt -FailBackgroundColor MediumSeaGreen
                New-TableCondition -BackgroundColor CoralRed -ComparisonType number -Value 0 -Name NonExistingGCSiteCoverageCount -Operator gt -FailBackgroundColor MediumSeaGreen

                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name HasIssues -Operator eq -FailBackgroundColor MediumSeaGreen
                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name Error -Operator eq -FailBackgroundColor MediumSeaGreen
            } -DataTableID 'DT-CoverageSites' -ScrollX
        }


    } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
    if ($PassThru) {
        $SiteCoverage
    }
}