function Show-WinADForestReplicationSummary {
    <#
    .SYNOPSIS
    Generates an HTML report for Active Directory replication summary.

    .DESCRIPTION
    This function generates an HTML report for Active Directory replication summary using the Get-WinADForestReplicationSummary function.
    The report includes statistics and detailed replication information.

    .PARAMETER FilePath
    The path where the HTML report will be saved.

    .PARAMETER Online
    Switch to indicate if the report should be generated with online resources.

    .PARAMETER HideHTML
    Switch to indicate if the HTML report should be hidden after generation.

    .PARAMETER PassThru
    Switch to return the replication summary and statistics as output.

    .EXAMPLE
    Show-WinADForestReplicationSummary -FilePath "C:\Reports\ReplicationSummary.html"

    .EXAMPLE
    Show-WinADForestReplicationSummary -Online -HideHTML

    .EXAMPLE
    Show-WinADForestReplicationSummary -PassThru

    .NOTES
    #>
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $PassThru
    )
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }

    $ReplicationSummary = Get-WinADForestReplicationSummary -IncludeStatisticsVariable Statistics

    New-HTML {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString "," -BoolAsString
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

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

        New-HTMLSection -HeaderText "Summary" {
            New-HTMLList {
                New-HTMLListItem -Text "Servers with good replication: ", $($Statistics.Good) -Color Black, SpringGreen -FontWeight normal, bold
                New-HTMLListItem -Text "Servers with replication failures: ", $($Statistics.Failures) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Servers with replication delta over 24 hours: ", $($Statistics.DeltaOver24Hours) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Servers with replication delta over 12 hours: ", $($Statistics.DeltaOver12Hours) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Servers with replication delta over 6 hours: ", $($Statistics.DeltaOver6Hours) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Servers with replication delta over 3 hours: ", $($Statistics.DeltaOver3Hours) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Servers with replication delta over 1 hour: ", $($Statistics.DeltaOver1Hours) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Unique replication errors: ", $($Statistics.UniqueErrors.Count) -Color Black, Red -FontWeight normal, bold
            }
        }

        New-HTMLSection -HeaderText "Replication Summary" {
            New-HTMLTable -DataTable $ReplicationSummary -DataTableID 'DT-ReplicationSummary' -ScrollX {
                New-HTMLTableCondition -Inline -Name "Fail" -HighlightHeaders 'Fails', 'Total', 'PercentageError' -ComparisonType number -Operator gt 0 -BackgroundColor Salmon -FailBackgroundColor SpringGreen
            } -Filtering -PagingLength 50 -PagingOptions @(5, 10, 15, 25, 50, 100)
        }
    } -FilePath $FilePath -ShowHTML:(-not $HideHTML)


    if ($PassThru) {
        [ordered] @{
            ReplicationSummary = $ReplicationSummary
            Statistics         = $Statistics
        }
    }
}