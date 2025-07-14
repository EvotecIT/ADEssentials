function New-DHCPOptionsClassesTab {
    <#
    .SYNOPSIS
    Creates the Options & Classes tab content for DHCP HTML report.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    New-HTMLTab -TabName 'Options & Classes' {
        # DHCP Options Analysis Section with enhanced visuals
        if ($DHCPData.OptionsAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "⚙️ DHCP Options Health Dashboard" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "DHCP Options Configuration Analysis" -FontSize 18pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Critical analysis of DHCP options configuration across all servers and scopes. Essential options ensure proper client functionality and network connectivity." -FontSize 12pt -Color DarkGray

                    foreach ($Analysis in $DHCPData.OptionsAnalysis) {
                        New-HTMLSection -HeaderText "Configuration Health Overview" -Invisible -Density Compact {
                            New-HTMLInfoCard -Title "Total Servers" -Number $Analysis.TotalServersAnalyzed -Subtitle "Analyzed" -Icon "🖥️" -TitleColor DodgerBlue -NumberColor Navy
                            New-HTMLInfoCard -Title "Options Configured" -Number $Analysis.TotalOptionsConfigured -Subtitle "Total Settings" -Icon "⚙️" -TitleColor Purple -NumberColor DarkMagenta
                            New-HTMLInfoCard -Title "Option Types" -Number $Analysis.UniqueOptionTypes -Subtitle "Different Options" -Icon "🔧" -TitleColor Orange -NumberColor DarkOrange

                            if ($Analysis.CriticalOptionsCovered -ge 4) {
                                New-HTMLInfoCard -Title "Critical Options" -Number "$($Analysis.CriticalOptionsCovered)/6" -Subtitle "Good Coverage" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen -ShadowColor 'rgba(50, 205, 50, 0.15)'
                            } else {
                                New-HTMLInfoCard -Title "Critical Options" -Number "$($Analysis.CriticalOptionsCovered)/6" -Subtitle "Needs Attention" -Icon "⚠️" -TitleColor Crimson -NumberColor DarkRed -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                            }
                        }

                        New-HTMLTable -DataTable @($Analysis) -HideFooter {
                            New-HTMLTableCondition -Name 'CriticalOptionsCovered' -ComparisonType number -Operator lt -Value 4 -BackgroundColor Orange -HighlightHeaders 'CriticalOptionsCovered'
                            New-HTMLTableCondition -Name 'CriticalOptionsCovered' -ComparisonType number -Operator gt -Value 3 -BackgroundColor LightGreen -HighlightHeaders 'CriticalOptionsCovered'
                            New-HTMLTableCondition -Name 'OptionIssues' -ComparisonType string -Operator ne -Value '' -BackgroundColor Orange
                        } -Title "Detailed Analysis Results"

                        # Show missing critical options if any
                        if ($Analysis.MissingCriticalOptions.Count -gt 0) {
                            New-HTMLSection -HeaderText "🚨 Missing Critical Options" -CanCollapse {
                                New-HTMLPanel {
                                    New-HTMLText -Text "The following critical DHCP options are not configured anywhere in your environment:" -FontSize 12pt -Color DarkRed -FontWeight bold
                                    foreach ($MissingOption in $Analysis.MissingCriticalOptions) {
                                        New-HTMLText -Text "🔴 $MissingOption" -Color Red -FontSize 14px
                                    }
                                }
                            }
                        }

                        if ($Analysis.OptionIssues.Count -gt 0) {
                            New-HTMLSection -HeaderText "⚠️ Configuration Issues Found" -CanCollapse {
                                New-HTMLPanel {
                                    New-HTMLText -Text "These configuration issues require attention:" -FontSize 12pt -Color DarkOrange -FontWeight bold
                                    foreach ($Issue in $Analysis.OptionIssues) {
                                        New-HTMLText -Text "🟠 $Issue" -Color Orange -FontSize 14px
                                    }
                                }
                            }
                        }

                        if ($Analysis.OptionRecommendations.Count -gt 0) {
                            New-HTMLSection -HeaderText "💡 Expert Recommendations" -CanCollapse {
                                New-HTMLPanel {
                                    New-HTMLText -Text "Recommended actions to optimize your DHCP configuration:" -FontSize 12pt -Color DarkBlue -FontWeight bold
                                    foreach ($Recommendation in $Analysis.OptionRecommendations) {
                                        New-HTMLText -Text "💙 $Recommendation" -Color DarkBlue -FontSize 14px
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        # Server-Level DHCP Options with improved presentation
        if ($DHCPData.DHCPOptions.Count -gt 0) {
            New-HTMLSection -HeaderText "🔧 Server-Level DHCP Options Configuration" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Global Options Analysis" -FontSize 16pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Server-level options apply to all scopes on each DHCP server unless overridden at the scope level. These are your baseline configurations." -FontSize 12pt -Color DarkGray

                    # Group by server for better organization
                    $ServerGroups = $DHCPData.DHCPOptions | Group-Object ServerName
                    foreach ($ServerGroup in $ServerGroups) {
                        New-HTMLSection -HeaderText "🖥️ $($ServerGroup.Name) Options" -CanCollapse {
                            New-HTMLTable -DataTable $ServerGroup.Group -HideFooter {
                                New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 6 -BackgroundColor LightBlue -HighlightHeaders 'OptionId', 'Name'
                                New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 3 -BackgroundColor LightGreen -HighlightHeaders 'OptionId', 'Name'
                                New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 15 -BackgroundColor LightYellow -HighlightHeaders 'OptionId', 'Name'
                                New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator like -Value '*8.8.8.8*' -BackgroundColor Orange -HighlightHeaders 'Value'
                                New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator like -Value '*1.1.1.1*' -BackgroundColor Orange -HighlightHeaders 'Value'
                            } -Title "Server Options for $($ServerGroup.Name)"
                        }
                    }
                }
            }
        }

        # DHCP Classes with enhanced visuals
        if ($DHCPData.DHCPClasses.Count -gt 0) {
            New-HTMLSection -HeaderText "📋 DHCP Classes & Device Categorization" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Vendor & User Classes Overview" -FontSize 16pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "DHCP classes allow different configuration based on client type. Vendor classes identify device manufacturers, while user classes provide custom categorization." -FontSize 12pt -Color DarkGray

                    # Summary statistics
                    $VendorClasses = ($DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'Vendor' }).Count
                    $UserClasses = ($DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'User' }).Count
                    $TotalServers = ($DHCPData.DHCPClasses | Group-Object ServerName).Count

                    New-HTMLSection -HeaderText "Classes Summary" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "Vendor Classes" -Number $VendorClasses -Subtitle "Device Types" -Icon "🏭" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "User Classes" -Number $UserClasses -Subtitle "Custom Categories" -Icon "👥" -TitleColor Orange -NumberColor DarkOrange
                        New-HTMLInfoCard -Title "Servers" -Number $TotalServers -Subtitle "With Classes" -Icon "🖥️" -TitleColor Purple -NumberColor DarkMagenta
                    }

                    New-HTMLTable -DataTable $DHCPData.DHCPClasses -Filtering {
                        New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Vendor' -BackgroundColor LightBlue -HighlightHeaders 'Type'
                        New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'User' -BackgroundColor LightGreen -HighlightHeaders 'Type'
                        New-HTMLTableCondition -Name 'Name' -ComparisonType string -Operator like -Value '*Microsoft*' -BackgroundColor LightYellow -HighlightHeaders 'Name'
                    } -DataStore JavaScript -ScrollX -Title "Complete Classes Configuration"
                }
            }
        } else {
            New-HTMLSection -HeaderText "📋 DHCP Classes & Device Categorization" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "ℹ️ No custom DHCP classes configured" -Color Blue -FontWeight bold -FontSize 14pt
                    New-HTMLText -Text "DHCP classes allow you to provide different configurations based on client type or custom categories." -Color Gray -FontSize 12px

                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "Benefits of DHCP Classes:" -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Different lease durations for laptops vs servers"
                            New-HTMLListItem -Text "Specific DNS servers for different device types"
                            New-HTMLListItem -Text "Custom boot options for network boot devices"
                            New-HTMLListItem -Text "Vendor-specific option configurations"
                        } -FontSize 11px
                    }
                }
            }
        }
    }
}

function New-DHCPNetworkDesignTab {
    <#
    .SYNOPSIS
    Creates the Network Design tab content for DHCP HTML report.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    New-HTMLTab -TabName 'Network Design' {
        # Superscopes with enhanced presentation
        if ($DHCPData.Superscopes.Count -gt 0) {
            New-HTMLSection -HeaderText "🏗️ Superscopes & Network Architecture" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Network Segmentation Analysis" -FontSize 18pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Superscopes combine multiple IP ranges into logical units, typically used for multi-homed subnets or network expansion scenarios." -FontSize 12pt -Color DarkGray

                    # Superscopes summary
                    $SuperscopeGroups = $DHCPData.Superscopes | Group-Object SuperscopeName
                    $TotalSuperscopes = $SuperscopeGroups.Count
                    $TotalScopesInSuperscopes = $DHCPData.Superscopes.Count
                    $ServersWithSuperscopes = ($DHCPData.Superscopes | Group-Object ServerName).Count

                    New-HTMLSection -HeaderText "Superscopes Overview" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "Superscopes" -Number $TotalSuperscopes -Subtitle "Configured" -Icon "🏗️" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "Member Scopes" -Number $TotalScopesInSuperscopes -Subtitle "In Superscopes" -Icon "📋" -TitleColor Purple -NumberColor DarkMagenta
                        New-HTMLInfoCard -Title "Servers" -Number $ServersWithSuperscopes -Subtitle "With Superscopes" -Icon "🖥️" -TitleColor Orange -NumberColor DarkOrange
                    }

                    # Group by superscope for better visualization
                    foreach ($SuperscopeGroup in $SuperscopeGroups) {
                        New-HTMLSection -HeaderText "🏢 $($SuperscopeGroup.Name)" -CanCollapse {
                            New-HTMLTable -DataTable $SuperscopeGroup.Group -HideFooter {
                                New-HTMLTableCondition -Name 'SuperscopeState' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                            } -Title "Scopes in $($SuperscopeGroup.Name)"
                        }
                    }
                }
            }
        } else {
            New-HTMLSection -HeaderText "🏗️ Superscopes & Network Architecture" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "ℹ️ No superscopes configured in this environment" -Color Blue -FontWeight bold -FontSize 14pt
                    New-HTMLText -Text "Superscopes are used to combine multiple scopes into a single administrative unit." -Color Gray -FontSize 12px

                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "When to Use Superscopes:" -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Multi-homed subnets (multiple IP ranges on same network)"
                            New-HTMLListItem -Text "Network expansion scenarios"
                            New-HTMLListItem -Text "Simplified scope management"
                            New-HTMLListItem -Text "Load distribution across multiple ranges"
                        } -FontSize 11px
                    }
                }
            }
        }

        # Failover Relationships with enhanced visuals
        if ($DHCPData.FailoverRelationships.Count -gt 0) {
            New-HTMLSection -HeaderText "🔄 High Availability & Failover Configuration" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "DHCP Failover Analysis" -FontSize 18pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Failover relationships ensure DHCP service continuity. Monitor partner health and synchronization status for optimal reliability." -FontSize 12pt -Color DarkGray

                    # Failover summary
                    $LoadBalanceCount = ($DHCPData.FailoverRelationships | Where-Object { $_.Mode -eq 'LoadBalance' }).Count
                    $HotStandbyCount = ($DHCPData.FailoverRelationships | Where-Object { $_.Mode -eq 'HotStandby' }).Count
                    $NormalState = ($DHCPData.FailoverRelationships | Where-Object { $_.State -eq 'Normal' }).Count
                    $TotalFailovers = $DHCPData.FailoverRelationships.Count

                    New-HTMLSection -HeaderText "Failover Health Dashboard" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "Total Relations" -Number $TotalFailovers -Subtitle "Configured" -Icon "🔄" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "Load Balance" -Number $LoadBalanceCount -Subtitle "50/50 Mode" -Icon "⚖️" -TitleColor Purple -NumberColor DarkMagenta
                        New-HTMLInfoCard -Title "Hot Standby" -Number $HotStandbyCount -Subtitle "Primary/Backup" -Icon "🔥" -TitleColor Orange -NumberColor DarkOrange

                        if ($NormalState -eq $TotalFailovers) {
                            New-HTMLInfoCard -Title "Health Status" -Number "Healthy" -Subtitle "All Normal" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen
                        } else {
                            New-HTMLInfoCard -Title "Health Status" -Number "Issues" -Subtitle "Check Status" -Icon "⚠️" -TitleColor Crimson -NumberColor DarkRed -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                        }
                    }

                    New-HTMLTable -DataTable $DHCPData.FailoverRelationships -Filtering {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Normal' -BackgroundColor LightGreen
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator ne -Value 'Normal' -BackgroundColor Orange -HighlightHeaders 'State'
                        New-HTMLTableCondition -Name 'Mode' -ComparisonType string -Operator eq -Value 'LoadBalance' -BackgroundColor LightBlue -HighlightHeaders 'Mode'
                        New-HTMLTableCondition -Name 'Mode' -ComparisonType string -Operator eq -Value 'HotStandby' -BackgroundColor LightYellow -HighlightHeaders 'Mode'
                        New-HTMLTableCondition -Name 'AutoStateTransition' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'ScopeCount' -ComparisonType number -Operator gt -Value 5 -BackgroundColor LightBlue -HighlightHeaders 'ScopeCount'
                    } -DataStore JavaScript -ScrollX -Title "Complete Failover Configuration"
                }
            }
        } else {
            New-HTMLSection -HeaderText "🔄 High Availability & Failover Configuration" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "⚠️ No DHCP failover relationships configured" -Color Orange -FontWeight bold -FontSize 16pt
                    New-HTMLText -Text "DHCP failover provides high availability by allowing two DHCP servers to serve the same scopes." -Color Gray -FontSize 12px

                    New-HTMLSection -HeaderText "🚨 High Availability Recommendations" -CanCollapse {
                        New-HTMLPanel {
                            New-HTMLText -Text "Benefits of DHCP Failover:" -FontWeight bold -Color DarkBlue
                            New-HTMLList {
                                New-HTMLListItem -Text "🟢 Automatic failover when primary server becomes unavailable"
                                New-HTMLListItem -Text "🟢 Load balancing between two servers for better performance"
                                New-HTMLListItem -Text "🟢 Centralized scope management and synchronization"
                                New-HTMLListItem -Text "🟢 Improved network uptime and reliability"
                                New-HTMLListItem -Text "🟢 Reduced single points of failure"
                            } -FontSize 12px

                            New-HTMLText -Text "Implementation Considerations:" -FontWeight bold -Color DarkOrange
                            New-HTMLList {
                                New-HTMLListItem -Text "🟠 Requires Windows Server 2012 or later"
                                New-HTMLListItem -Text "🟠 Both servers must be in same domain"
                                New-HTMLListItem -Text "🟠 Network connectivity required between partners"
                                New-HTMLListItem -Text "🟠 Regular monitoring of sync status recommended"
                            } -FontSize 12px
                        }
                    }
                }
            }
        }
    }
}

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

                        if ($Performance.CapacityPlanningRecommendations.Count -gt 0) {
                            New-HTMLSection -HeaderText "📈 Capacity Planning Recommendations" -CanCollapse {
                                foreach ($Recommendation in $Performance.CapacityPlanningRecommendations) {
                                    New-HTMLText -Text "• $Recommendation" -Color DarkBlue
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}