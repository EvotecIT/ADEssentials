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

    $SiteLinks = Get-WinADSiteLinks
    $SiteOptions = Get-WinADSiteOptions

    $ReplicationOutput = Get-WinADForestReplication -Extended -All
    # Lets build the report using the data from Get-WinADForestReplication
    $ReplicationData = $ReplicationOutput.ReplicationData
    $DCs = $ReplicationOutput.DCs
    $Links = $ReplicationOutput.Links
    $DCPartnerSummary = $ReplicationOutput.DCPartnerSummary
    $ReplicationMatrix = $ReplicationOutput.ReplicationMatrix
    $MatrixHeaders = $ReplicationOutput.MatrixHeaders
    $Sites = $ReplicationOutput.Sites
    $Subnets = $ReplicationOutput.Subnets

    New-HTML {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString ", " -BoolAsString
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
            New-HTMLTab -TabName 'Replication Topology & Details' {
                New-HTMLSection -HeaderText 'Replication Topology' {
                    New-HTMLDiagram -Height 'calc(50vh)' {
                        New-DiagramEvent -ID 'DT-ReplicationDetails' -ColumnID 0
                        New-DiagramEvent -ID 'DT-ReplicationMatrix' -ColumnID 0
                        New-DiagramEvent -ID 'DT-DCPartnerSummary' -ColumnID 0
                        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion

                        # Add Nodes (Domain Controllers)
                        foreach ($DCName in $DCs.Keys) {
                            $DCInfo = $DCs[$DCName]
                            $NodeLabel = "$($DCInfo.Label)`n$($DCInfo.IP)" # Add IP to label
                            $NodeColor = if ($DCInfo.Status) { "#c5e8cd" } else { "#f7bec3" } # Light green or light red
                            $SiteName = ""
                            # Add site information if available
                            foreach ($DCPartner in $DCPartnerSummary) {
                                if ($DCPartner.DomainController -eq $DCName -and $DCPartner.Site) {
                                    $SiteName = $DCPartner.Site
                                    break
                                }
                            }
                            $NodeTitle = "DC: $($DCInfo.Label)"
                            if ($SiteName) {
                                $NodeTitle += " (Site: $SiteName)"
                            }
                            #New-DiagramNode -Id $DCName -Label $NodeLabel -Title $NodeTitle -ColorBackground $NodeColor
                            New-DiagramNode -Id $DCName -Label $DCInfo.Label -ColorBackground $NodeColor -Shape box
                        }

                        # Track which connections we've already processed to avoid duplicates
                        $ProcessedLinks = @{}

                        # Directly use the Links collection to create edges between DCs
                        foreach ($Link in $Links) {
                            $FromDC = $Link.From
                            $ToDC = $Link.To
                            $LinkKey = "$FromDC-$ToDC"
                            $ReverseKey = "$ToDC-$FromDC"

                            # Skip if we've already processed this link
                            if ($ProcessedLinks.ContainsKey($LinkKey) -or $ProcessedLinks.ContainsKey($ReverseKey)) {
                                continue
                            }

                            # Mark as processed
                            $ProcessedLinks[$LinkKey] = $true

                            # Determine if it's bidirectional
                            $Bidirectional = $false
                            $ReverseLink = $Links | Where-Object { $_.From -eq $ToDC -and $_.To -eq $FromDC } | Select-Object -First 1
                            if ($ReverseLink) {
                                $Bidirectional = $true
                                # Mark reverse link as processed too
                                $ProcessedLinks[$ReverseKey] = $true
                            }

                            # Determine status and color
                            $EdgeColor = if ($Link.Status) { 'Green' } else { 'Red' }
                            $EdgeDashes = -not $Link.Status # Dashed line for failures

                            if ($Bidirectional) {
                                # Create bidirectional edge
                                New-DiagramEdge -From $FromDC -To $ToDC -Color $EdgeColor -ArrowsToEnabled -ArrowsFromEnabled -Dashes $EdgeDashes -Label "Both" -FontAlign middle
                            } else {
                                # Create directional edge
                                New-DiagramEdge -From $ToDC -To $FromDC -Color $EdgeColor -ArrowsToEnabled -Dashes $EdgeDashes -Label "One-way" -FontAlign middle
                            }
                        }
                    } -EnableFiltering -EnableFilteringButton
                }
                New-HTMLSection -HeaderText 'Domain Controller Replication Partners' {
                    New-HTMLTable -DataTable $DCPartnerSummary -DataTableID 'DT-DCPartnerSummary' -Filtering -ScrollX {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Issues Detected' -BackgroundColor '#f7bec3' -Row
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Healthy' -BackgroundColor '#c5e8cd' -Row
                    }
                }

                New-HTMLSection -HeaderText 'Replication Matrix' {
                    New-HTMLPanel {
                        New-HTMLTable -DataTable $ReplicationMatrix -HideButtons -HideFooter -FixedHeader {
                            New-HTMLTableHeader -Names $MatrixHeaders -Title "Domain Controller Inbound Partners"
                            foreach ($Header in $MatrixHeaders) {
                                New-HTMLTableCondition -Value '✓' -ComparisonType string -Operator eq -BackgroundColor LightGreen -Name $Header
                                New-HTMLTableCondition -Value '✗' -ComparisonType string -Operator eq -BackgroundColor Salmon -Name $Header
                                New-HTMLTableCondition -Value '-' -ComparisonType string -Operator eq -BackgroundColor LightYellow -Name $Header
                            }

                        } -ScrollX -DataTableID 'DT-ReplicationMatrix'
                    }
                }

                New-HTMLSection -HeaderText 'Detailed Replication Status' {
                    # Add conditional formatting for Status column
                    New-HTMLTable -DataTable $ReplicationData -DataTableID 'DT-ReplicationDetails' -Filtering -ScrollX -ScrollY {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value $false -BackgroundColor '#f7bec3' -Row

                        New-HTMLTableCondition -Name 'LastReplicationResult' -ComparisonType string -Operator eq -Value "0" -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        New-HTMLTableCondition -Name 'ConsecutiveReplicationFailures' -ComparisonType string -Operator eq -Value "0" -BackgroundColor LightGreen -FailBackgroundColor Salmon

                        $Properties = @('ScheduledSync', 'SyncOnStartup')
                        foreach ($Property in $Properties) {
                            New-HTMLTableCondition -Name $Property -ComparisonType string -Operator eq -Value "True" -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        }
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value "True" -BackgroundColor LightGreen -FailBackgroundColor Salmon -HighlightHeaders 'Status', 'StatusMessage'
                        New-HTMLTableCondition -Name 'Writable' -ComparisonType string -Operator eq -Value "True" -BackgroundColor LightGreen -FailBackgroundColor LightYellow
                    }
                }
            }
            New-HTMLTab -TabName 'Sites & Subnets' {
                New-HTMLSection -HeaderText 'Organization Diagram' {
                    New-HTMLDiagram -Height 'calc(50vh)' {
                        New-DiagramEvent -ID 'DT-StandardSites' -ColumnID 0
                        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
                        foreach ($Site in $Sites) {
                            New-DiagramNode -Id $Site.DistinguishedName -Label $Site.Name -Image 'https://cdn-icons-png.flaticon.com/512/1104/1104991.png'
                            foreach ($Subnet in $Site.Subnets) {
                                New-DiagramNode -Id $Subnet -Label $Subnet -Image 'https://cdn-icons-png.flaticon.com/512/1674/1674968.png'
                                New-DiagramEdge -From $Subnet -To $Site.DistinguishedName
                            }
                            foreach ($DC in $Site.DomainControllers) {
                                New-DiagramNode -Id $DC -Label $DC -Image 'https://cdn-icons-png.flaticon.com/512/1383/1383395.png'
                                New-DiagramEdge -From $DC -To $Site.DistinguishedName
                            }
                        }
                        foreach ($R in $CacheReplication.Values) {
                            if ($R.ConsecutiveReplicationFailures -gt 0) {
                                $Color = 'CoralRed'
                            } else {
                                $Color = 'MediumSeaGreen'
                            }
                            New-DiagramEdge -From $R.Server -To $R.ServerPartner -Color $Color -ArrowsToEnabled -ColorOpacity 0.5
                        }
                    }
                }
                New-HTMLSection -HeaderText 'Sites' {
                    New-HTMLTable -DataTable $Sites -DataTableID 'DT-Sites' -Filtering -ScrollX {
                        New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType number -Value 0 -Name SubnetsCount -Operator gt
                        New-TableCondition -BackgroundColor CoralRed -ComparisonType number -Value 0 -Name SubnetsCount -Operator eq
                    }
                }
                New-HTMLSection -HeaderText 'Subnets' {
                    New-HTMLTable -DataTable $Subnets -DataTableID 'DT-Subnets' -Filtering -ScrollX {
                        New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value $true -Name SiteStatus -FailBackgroundColor CoralRed
                        New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value $false -Name Overlap -FailBackgroundColor CoralRed
                    }
                }
                New-HTMLSection -HeaderText 'Site Links' {
                    New-HTMLTable -DataTable $SiteLinks -DataTableID 'DT-SiteLinks' -Filtering -ScrollX {

                    }
                }
                New-HTMLSection -HeaderText 'Site Options' {
                    New-HTMLTable -DataTable $SiteOptions -DataTableID 'DT-SiteOptions' -Filtering -ScrollX {

                    }
                }
            }
            # New-HTMLTab -TabName 'Errors & Warnings' {
            #     New-HTMLSection -HeaderText 'Errors and Warnings During Data Collection' {
            #         # Placeholder: Need to capture errors from Get-WinADForestReplication if possible
            #         # For now, display errors captured by the original function's try/catch
            #         $Errors = $ReplicationData | Where-Object { $_.StatusMessage -like '*Error*' -or $_.Status -eq $false } | Select-Object Server, ServerPartner, StatusMessage, LastReplicationAttempt, ConsecutiveReplicationFailures
            #         if ($Errors) {
            #             New-HTMLTable -DataTable $Errors -DataTableID 'DT-ReplicationErrors' -Filtering -ScrollX
            #         } else {
            #             New-HTMLText -Text "No significant errors detected or reported by Get-WinADForestReplication."
            #         }
            #     }
            # }
        }
    } -FilePath $FilePath -ShowHTML:(-not $HideHTML) -Online:$Online


    if ($PassThru) {
        [ordered] @{
            ReplicationSummary = $ReplicationSummary
            Statistics         = $Statistics
            ReplicationData    = $ReplicationData
            DCs                = $DCs
            Links              = $Links
            DCPartnerSummary   = $DCPartnerSummary
            ReplicationMatrix  = $ReplicationMatrix
        }
    }
}