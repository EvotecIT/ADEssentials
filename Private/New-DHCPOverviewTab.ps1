function New-DHCPOverviewTab {
    <#
    .SYNOPSIS
    Creates the Overview tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Overview tab which includes summary information,
    critical actions, infrastructure statistics, and visual analytics.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Overview tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    # Extract statistics for easier access
    $TotalServers = $DHCPData.Statistics.TotalServers
    $ServersOnline = $DHCPData.Statistics.ServersOnline
    $ServersOffline = $DHCPData.Statistics.ServersOffline
    $ServersWithIssues = $DHCPData.Statistics.ServersWithIssues
    $TotalScopes = $DHCPData.Statistics.TotalScopes
    $ScopesActive = $DHCPData.Statistics.ScopesActive
    $ScopesInactive = $DHCPData.Statistics.ScopesInactive
    $ScopesWithIssues = $DHCPData.Statistics.ScopesWithIssues
    $TotalAddresses = $DHCPData.Statistics.TotalAddresses
    $AddressesInUse = $DHCPData.Statistics.AddressesInUse
    $AddressesFree = $DHCPData.Statistics.AddressesFree
    $OverallPercentageInUse = $DHCPData.Statistics.OverallPercentageInUse

    New-HTMLTab -TabName 'Overview' {
        New-HTMLSection -Invisible {
            New-HTMLSection -HeaderText "DHCP Infrastructure Overview" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "About this Report" -FontSize 16px -FontWeight bold
                    New-HTMLText -Text "This report provides a comprehensive overview of DHCP infrastructure across your Active Directory forest. DHCP (Dynamic Host Configuration Protocol) is critical for automatic IP address assignment and network configuration. Monitoring DHCP health ensures reliable network connectivity for all clients." -FontSize 12px

                    New-HTMLText -Text "What to Look For" -FontSize 16px -FontWeight bold
                    New-HTMLList {
                        New-HTMLListItem -Text "Server Health: ", "Ensure all DHCP servers are online and operational" -FontWeight bold, normal
                        New-HTMLListItem -Text "Scope Utilization: ", "Monitor IP address pool usage to prevent exhaustion" -FontWeight bold, normal
                        New-HTMLListItem -Text "Configuration Issues: ", "Address DNS settings, lease durations, and failover configuration" -FontWeight bold, normal
                        New-HTMLListItem -Text "High Utilization: ", "Identify scopes approaching capacity limits" -FontWeight bold, normal
                    } -FontSize 12px

                    New-HTMLText -Text "Report Sections" -FontSize 16px -FontWeight bold
                    New-HTMLList {
                        New-HTMLListItem -Text "Overview: ", "Health summary, statistics, and key metrics at a glance" -FontWeight bold, normal
                        New-HTMLListItem -Text "Infrastructure: ", "Detailed server and scope information" -FontWeight bold, normal
                        New-HTMLListItem -Text "Validation Issues: ", "All configuration problems and capacity concerns" -FontWeight bold, normal
                        New-HTMLListItem -Text "Configuration: ", "Audit logs and database settings" -FontWeight bold, normal
                    } -FontSize 12px

                    New-HTMLText -Text "Environment Summary" -FontSize 16px -FontWeight bold
                    New-HTMLList {
                        New-HTMLListItem -Text "Total DHCP Servers: ", $TotalServers -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                        New-HTMLListItem -Text "Total DHCP Scopes: ", $TotalScopes -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                        New-HTMLListItem -Text "Total IP Addresses: ", $TotalAddresses.ToString("N0") -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                        New-HTMLListItem -Text "Overall Utilization: ", "$OverallPercentageInUse%" -Color Black, $(if ($OverallPercentageInUse -gt 80) { 'Red' } elseif ($OverallPercentageInUse -gt 60) { 'Orange' } else { 'Green' }) -FontWeight normal, bold -FontSize 12px
                    }
                }
            }
            # CRITICAL ACTIONS
            New-HTMLSection -HeaderText "🚨 Immediate Actions Required" {
                New-HTMLPanel -Invisible {
                    # Calculate critical metrics first
                    $CriticalIssuesCount = 0
                    $WarningIssuesCount = 0
                    $CriticalActions = @()
                    $WarningActions = @()

                    # Check for offline servers
                    $OfflineServersCount = @($DHCPData.Servers | Where-Object { $_.Status -ne 'Online' }).Count
                    if ($OfflineServersCount -gt 0) {
                        $CriticalIssuesCount += $OfflineServersCount
                        $CriticalActions += "🔴 $OfflineServersCount DHCP server(s) are offline - Check network connectivity and service status immediately"
                    }

                    # Check for high utilization (>90%)
                    $CriticalUtilizationScopes = @($DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 90 }).Count
                    if ($CriticalUtilizationScopes -gt 0) {
                        $CriticalIssuesCount += $CriticalUtilizationScopes
                        $CriticalActions += "🔴 $CriticalUtilizationScopes scope(s) have critical utilization (>90%) - Expand IP ranges immediately"
                    }

                    # Check for high utilization (>80%)
                    $HighUtilizationScopes = @($DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 80 -and $_.PercentageInUse -le 90 }).Count
                    if ($HighUtilizationScopes -gt 0) {
                        $WarningIssuesCount += $HighUtilizationScopes
                        $WarningActions += "⚠️ $HighUtilizationScopes scope(s) have high utilization (>80%) - Monitor and plan expansion"
                    }

                    # Check for servers with failed validation
                    $FailedValidationServers = @($DHCPData.Servers | Where-Object { -not $_.DHCPResponding -or -not $_.PingSuccessful -or -not $_.DNSResolvable }).Count
                    if ($FailedValidationServers -gt 0) {
                        $CriticalIssuesCount += $FailedValidationServers
                        $CriticalActions += "🔴 $FailedValidationServers server(s) failed connectivity validation - Check DNS, network, and DHCP service"
                    }

                    # Check for scopes with configuration issues
                    $ScopesWithConfigIssues = @($DHCPData.ScopesWithIssues).Count
                    if ($ScopesWithConfigIssues -gt 0) {
                        $WarningIssuesCount += $ScopesWithConfigIssues
                        $WarningActions += "⚠️ $ScopesWithConfigIssues scope(s) have configuration issues - Review DNS settings and failover configuration"
                    }

                    if ($CriticalIssuesCount -gt 0 -and $CriticalActions.Count -gt 0) {
                        New-HTMLText -Text "CRITICAL ISSUES REQUIRING IMMEDIATE ATTENTION" -Color Red -FontSize 18px -FontWeight bold
                        New-HTMLList {
                            foreach ($Action in $CriticalActions) {
                                New-HTMLListItem -Text $Action -Color Red -FontWeight bold
                            }
                        } -FontSize 14px
                    }

                    if ($WarningIssuesCount -gt 0 -and $WarningActions.Count -gt 0) {
                        New-HTMLText -Text "Warning Issues Requiring Attention" -Color Orange -FontSize 16px -FontWeight bold
                        New-HTMLList {
                            foreach ($Action in $WarningActions) {
                                New-HTMLListItem -Text $Action -Color DarkOrange -FontWeight bold
                            }
                        } -FontSize 13px
                    }

                    if ($CriticalIssuesCount -eq 0 -and $WarningIssuesCount -eq 0) {
                        New-HTMLText -Text "✅ No Critical Issues Detected" -Color Green -FontSize 18px -FontWeight bold
                        New-HTMLText -Text "Your DHCP infrastructure appears healthy. Continue monitoring and review recommendations below." -Color Green -FontSize 14px
                    }

                    # Always show these general recommendations
                    New-HTMLText -Text "General Recommendations:" -Color Blue -FontSize 14px -FontWeight bold
                    New-HTMLList {
                        New-HTMLListItem -Text "📊 Review detailed analysis in the Infrastructure and Validation Issues tabs"
                        New-HTMLListItem -Text "📋 Check Configuration tab for audit log and database settings"
                        New-HTMLListItem -Text "🔄 Implement DHCP failover for critical environments"
                        New-HTMLListItem -Text "📈 Monitor scope utilization trends regularly"
                        New-HTMLListItem -Text "🔍 Validate server connectivity and DNS resolution monthly"
                    } -FontSize 12px
                }
            }
        }
        New-HTMLSection -HeaderText "DHCP Infrastructure Statistics & Visual analytics" -Wrap wrap {
            # Infrastructure Overview using Info Cards - organized in logical rows
            New-HTMLSection -HeaderText "Server Status Overview" -Invisible -Density Compact {
                New-HTMLInfoCard -Title "Total Servers" -Number $TotalServers -Subtitle "DHCP Infrastructure" -Icon "🖥️" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                New-HTMLInfoCard -Title "Online Servers" -Number $ServersOnline -Subtitle "Operational" -Icon "✅" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'

                if ($ServersOffline -gt 0) {
                    New-HTMLInfoCard -Title "Offline Servers" -Number $ServersOffline -Subtitle "Need Attention" -Icon "❌" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                } else {
                    New-HTMLInfoCard -Title "Offline Servers" -Number $ServersOffline -Subtitle "All Online" -Icon "🎯" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                }

                if ($ServersWithIssues -gt 0) {
                    New-HTMLInfoCard -Title "Servers with Issues" -Number $ServersWithIssues -Subtitle "Configuration Issues" -Icon "⚠️" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.2)'
                } else {
                    New-HTMLInfoCard -Title "Servers with Issues" -Number $ServersWithIssues -Subtitle "All Clean" -Icon "✨" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                }
            }

            New-HTMLSection -HeaderText "Scope Status Overview" -Invisible -Density Compact {
                New-HTMLInfoCard -Title "Total Scopes" -Number $TotalScopes -Subtitle "All Configured Scopes" -Icon "📋" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                New-HTMLInfoCard -Title "Active Scopes" -Number $ScopesActive -Subtitle "Currently Serving" -Icon "🟢" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'

                if ($ScopesInactive -gt 0) {
                    New-HTMLInfoCard -Title "Inactive Scopes" -Number $ScopesInactive -Subtitle "Disabled" -Icon "🔴" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.15)'
                } else {
                    New-HTMLInfoCard -Title "Inactive Scopes" -Number $ScopesInactive -Subtitle "All Active" -Icon "✅" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                }

                if ($ScopesWithIssues -gt 0) {
                    New-HTMLInfoCard -Title "Scopes with Issues" -Number $ScopesWithIssues -Subtitle "Need Review" -Icon "🔧" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                } else {
                    New-HTMLInfoCard -Title "Scopes with Issues" -Number $ScopesWithIssues -Subtitle "All Configured" -Icon "💯" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                }
            }

        New-HTMLSection -HeaderText "Address Pool Utilization" -Invisible -Density Compact {
            New-HTMLInfoCard -Title "Total IP Addresses" -Number $TotalAddresses.ToString("N0") -Subtitle "Pool Capacity" -Icon "🚀" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'

                if ($OverallPercentageInUse -gt 80) {
                    New-HTMLInfoCard -Title "Addresses In Use" -Number $AddressesInUse.ToString("N0") -Subtitle "High Utilization" -Icon "🚨" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.25)' -ShadowIntensity ExtraBold
                } elseif ($OverallPercentageInUse -gt 60) {
                    New-HTMLInfoCard -Title "Addresses In Use" -Number $AddressesInUse.ToString("N0") -Subtitle "Moderate Usage" -Icon "⚠️" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.2)'
                } else {
                    New-HTMLInfoCard -Title "Addresses In Use" -Number $AddressesInUse.ToString("N0") -Subtitle "Healthy Usage" -Icon "📊" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                }

                New-HTMLInfoCard -Title "Addresses Available" -Number $AddressesFree.ToString("N0") -Subtitle "Ready for Assignment" -Icon "🆓" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'

                if ($OverallPercentageInUse -gt 90) {
                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "Critical Level" -Icon "🔥" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.3)' -ShadowIntensity ExtraBold -ShadowDirection 'All'
                } elseif ($OverallPercentageInUse -gt 75) {
                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "High Usage" -Icon "📈" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.25)' -ShadowIntensity Bold
                } elseif ($OverallPercentageInUse -gt 50) {
                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "Moderate Usage" -Icon "📊" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                } else {
                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "Low Usage" -Icon "🌱" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                }
            }
        }

        # Failover Overview (new) - show critical failover coverage and mismatches
        if ($DHCPData.FailoverRelationships.Count -ge 0) {
            New-HTMLSection -HeaderText "Failover Overview" -Invisible -Density Compact {
                $ScopesWithoutFailover = ($DHCPData.Scopes | Where-Object { $_.State -eq 'Active' -and (-not $_.HasFailover) }).Count
                $OnlyOnPrimary   = if ($DHCPData.FailoverAnalysis) { $DHCPData.FailoverAnalysis.OnlyOnPrimary.Count } else { 0 }
                $OnlyOnSecondary = if ($DHCPData.FailoverAnalysis) { $DHCPData.FailoverAnalysis.OnlyOnSecondary.Count } else { 0 }
                $MissingOnBoth   = if ($DHCPData.FailoverAnalysis) { $DHCPData.FailoverAnalysis.MissingOnBoth.Count } else { 0 }

                New-HTMLInfoCard -Title "Unprotected Scopes" -Number $ScopesWithoutFailover -Subtitle "No Failover" -Icon "🚨" -TitleColor $(if ($ScopesWithoutFailover -gt 0) { 'Orange' } else { 'Green' }) -NumberColor $(if ($ScopesWithoutFailover -gt 0) { 'DarkOrange' } else { 'DarkGreen' })
                New-HTMLInfoCard -Title "Only on Primary" -Number $OnlyOnPrimary -Subtitle "Mismatch" -Icon "🟠" -TitleColor 'DarkOrange' -NumberColor 'DarkOrange'
                New-HTMLInfoCard -Title "Only on Secondary" -Number $OnlyOnSecondary -Subtitle "Mismatch" -Icon "🟠" -TitleColor 'DarkOrange' -NumberColor 'DarkOrange'
                New-HTMLInfoCard -Title "Missing on Both" -Number $MissingOnBoth -Subtitle "Gap" -Icon "⚠️" -TitleColor 'OrangeRed' -NumberColor 'OrangeRed'
            }
        }

        # Charts Section - organized vertically for better readability
        New-HTMLSection -HeaderText "Visual Analytics" -Invisible {
            New-HTMLPanel -Invisible {
                New-HTMLChart {
                    New-ChartPie -Name 'Servers Online' -Value $DHCPData.Statistics.ServersOnline -Color LightGreen
                    New-ChartPie -Name 'Servers Offline' -Value $DHCPData.Statistics.ServersOffline -Color Salmon
                    New-ChartPie -Name 'Servers with Issues' -Value $DHCPData.Statistics.ServersWithIssues -Color Orange
                } -Title 'DHCP Server Status' -TitleColor DodgerBlue
            }

            New-HTMLPanel -Invisible {
                New-HTMLChart {
                    New-ChartPie -Name 'Addresses In Use' -Value $DHCPData.Statistics.AddressesInUse -Color Orange
                    New-ChartPie -Name 'Addresses Available' -Value $DHCPData.Statistics.AddressesFree -Color LightGreen
                } -Title 'Address Pool Utilization' -TitleColor DodgerBlue
            }
        }
    }
}
