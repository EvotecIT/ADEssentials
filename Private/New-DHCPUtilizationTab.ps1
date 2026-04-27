function New-DHCPUtilizationTab {
    <#
    .SYNOPSIS
    Creates the Utilization tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Utilization tab which focuses on capacity planning,
    utilization trends, growth analysis, and forecasting.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Utilization tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Utilization' {
        $OnlineServerPerformance = @($DHCPData.ServerPerformanceAnalysis | Where-Object { $_.Status -eq 'Online' } | Sort-Object UtilizationPercent -Descending)
        $TopUtilizedScopes = @($DHCPData.Scopes | Where-Object { $_.State -eq 'Active' } | Sort-Object PercentageInUse -Descending | Select-Object -First 10)
        $TopServerPerformance = @($OnlineServerPerformance | Select-Object -First 10)
        $CriticalUtilizationCount = @($DHCPData.ValidationResults.UtilizationIssues.HighUtilization).Count
        $ModerateUtilizationCount = @($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization).Count
        $OverallUtilization = [Math]::Round([double]$DHCPData.Statistics.OverallPercentageInUse, 2)
        $OverallUtilizationColor = if ($OverallUtilization -gt 90) {
            'Crimson'
        } elseif ($OverallUtilization -gt 75) {
            'DarkOrange'
        } else {
            'DodgerBlue'
        }

        # Overall Utilization Summary
        New-HTMLSection -HeaderText "📊 Overall DHCP Utilization Summary" {
            New-HTMLPanel -Invisible {
                if ($DHCPData.AccurateUtilization) {
                    New-HTMLText -Text "Accurate utilization is enabled (active leases + active reservations). This is slower due to per-scope lease enumeration." -FontSize 11pt -Color DarkOrange
                } else {
                    New-HTMLText -Text "Utilization is based on DHCP scope statistics, which include inactive reservations." -FontSize 11pt -Color DarkGray
                }

                New-HTMLSection -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallUtilization%" -Subtitle "Across all active scopes" -Icon "📊" -TitleColor $OverallUtilizationColor -NumberColor $OverallUtilizationColor
                    New-HTMLInfoCard -Title "Addresses In Use" -Number ("{0:N0}" -f $DHCPData.Statistics.AddressesInUse) -Subtitle "Currently assigned" -Icon "🔴" -TitleColor 'Crimson' -NumberColor 'DarkRed'
                    New-HTMLInfoCard -Title "Addresses Available" -Number ("{0:N0}" -f $DHCPData.Statistics.AddressesFree) -Subtitle "Remaining capacity" -Icon "🟢" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen'
                    New-HTMLInfoCard -Title "Critical Scopes" -Number $CriticalUtilizationCount -Subtitle ">90% utilization" -Icon "🚨" -TitleColor $(if ($CriticalUtilizationCount -gt 0) { 'Crimson' } else { 'LimeGreen' }) -NumberColor $(if ($CriticalUtilizationCount -gt 0) { 'DarkRed' } else { 'DarkGreen' })
                    New-HTMLInfoCard -Title "Warning Scopes" -Number $ModerateUtilizationCount -Subtitle "75-90% utilization" -Icon "⚠️" -TitleColor $(if ($ModerateUtilizationCount -gt 0) { 'DarkOrange' } else { 'LimeGreen' }) -NumberColor $(if ($ModerateUtilizationCount -gt 0) { 'DarkOrange' } else { 'DarkGreen' })
                }

                $CapacityMetrics = [PSCustomObject]@{
                    'Total Addresses' = "{0:N0}" -f $DHCPData.Statistics.TotalAddresses
                    'In Use'          = "{0:N0}" -f $DHCPData.Statistics.AddressesInUse
                    'Available'       = "{0:N0}" -f $DHCPData.Statistics.AddressesFree
                    'Critical Scopes' = $CriticalUtilizationCount
                    'Warning Scopes'  = $ModerateUtilizationCount
                }
                New-HTMLTable -DataTable $CapacityMetrics -HideFooter -DisableSearch -DisablePaging -DisableOrdering -Buttons @() -Title 'Capacity Metrics'
            }
        }

        # Utilization by Server
        if ($DHCPData.ServerPerformanceAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "🖥️ Server Utilization Analysis" -Wrap wrap {
                New-HTMLPanel -Invisible {
                    if ($TopServerPerformance.Count -gt 0) {
                        $serverRanking = for ($index = 0; $index -lt $TopServerPerformance.Count; $index++) {
                            [PSCustomObject]@{
                                Rank               = $index + 1
                                ServerName         = $TopServerPerformance[$index].ServerName
                                UtilizationPercent = [Math]::Round([double]$TopServerPerformance[$index].UtilizationPercent, 2)
                                ActiveScopes       = $TopServerPerformance[$index].ActiveScopes
                                ScopesWithIssues   = $TopServerPerformance[$index].ScopesWithIssues
                                PerformanceRating  = $TopServerPerformance[$index].PerformanceRating
                                CapacityStatus     = $TopServerPerformance[$index].CapacityStatus
                            }
                        }

                        New-HTMLText -Text "Top online servers by utilization, shown as a ranking table to keep the layout readable and avoid chart overflow." -FontSize 11pt -Color DarkSlateGray
                        New-HTMLTable -DataTable $serverRanking -HideFooter -DisableSearch -DisablePaging -DisableOrdering -Buttons @() -Title 'Top 10 Server Utilization' {
                            New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Red -Color White -HighlightHeaders 'UtilizationPercent', 'CapacityStatus'
                            New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'UtilizationPercent'
                            New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 50 -BackgroundColor Yellow -HighlightHeaders 'UtilizationPercent'
                            New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                            New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Orange
                        }
                    }

                    New-HTMLTable -DataTable $DHCPData.ServerPerformanceAnalysis -Filtering {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Red -Color White -HighlightHeaders 'UtilizationPercent'
                        New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'UtilizationPercent'
                        New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 50 -BackgroundColor Yellow -HighlightHeaders 'UtilizationPercent'
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Orange
                    } -DataStore JavaScript -ScrollX -Title "Server Capacity and Performance Metrics"
                }
            }
        }

        # Scope Utilization Details
        New-HTMLSection -HeaderText "📈 Scope Utilization Analysis" -Wrap wrap {
            New-HTMLPanel -Invisible {
                # Top 10 utilized scopes table
                if ($TopUtilizedScopes.Count -gt 0) {
                    $scopeRanking = for ($index = 0; $index -lt $TopUtilizedScopes.Count; $index++) {
                        [PSCustomObject]@{
                            Rank               = $index + 1
                            ServerName         = $TopUtilizedScopes[$index].ServerName
                            ScopeId            = [string]$TopUtilizedScopes[$index].ScopeId
                            Name               = $TopUtilizedScopes[$index].Name
                            PercentageInUse    = [Math]::Round([double]$TopUtilizedScopes[$index].PercentageInUse, 2)
                            AddressesInUse     = $TopUtilizedScopes[$index].AddressesInUse
                            AddressesFree      = $TopUtilizedScopes[$index].AddressesFree
                            CapacityStatus     = if ($TopUtilizedScopes[$index].PercentageInUse -gt 90) { 'Critical' } elseif ($TopUtilizedScopes[$index].PercentageInUse -gt 75) { 'Warning' } else { 'Healthy' }
                        }
                    }

                    New-HTMLText -Text "Top 10 most utilized scopes, shown as a compact ranking table instead of a chart to keep the layout stable." -FontSize 11pt -Color DarkSlateGray
                    New-HTMLTable -DataTable $scopeRanking -HideFooter -DisableSearch -DisablePaging -DisableOrdering -Title 'Top 10 Most Utilized Scopes' -Buttons @() {
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse', 'CapacityStatus'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor LightYellow -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Orange
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Healthy' -BackgroundColor LightGreen
                    }
                }
            }
            # High utilization scopes
            if ($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count -gt 0) {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "🔴 Critical Utilization Scopes (>90%)" -FontSize 16pt -FontWeight bold -Color Red
                    New-HTMLTable -DataTable $DHCPData.ValidationResults.UtilizationIssues.HighUtilization -Filtering {
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 95 -BackgroundColor Red -Color White -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                    } -DataStore JavaScript -ScrollX
                }
            }

            # Moderate utilization scopes
            if ($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count -gt 0) {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "🟠 High Utilization Scopes (75-90%)" -FontSize 16pt -FontWeight bold -Color DarkOrange
                    New-HTMLTable -DataTable $DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization -Filtering {
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 85 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Yellow -HighlightHeaders 'PercentageInUse'
                    } -DataStore JavaScript -ScrollX
                }
            }


        }

        # Growth Trend Analysis (moved from Scale Analysis)
        New-HTMLSection -HeaderText "📈 Capacity Forecasting & Growth Planning" {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Growth Trend Analysis" -FontSize 16pt -FontWeight bold -Color DarkBlue
                New-HTMLText -Text "Based on current utilization patterns and environment size, plan capacity expansion appropriately." -FontSize 12pt -Color DarkGray

                # Calculate forecasting metrics
                $CurrentCapacity = $DHCPData.Statistics.TotalAddresses
                $CurrentUsage = $DHCPData.Statistics.AddressesInUse
                $CurrentUtilization = $DHCPData.Statistics.OverallPercentageInUse

                # Determine growth rate based on current utilization
                $MonthlyGrowthRate = if ($CurrentUtilization -gt 80) { 5 }
                elseif ($CurrentUtilization -gt 60) { 3 }
                else { 2 }

                # Calculate projections
                $Projections = @()
                for ($months = 3; $months -le 24; $months += 3) {
                    $ProjectedUsage = [Math]::Round($CurrentUsage * [Math]::Pow(1 + ($MonthlyGrowthRate / 100), $months))
                    $ProjectedUtilization = [Math]::Round(($ProjectedUsage / $CurrentCapacity) * 100, 2)

                    $Projections += [PSCustomObject]@{
                        'Time Period'           = "+$months months"
                        'Projected Usage'       = "{0:N0}" -f $ProjectedUsage
                        'Projected Utilization' = "$ProjectedUtilization%"
                        'Status'                = if ($ProjectedUtilization -gt 95) { 'Critical' }
                        elseif ($ProjectedUtilization -gt 85) { 'Warning' }
                        else { 'OK' }
                        'Action Required'       = if ($ProjectedUtilization -gt 95) { 'Immediate expansion needed' }
                        elseif ($ProjectedUtilization -gt 85) { 'Plan expansion' }
                        else { 'Monitor' }
                    }
                }

                New-HTMLTable -DataTable $Projections -Filtering {
                    New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                    New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Orange
                    New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen
                } -Title "Growth Projections (Monthly Growth Rate: $MonthlyGrowthRate%)"

                # Recommendations
                New-HTMLText -Text "Capacity Planning Recommendations:" -FontSize 14pt -FontWeight bold -Color Blue
                New-HTMLList {
                    if ($CurrentUtilization -gt 85) {
                        New-HTMLListItem -Text "🚨 Critical: Current utilization exceeds 85%. Immediate capacity expansion required."
                    }
                    if (($Projections | Where-Object { $_.Status -eq 'Critical' }).Count -gt 0) {
                        New-HTMLListItem -Text "⚠️ Based on growth projections, capacity will be exhausted within $((($Projections | Where-Object { $_.Status -eq 'Critical' })[0]).'Time Period')"
                    }
                    if ($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count -gt 0) {
                        New-HTMLListItem -Text "📊 $($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count) scope(s) require immediate expansion"
                    }
                    if ($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count -gt 0) {
                        New-HTMLListItem -Text "📈 $($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count) scope(s) need expansion planning"
                    }
                    New-HTMLListItem -Text "💡 Consider implementing DHCP split-scope configuration for load balancing"
                    New-HTMLListItem -Text "🔄 Review and optimize lease duration settings to improve address recycling"
                }
            }
        }

        # Utilization Heatmap
        if ($DHCPData.Scopes.Count -gt 0) {
            New-HTMLSection -HeaderText "🗺️ Utilization Heatmap" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Visual representation of scope utilization across the infrastructure" -FontSize 12pt -Color DarkGray

                    # Create heatmap data
                    $HeatmapData = foreach ($Scope in ($DHCPData.Scopes | Where-Object { $_.State -eq 'Active' })) {
                        [PSCustomObject]@{
                            'Scope'       = "$($Scope.Name) ($($Scope.ScopeId))"
                            'Server'      = $Scope.ServerName
                            'Utilization' = $Scope.PercentageInUse
                            'Status'      = if ($Scope.PercentageInUse -gt 90) { '🔴 Critical' }
                            elseif ($Scope.PercentageInUse -gt 75) { '🟠 High' }
                            elseif ($Scope.PercentageInUse -gt 50) { '🟡 Moderate' }
                            else { '🟢 Low' }
                        }
                    }

                    New-HTMLTable -DataTable $HeatmapData -Filtering {
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 90 -BackgroundColor '#8B0000' -Color White
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 80 -BackgroundColor '#FF0000' -Color White
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 70 -BackgroundColor '#FF4500'
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 60 -BackgroundColor '#FFA500'
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 50 -BackgroundColor '#FFD700'
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 40 -BackgroundColor '#FFFF00'
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 30 -BackgroundColor '#ADFF2F'
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator gt -Value 20 -BackgroundColor '#00FF00'
                        New-HTMLTableCondition -Name 'Utilization' -ComparisonType number -Operator le -Value 20 -BackgroundColor '#006400' -Color White
                    } -DataStore JavaScript
                }
            }
        }
    }
}
