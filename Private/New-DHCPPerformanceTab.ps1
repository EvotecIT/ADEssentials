function New-DHCPPerformanceTab {
    <#
    .SYNOPSIS
    Creates the Performance tab content for DHCP HTML report.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    New-HTMLTab -TabName 'Performance' {
        # Server Statistics with enhanced visuals
        if ($DHCPData.ServerStatistics.Count -gt 0) {
            New-HTMLSection -HeaderText "📊 DHCP Server Performance Analytics" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Performance Metrics Dashboard" -FontSize 18pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Real-time analysis of DHCP server performance, request handling, and capacity utilization. Monitor these metrics to ensure optimal service delivery." -FontSize 12pt -Color DarkGray

                    # Performance summary across all servers
                    $TotalDiscovers = ($DHCPData.ServerStatistics | Measure-Object -Property Discovers -Sum).Sum
                    $TotalOffers = ($DHCPData.ServerStatistics | Measure-Object -Property Offers -Sum).Sum
                    $TotalAcks = ($DHCPData.ServerStatistics | Measure-Object -Property Acks -Sum).Sum
                    $TotalNaks = ($DHCPData.ServerStatistics | Measure-Object -Property Naks -Sum).Sum
                    $SuccessRate = if ($TotalDiscovers -gt 0) { [Math]::Round(($TotalAcks / $TotalDiscovers) * 100, 2) } else { 0 }

                    New-HTMLSection -HeaderText "Infrastructure Performance Overview" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "Total Requests" -Number $TotalDiscovers.ToString("N0") -Subtitle "DHCP Discovers" -Icon "📡" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "Successful Leases" -Number $TotalAcks.ToString("N0") -Subtitle "Acks Sent" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen
                        New-HTMLInfoCard -Title "Success Rate" -Number "$SuccessRate%" -Subtitle "Efficiency" -Icon "🎯" -TitleColor Purple -NumberColor DarkMagenta

                        if ($TotalNaks -gt 100) {
                            New-HTMLInfoCard -Title "Rejections" -Number $TotalNaks.ToString("N0") -Subtitle "NAKs (High)" -Icon "❌" -TitleColor Crimson -NumberColor DarkRed -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                        } else {
                            New-HTMLInfoCard -Title "Rejections" -Number $TotalNaks.ToString("N0") -Subtitle "NAKs (Normal)" -Icon "📊" -TitleColor Orange -NumberColor DarkOrange
                        }
                    }

                    New-HTMLTable -DataTable $DHCPData.ServerStatistics -Filtering {
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Red -Color White -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'ScopesWithDelay' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Yellow -HighlightHeaders 'ScopesWithDelay'
                        New-HTMLTableCondition -Name 'Naks' -ComparisonType number -Operator gt -Value 100 -BackgroundColor Orange -HighlightHeaders 'Naks'
                        New-HTMLTableCondition -Name 'Declines' -ComparisonType number -Operator gt -Value 10 -BackgroundColor Orange -HighlightHeaders 'Declines'
                    } -DataStore JavaScript -ScrollX -Title "Detailed Server Performance Metrics"
                }
            }
        } else {
            New-HTMLSection -HeaderText "📊 DHCP Server Performance Analytics" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "ℹ️ No server statistics available" -Color Blue -FontWeight bold -FontSize 14pt
                    New-HTMLText -Text "Server statistics require Extended mode data collection or administrative access to DHCP servers." -Color Gray -FontSize 12px
                }
            }
        }

        # Include existing performance analysis sections here
        if ($DHCPData.PerformanceMetrics.Count -gt 0) {
            New-HTMLSection -HeaderText "📈 Capacity Planning & Performance Analysis" {
                New-HTMLPanel -Invisible {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "Performance Overview" -FontSize 16pt -FontWeight bold -Color DarkBlue
                        New-HTMLText -Text "Capacity utilization analysis and performance recommendations for optimal DHCP infrastructure." -FontSize 12pt
                    }

                    foreach ($Performance in $DHCPData.PerformanceMetrics) {
                        New-HTMLTable -DataTable @($Performance) -HideFooter {
                            New-HTMLTableCondition -Name 'HighUtilizationScopes' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Orange -HighlightHeaders 'HighUtilizationScopes'
                            New-HTMLTableCondition -Name 'CriticalUtilizationScopes' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Red -Color White -HighlightHeaders 'CriticalUtilizationScopes'
                            New-HTMLTableCondition -Name 'UnderUtilizedScopes' -ComparisonType number -Operator gt -Value 0 -BackgroundColor LightBlue -HighlightHeaders 'UnderUtilizedScopes'
                        }

                        # if ($Performance.CapacityPlanningRecommendations.Count -gt 0) {
                        #     New-HTMLSection -HeaderText "📈 Capacity Planning Recommendations" -CanCollapse {
                        #         foreach ($Recommendation in $Performance.CapacityPlanningRecommendations) {
                        #             New-HTMLText -Text "• $Recommendation" -Color DarkBlue
                        #         }
                        #     }
                        # }
                    }
                }
            }
        }
    }
}