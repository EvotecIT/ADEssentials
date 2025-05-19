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

    .PARAMETER SummaryOnly
    Switch to indicate if only the summary should be returned.

    .PARAMETER SkipReplicationTopology
    Switch to indicate if the replication topology should be skipped.

    .PARAMETER SkipReplicationTopologyDiagram
    Switch to indicate if the replication topology diagram should be skipped.

    .PARAMETER SkipSitesSubnets
    Switch to indicate if the sites and subnets information should be skipped.

    .PARAMETER SkipSitesSubnetsDiagram
    Switch to indicate if the sites and subnets diagram should be skipped.

    .PARAMETER DiagramSitesSubnetsNodes
    Specifies the nodes to be included in the sites and subnets diagram. Valid values are 'DC' and 'Subnet'.
    Default is both.

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
        [switch] $PassThru,
        [switch] $SummaryOnly,
        [switch] $SkipReplicationTopology,
        [switch] $SkipReplicationTopologyDiagram,
        [switch] $SkipSitesSubnets,
        [switch] $SkipSitesSubnetsDiagram,
        [ValidateSet('DC', 'Subnet')][string[]] $DiagramSitesSubnetsNodes = @('DC', 'Subnet')
    )
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    Write-Verbose -Message "Show-WinADForestReplicationSummary - Getting Replication Summary"
    $ReplicationSummary = Get-WinADForestReplicationSummary -IncludeStatisticsVariable Statistics

    Write-Verbose -Message "Show-WinADForestReplicationSummary - Getting SiteLinks"
    $SiteLinks = Get-WinADSiteLinks
    Write-Verbose -Message "Show-WinADForestReplicationSummary - Getting SiteOptions"
    $SiteOptions = Get-WinADSiteOptions

    Write-Verbose -Message "Show-WinADForestReplicationSummary - Getting Replication Summary"
    if ($SummaryOnly) {
        $ReplicationOutput = Get-WinADForestReplication -Extended
    } else {
        $ReplicationOutput = Get-WinADForestReplication -Extended -All -SkipReplicationTopology:$SkipReplicationTopology.IsPresent -SkipSitesSubnets:$SkipSitesSubnets.IsPresent
    }
    # Lets build the report using the data from Get-WinADForestReplication
    $ReplicationData = $ReplicationOutput.ReplicationData
    $DCs = $ReplicationOutput.DCs
    $Links = $ReplicationOutput.Links
    $DCPartnerSummary = $ReplicationOutput.DCPartnerSummary
    $ReplicationMatrix = $ReplicationOutput.ReplicationMatrix
    $MatrixHeaders = $ReplicationOutput.MatrixHeaders
    $Sites = $ReplicationOutput.Sites
    $Subnets = $ReplicationOutput.Subnets

    Write-Verbose -Message "Show-WinADForestReplicationSummary - Generating HTML report"

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
            New-HTMLTab -TabName 'Overview' {
                if (-not $SummaryOnly) {
                    New-HTMLSection -HeaderText "Report Overview" {
                        New-HTMLPanel {
                            New-HTMLText -Text "About this Report" -FontSize 16px -FontWeight bold
                            New-HTMLText -Text "This report provides a comprehensive overview of Active Directory replication status across your forest. AD replication ensures that changes made to any domain controller are propagated to all other domain controllers in the environment. Monitoring replication is critical for maintaining a healthy Active Directory environment." -FontSize 12px

                            New-HTMLText -Text "What to Look For" -FontSize 16px -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Replication Failures: ", "Indicate domain controllers that cannot replicate changes" -FontWeight bold, normal
                                New-HTMLListItem -Text "High Delta Times: ", "Indicate replications not happening frequently enough" -FontWeight bold, normal
                                New-HTMLListItem -Text "Connectivity Issues: ", "Show potential network or configuration problems" -FontWeight bold, normal
                            } -FontSize 12px

                            New-HTMLText -Text "Report Sections" -FontSize 16px -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Replication Summary: ", "Overview statistics and health at a glance" -FontWeight bold, normal
                                New-HTMLListItem -Text "Replication Topology & Details: ", "Visual map of replication connections and detailed status" -FontWeight bold, normal
                                New-HTMLListItem -Text "Sites & Subnets: ", "Information about AD sites, subnets, and their configuration" -FontWeight bold, normal
                            } -FontSize 12px
                        }
                        New-HTMLPanel {
                            New-HTMLText -Text "Domain Controllers / Subnets & Sites" -FontSize 16px -FontWeight bold
                            # Create a few key metrics about the environment
                            New-HTMLList {
                                New-HTMLListItem -Text "Total Domain Controllers: ", $($DCs.Count) -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                                New-HTMLListItem -Text "Total AD Sites: ", $($Sites.Count) -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                                New-HTMLListItem -Text "Total Subnets: ", $($Subnets.Count) -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                            }
                            # Get DC count by site
                            $SiteCounts = @{}
                            foreach ($DC in $DCPartnerSummary) {
                                if ($DC.Site) {
                                    if (-not $SiteCounts.ContainsKey($DC.Site)) {
                                        $SiteCounts[$DC.Site] = 0
                                    }
                                    $SiteCounts[$DC.Site]++
                                }
                            }

                            # Create a small chart
                            if ($SiteCounts.Count -gt 0) {
                                New-HTMLChart {
                                    #New-ChartToolbar -Download
                                    #New-ChartBarOptions -Type bar
                                    foreach ($Site in $SiteCounts.Keys) {
                                        New-ChartBar -Name $Site -Value $SiteCounts[$Site]
                                    }
                                    #New-ChartBar -Name 'DCs per Site' -Value $SiteCounts.Values # -Label $SiteCounts.Keys
                                } -Title "Domain Controller Distribution by Site"
                            }
                        }
                    }
                }

                New-HTMLSection -HeaderText "Replication Health Summary" -CanCollapse {
                    # Create a cleaner visual layout for the statistics
                    New-HTMLPanel {
                        New-HTMLChart {
                            # Good vs Failed Replication
                            New-ChartToolbar -Download
                            New-ChartPie -Name 'Good replication' -Value $Statistics.Good -Color LightGreen
                            New-ChartPie -Name 'Failed replication' -Value $Statistics.Failures -Color Salmon
                        }
                    }
                    New-HTMLPanel {
                        # Keep the existing list but make it more compact
                        New-HTMLList {
                            New-HTMLListItem -Text "Servers with good replication: ", $($Statistics.Good) -Color Black, LightGreen -FontWeight normal, bold
                            New-HTMLListItem -Text "Servers with replication failures: ", $($Statistics.Failures) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Servers with replication delta over 24 hours: ", $($Statistics.DeltaOver24Hours) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Servers with replication delta over 12 hours: ", $($Statistics.DeltaOver12Hours) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Servers with replication delta over 6 hours: ", $($Statistics.DeltaOver6Hours) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Servers with replication delta over 3 hours: ", $($Statistics.DeltaOver3Hours) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Servers with replication delta over 1 hour: ", $($Statistics.DeltaOver1Hours) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Unique replication errors: ", $($Statistics.UniqueErrors.Count) -Color Black, Red -FontWeight normal, bold
                            New-HTMLListItem -Text "Unique replication warnings: ", $($Statistics.UniqueWarnings.Count) -Color Black, Yellow -FontWeight normal, bold
                        } -FontSize 12px

                        New-HTMLChart {
                            # Replication delays by timeframe
                            $DelayLabels = @('Good', '1 hours', '3-6 hours', '6-12 hours', '12-24 hours', 'Over 24 hours')
                            $DelayValues = @(
                                $Statistics.Good
                                ($Statistics.DeltaOver1Hours + $Statistics.DeltaOver3Hours),
                                ($Statistics.DeltaOver3Hours + $Statistics.DeltaOver6Hours),
                                ($Statistics.DeltaOver6Hours + $Statistics.DeltaOver12Hours),
                                ($Statistics.DeltaOver12Hours + $Statistics.DeltaOver24Hours),
                                $Statistics.DeltaOver24Hours
                            )
                            $DelayColors = @(
                                'LightGreen', 'Yellow', 'Gold', 'Orange', 'CoralRed', 'Salmon'
                            )
                            New-ChartBarOptions -Type bar
                            New-ChartLegend -Names $DelayLabels -Color $DelayColors
                            New-ChartBar -Name 'Replication Delays' -Value $DelayValues
                        }
                    }
                }

                # Add critical errors section if any exist
                if ($Statistics.Failures -gt 0 -or $Statistics.DeltaOver24Hours -gt 0) {
                    New-HTMLSection -HeaderText "Critical Issues Requiring Attention" -CanCollapse {
                        $CriticalIssues = $ReplicationData | Where-Object {
                            -not $_.Status -or
                            ($_.LastReplicationSuccess -and (New-TimeSpan -Start $_.LastReplicationSuccess -End (Get-Date)).TotalHours -gt 24)
                        } | Select-Object Server, ServerPartner, LastReplicationSuccess, ConsecutiveReplicationFailures, StatusMessage

                        if ($CriticalIssues) {
                            New-HTMLTable -DataTable $CriticalIssues -Filtering -PagingLength 5 {
                                New-HTMLTableCondition -Name 'ConsecutiveReplicationFailures' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Salmon
                            }
                        } else {
                            New-HTMLText -Text "No critical issues found despite statistics indicating potential problems. This may require further investigation." -Color Orange -FontWeight bold
                        }
                    }
                }

                New-HTMLSection -HeaderText "Replication Summary by Domain Controller" {
                    New-HTMLTable -DataTable $ReplicationSummary -DataTableID 'DT-ReplicationSummary' -ScrollX {
                        New-HTMLTableCondition -Name "Fails" -HighlightHeaders 'Fails', 'Total', 'PercentageError' -ComparisonType number -Operator gt 0 -BackgroundColor Salmon -FailBackgroundColor LightGreen
                    } -Filtering -PagingLength 50 -PagingOptions @(5, 10, 15, 25, 50, 100)
                }
                # Recommended actions section
                if ($Statistics.Failures -gt 0 -or $Statistics.DeltaOver24Hours -gt 0) {
                    New-HTMLText -Text "Recommended Actions" -FontSize 16px -FontWeight bold
                    New-HTMLPanel {
                        New-HTMLList {
                            New-HTMLListItem -Text "Check network connectivity between domain controllers with replication failures."
                            New-HTMLListItem -Text "Verify that all domain controllers have appropriate DNS resolution."
                            New-HTMLListItem -Text "Review site links and connection objects for misconfiguration."
                            New-HTMLListItem -Text "Check for sufficient bandwidth and appropriate replication schedules between sites."
                            New-HTMLListItem -Text "Resolve any lingering objects that could impact replication."
                            New-HTMLListItem -Text "Review the Replication Topology tab for more detailed insights."
                        } -FontSize 12px
                    } -Invisible
                } else {
                    New-HTMLPanel {
                        New-HTMLText -Text "No replication issues detected in this environment." -Color Green -FontWeight bold
                    } -Invisible
                }
            }
            if (-not $SummaryOnly) {
                if (-not $SkipReplicationTopology) {
                    New-HTMLTab -TabName 'Replication Topology & Details' {
                        if (-not $SkipReplicationTopologyDiagram) {
                            New-HTMLSection -HeaderText 'Replication Topology' {
                                New-HTMLDiagram -Height 'calc(50vh)' {
                                    New-DiagramEvent -ID 'DT-ReplicationDetails' -ColumnID 0
                                    New-DiagramEvent -ID 'DT-ReplicationMatrix' -ColumnID 0
                                    New-DiagramEvent -ID 'DT-DCPartnerSummary' -ColumnID 0
                                    New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion

                                    # Add Nodes (Domain Controllers)
                                    foreach ($DCName in $DCs.Keys) {
                                        $DCInfo = $DCs[$DCName]
                                        # $NodeLabel = "$($DCInfo.Label)`n$($DCInfo.IP)" # Add IP to label
                                        $NodeLabel = $DCInfo.Label
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
                                        New-DiagramNode -Id $DCName -Label $NodeLabel -ColorBackground $NodeColor -Shape box
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
                        }
                        New-HTMLSection -HeaderText 'Domain Controller Replication Partners' {
                            New-HTMLTable -DataTable $DCPartnerSummary -DataTableID 'DT-DCPartnerSummary' -Filtering -ScrollX {
                                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Healthy' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                            }
                        }

                        New-HTMLSection -HeaderText 'Replication Matrix' {
                            New-HTMLPanel {
                                New-HTMLTable -DataTable $ReplicationMatrix {
                                    New-HTMLTableHeader -Names $MatrixHeaders -Title "Domain Controller Inbound Partners"
                                    foreach ($Header in $MatrixHeaders) {
                                        New-HTMLTableCondition -Value '✓' -ComparisonType string -Operator eq -BackgroundColor LightGreen -Name $Header
                                        New-HTMLTableCondition -Value '✗' -ComparisonType string -Operator eq -BackgroundColor Salmon -Name $Header
                                        New-HTMLTableCondition -Value '-' -ComparisonType string -Operator eq -BackgroundColor LightYellow -Name $Header
                                    }
                                } -ScrollX -DataTableID 'DT-ReplicationMatrix' -Filtering
                            }
                        }

                        New-HTMLSection -HeaderText 'Detailed Replication Status' {
                            # Add conditional formatting for Status column
                            New-HTMLTable -DataTable $ReplicationData -DataTableID 'DT-ReplicationDetails' -Filtering -ScrollX {
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
                }
                if (-not $SkipSitesSubnets) {
                    New-HTMLTab -TabName 'Sites & Subnets' {
                        if (-not $SkipSitesSubnetsDiagram) {
                            New-HTMLSection -HeaderText 'Sites & Subnets Diagram' {
                                New-HTMLDiagram -Height 'calc(50vh)' {
                                    New-DiagramEvent -ID 'DT-StandardSites' -ColumnID 0
                                    New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
                                    foreach ($Site in $Sites) {
                                        New-DiagramNode -Id $Site.DistinguishedName -Label $Site.Name -Image 'https://cdn-icons-png.flaticon.com/512/1104/1104991.png' -ImageType squareImage
                                        if ($DiagramSitesSubnetsNodes -contains 'Subnet') {
                                            foreach ($Subnet in $Site.Subnets) {
                                                New-DiagramNode -Id $Subnet -Label $Subnet -Image 'https://cdn-icons-png.flaticon.com/512/1674/1674968.png' -ImageType squareImage
                                                New-DiagramEdge -From $Subnet -To $Site.DistinguishedName
                                            }
                                        }
                                        if ($DiagramSitesSubnetsNodes -contains 'DC') {
                                            foreach ($DC in $Site.DomainControllers) {
                                                New-DiagramNode -Id $DC -Label $DC -Image 'https://cdn-icons-png.flaticon.com/512/1383/1383395.png' -ImageType squareImage
                                                New-DiagramEdge -From $DC -To $Site.DistinguishedName
                                            }
                                        }
                                    }
                                    # foreach ($R in $CacheReplication.Values) {
                                    #     if ($R.ConsecutiveReplicationFailures -gt 0) {
                                    #         $Color = 'CoralRed'
                                    #     } else {
                                    #         $Color = 'MediumSeaGreen'
                                    #     }
                                    #     New-DiagramEdge -From $R.Server -To $R.ServerPartner -Color $Color -ArrowsToEnabled -ColorOpacity 0.5
                                    # }
                                } -EnableFiltering -EnableFilteringButton
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
                }
            }
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
            EmailBody          = EmailBody {
                EmailText -Text "Dear ", "AD Team," -LineBreak
                EmailText -Text "Upon reviewing the resuls of replication I've found: "
                EmailList {
                    EmailListItem -Text "Servers with good replication: ", $($Statistics.Good) -Color Black, SpringGreen -FontWeight normal, bold
                    EmailListItem -Text "Servers with replication failures: ", $($Statistics.Failures) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Servers with replication delta over 24 hours: ", $($Statistics.DeltaOver24Hours) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Servers with replication delta over 12 hours: ", $($Statistics.DeltaOver12Hours) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Servers with replication delta over 6 hours: ", $($Statistics.DeltaOver6Hours) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Servers with replication delta over 3 hours: ", $($Statistics.DeltaOver3Hours) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Servers with replication delta over 1 hour: ", $($Statistics.DeltaOver1Hours) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Unique replication errors: ", $($Statistics.UniqueErrors.Count) -Color Black, Red -FontWeight normal, bold
                    EmailListItem -Text "Unique replication warnings: ", $($Statistics.UniqueWarnings.Count) -Color Black, Yellow -FontWeight normal, bold
                }

                if ($Statistics.UniqueErrors.Count -gt 0) {
                    EmailText -Text "Unique replication errors:"
                    EmailList {
                        foreach ($ErrorText in $Statistics.UniqueErrors) {
                            EmailListItem -Text $ErrorText
                        }
                    }
                } else {
                    EmailText -Text "It seems you're doing a great job! Keep it up! 😊" -LineBreak
                }

                EmailText -Text "For more details please check the table below:"

                EmailTable -DataTable $ReplicationSummary {
                    EmailTableCondition -Inline -Name "Fail" -HighlightHeaders 'Fails', 'Total', 'PercentageError' -ComparisonType number -Operator gt 0 -BackGroundColor Salmon -FailBackgroundColor SpringGreen
                } -HideFooter

                EmailText -LineBreak
                EmailText -Text "Kind regards,"
                EmailText -Text "Your automation friend"
            }
        }
    }
}