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