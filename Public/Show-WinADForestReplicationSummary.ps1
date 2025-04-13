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

    $ReplicationData = Get-WinADForestReplication -Extended

    $DCs = @{}
    $Links = [System.Collections.Generic.List[object]]::new()

    foreach ($RepLink in $ReplicationData) {
        # Ensure Server and Partner are added as nodes
        if ($RepLink.Server -and -not $DCs.ContainsKey($RepLink.Server)) {
            $DCs[$RepLink.Server] = @{ Label = $RepLink.Server; IP = $RepLink.ServerIPV4 }
        }
        if ($RepLink.ServerPartner -and -not $DCs.ContainsKey($RepLink.ServerPartner)) {
            # Attempt to resolve partner IP if not directly available (may require another lookup or be less reliable)
            $PartnerIP = $RepLink.ServerPartnerIPV4 # Use the IP already resolved by Get-WinADForestReplication
            $DCs[$RepLink.ServerPartner] = @{ Label = $RepLink.ServerPartner; IP = $PartnerIP }
        }

        # Add the link (handle potential duplicates if needed, maybe group by Server/Partner/Partition?)
        # For simplicity now, add each link found. Diagram might show multiple lines if partitions differ.
        if ($RepLink.Server -and $RepLink.ServerPartner) {
            $Links.Add(@{
                    From        = $RepLink.Server
                    To          = $RepLink.ServerPartner
                    Status      = $RepLink.Status
                    Fails       = $RepLink.ConsecutiveReplicationFailures
                    LastSuccess = $RepLink.LastReplicationSuccess
                    Partition   = $RepLink.Partition
                })
        }
    }
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
        New-HTMLTabPanel {
            New-HTMLTab -TabName 'Replication Diagram' {
                New-HTMLSection -HeaderText 'Replication Topology' {
                    New-HTMLDiagram -Height 'calc(50vh)' {
                        New-DiagramEvent -ID 'DT-ReplicationDetails' -ColumnID 0
                        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion

                        # Add Nodes (Domain Controllers)
                        foreach ($DCName in $DCs.Keys) {
                            $DCInfo = $DCs[$DCName]
                            $NodeLabel = "$($DCInfo.Label)`n$($DCInfo.IP)" # Add IP to label
                            # Consider adding an image based on DC type (RODC/RWDC) if info is available
                            New-DiagramNode -Id $DCName -Label $NodeLabel -Title "DC: $($DCInfo.Label)" # Tooltip
                        }

                        # Add Edges (Replication Links)
                        foreach ($Link in $Links) {
                            $EdgeColor = if ($Link.Status) { 'Green' } else { 'Red' }
                            #$EdgeTitle = "From: $($Link.From) To: $($Link.To)`nPartition: $($Link.Partition)`nStatus: $($Link.Status)`nFails: $($Link.Fails)`nLast Success: $($Link.LastSuccess)"
                            $EdgeTitle = ""
                            $EdgeDashes = if (-not $Link.Status) { $true } else { $false } # Dashed line for failures

                            New-DiagramEdge -From $Link.From -To $Link.To -Color $EdgeColor -ArrowsToEnabled -Label $EdgeTitle -Dashes $EdgeDashes
                        }
                    } -EnableFiltering -EnableFilteringButton #-PhysicsEnabled # Consider physics options if needed
                }
                New-HTMLSection -HeaderText 'Detailed Replication Status' {
                    # Add conditional formatting for Status column?
                    New-HTMLTable -DataTable $ReplicationData -DataTableID 'DT-ReplicationDetails' -Filtering -ScrollX -ScrollY
                }
            }
            New-HTMLTab -TabName 'Replication Summary' {
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
                        New-HTMLListItem -Text "Unique replication warnings: ", $($Statistics.UniqueWarnings.Count) -Color Black, Yellow -FontWeight normal, bold
                    }
                }
                New-HTMLSection -HeaderText "Replication Summary" {
                    New-HTMLTable -DataTable $ReplicationSummary -DataTableID 'DT-ReplicationSummary' -ScrollX {
                        New-HTMLTableCondition -Inline -Name "Fail" -HighlightHeaders 'Fails', 'Total', 'PercentageError' -ComparisonType number -Operator gt 0 -BackgroundColor Salmon -FailBackgroundColor SpringGreen
                    } -Filtering -PagingLength 50 -PagingOptions @(5, 10, 15, 25, 50, 100)
                }
            }
            New-HTMLTab -TabName 'Errors & Warnings' {
                New-HTMLSection -HeaderText 'Errors and Warnings During Data Collection' {
                    # Placeholder: Need to capture errors from Get-WinADForestReplication if possible
                    # For now, display errors captured by the original function's try/catch
                    $Errors = $ReplicationData | Where-Object { $_.StatusMessage -like '*Error*' -or $_.Status -eq $false } | Select-Object Server, ServerPartner, StatusMessage, LastReplicationAttempt, ConsecutiveReplicationFailures
                    if ($Errors) {
                        New-HTMLTable -DataTable $Errors -DataTableID 'DT-ReplicationErrors' -Filtering -ScrollX
                    } else {
                        New-HTMLText -Text "No significant errors detected or reported by Get-WinADForestReplication."
                    }
                }
            }
        }
    } -FilePath $FilePath -ShowHTML:(-not $HideHTML)


    if ($PassThru) {
        [ordered] @{
            ReplicationSummary = $ReplicationSummary
            Statistics         = $Statistics
        }
    }
}