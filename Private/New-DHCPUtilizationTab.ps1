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
        # Overall Utilization Summary
        New-HTMLSection -HeaderText "📊 Overall DHCP Utilization Summary" {
            New-HTMLPanel -Invisible {
                # Create utilization gauges
                New-HTMLSection -Density Compact -Invisible {
                    New-HTMLPanel {
                        #New-HTMLText -Text "Overall IP Utilization" -FontSize 14pt -FontWeight bold -Alignment center
                        New-HTMLChart {
                            New-ChartRadial -Name "Used" -Value $DHCPData.Statistics.OverallPercentageInUse
                            New-ChartRadialOptions -CircleType SemiCircleGauge
                        } -Title "Overall IP Utilization"
                    }

                    New-HTMLPanel {
                        New-HTMLText -Text "Address Distribution" -FontSize 14pt -FontWeight bold -Alignment center
                        New-HTMLChart {
                            New-ChartDonut -Name "In Use" -Value $DHCPData.Statistics.AddressesInUse -Color '#FF6347'
                            New-ChartDonut -Name "Available" -Value $DHCPData.Statistics.AddressesFree -Color '#00FF00'
                        }
                    }


                    if (($DHCPData.ServerPerformanceAnalysis | Where-Object { $_.Status -eq 'Online' }).Count -gt 0) {
                        New-HTMLPanel -Invisible {
                            New-HTMLChart -Title "Server Utilization Comparison" {
                                New-ChartBarOptions -Type bar -Distributed
                                foreach ($Server in ($DHCPData.ServerPerformanceAnalysis | Where-Object { $_.Status -eq 'Online' })) {
                                    New-ChartBar -Name $Server.ServerName -Value $Server.UtilizationPercent
                                }
                            }
                        }
                    }
                    New-HTMLSection -Invisible {
                        New-HTMLPanel {
                            New-HTMLText -Text "Capacity Metrics" -FontSize 14pt -FontWeight bold -Alignment center
                            $CapacityMetrics = [PSCustomObject]@{
                                'Total Addresses' = "{0:N0}" -f $DHCPData.Statistics.TotalAddresses
                                'In Use'          = "{0:N0}" -f $DHCPData.Statistics.AddressesInUse
                                'Available'       = "{0:N0}" -f $DHCPData.Statistics.AddressesFree
                                'Critical Scopes' = ($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count)
                                'Warning Scopes'  = ($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count)
                            }
                            New-HTMLTable -DataTable $CapacityMetrics -HideFooter -DisableSearch -DisablePaging -DisableOrdering
                        }
                    }
                }
            }
        }

        # Utilization by Server
        if ($DHCPData.ServerPerformanceAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "🖥️ Server Utilization Analysis" -Wrap wrap {
                # Server utilization chart

                New-HTMLPanel -Invisible {
                    New-HTMLTable -DataTable $DHCPData.ServerPerformanceAnalysis -Filtering {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Red -Color White -HighlightHeaders 'UtilizationPercent'
                        New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'UtilizationPercent'
                        New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 50 -BackgroundColor Yellow -HighlightHeaders 'UtilizationPercent'
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'CapacityStatus' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Orange
                    } -DataStore JavaScript -Title "Server Capacity and Performance Metrics"
                }
            }
        }

        # Scope Utilization Details
        New-HTMLSection -HeaderText "📈 Scope Utilization Analysis" -Wrap wrap {
            New-HTMLPanel -Invisible {
                # Top 10 utilized scopes chart
                $TopUtilizedScopes = $DHCPData.Scopes | Where-Object { $_.State -eq 'Active' } | Sort-Object PercentageInUse -Descending | Select-Object -First 10
                if ($TopUtilizedScopes.Count -gt 0) {
                    New-HTMLChart -Title "Top 10 Most Utilized Scopes" {
                        New-ChartBarOptions -Type bar -Distributed
                        foreach ($Scope in $TopUtilizedScopes) {
                            $Color = if ($Scope.PercentageInUse -gt 90) { '#FF0000' }
                            elseif ($Scope.PercentageInUse -gt 75) { '#FFA500' }
                            else { '#00FF00' }
                            New-ChartBar -Name "$($Scope.Name) ($($Scope.ScopeId))" -Value $Scope.PercentageInUse -Color $Color
                        }
                    } -Height 400
                }
            }
            # High utilization scopes
            if ($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count -gt 0) {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "🔴 Critical Utilization Scopes (>90%)" -FontSize 16pt -FontWeight bold -Color Red
                    New-HTMLTable -DataTable $DHCPData.ValidationResults.UtilizationIssues.HighUtilization -Filtering {
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 95 -BackgroundColor Red -Color White -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                    } -DataStore JavaScript
                }
            }

            # Moderate utilization scopes
            if ($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count -gt 0) {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "🟠 High Utilization Scopes (75-90%)" -FontSize 16pt -FontWeight bold -Color DarkOrange
                    New-HTMLTable -DataTable $DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization -Filtering {
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 85 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Yellow -HighlightHeaders 'PercentageInUse'
                    } -DataStore JavaScript
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