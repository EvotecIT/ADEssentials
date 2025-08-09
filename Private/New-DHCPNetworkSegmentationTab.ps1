function New-DHCPNetworkSegmentationTab {
    <#
    .SYNOPSIS
    Creates the Network Segmentation tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Network Segmentation tab which focuses on network design,
    superscopes, network topology, and segmentation analysis.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Network Segmentation tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Network Segmentation' {
        # Network Design Overview at the top
        if ($DHCPData.NetworkDesignAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "🌐 Network Design Overview" {
                New-HTMLPanel -Invisible {
                    foreach ($Analysis in $DHCPData.NetworkDesignAnalysis) {
                        New-HTMLSection -HeaderText "Network Topology Analysis" -Invisible -Density Compact {
                            New-HTMLInfoCard -Title "Network Segments" -Number $Analysis.TotalNetworkSegments -Subtitle "Identified" -Icon "🌐" -TitleColor Blue -NumberColor DarkBlue
                            New-HTMLInfoCard -Title "Scope Overlaps" -Number $Analysis.ScopeOverlapsCount -Subtitle $(if ($Analysis.ScopeOverlapsCount -gt 0) { "Found" } else { "None" }) -Icon $(if ($Analysis.ScopeOverlapsCount -gt 0) { "⚠️" } else { "✅" }) -TitleColor $(if ($Analysis.ScopeOverlapsCount -gt 0) { "Red" } else { "Green" }) -NumberColor $(if ($Analysis.ScopeOverlapsCount -gt 0) { "DarkRed" } else { "DarkGreen" })
                            New-HTMLInfoCard -Title "Redundancy Issues" -Number $Analysis.RedundancyIssuesCount -Subtitle "Detected" -Icon "🔍" -TitleColor Orange -NumberColor DarkOrange
                            New-HTMLInfoCard -Title "Design Recommendations" -Number $Analysis.DesignRecommendationsCount -Subtitle "Generated" -Icon "💡" -TitleColor Purple -NumberColor DarkMagenta
                        }

                        # Network topology visualization placeholder
                        if ($Analysis.TotalNetworkSegments -gt 0) {
                            New-HTMLChart -Title "Network Segments Distribution" {
                                New-ChartBarOptions -Distributed
                                # This would show segment sizes if we had that data
                                New-ChartBar -Name "Configured Segments" -Value $Analysis.TotalNetworkSegments
                            } -Height 200
                        }
                    }
                }
            }
        }

        # Superscopes Configuration
        if ($DHCPData.Superscopes.Count -gt 0) {
            New-HTMLSection -HeaderText "🏗️ Superscopes Architecture" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Network Segmentation via Superscopes" -FontSize 18pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Superscopes combine multiple IP ranges into logical units for multi-homed subnets or network expansion." -FontSize 12pt -Color DarkGray

                    # Superscopes summary
                    $SuperscopeGroups = $DHCPData.Superscopes | Group-Object SuperscopeName
                    $TotalSuperscopes = $SuperscopeGroups.Count
                    $TotalScopesInSuperscopes = $DHCPData.Superscopes.Count
                    $ServersWithSuperscopes = ($DHCPData.Superscopes | Group-Object ServerName).Count

                    New-HTMLSection -HeaderText "Superscopes Statistics" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "Superscopes" -Number $TotalSuperscopes -Subtitle "Configured" -Icon "🏗️" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "Member Scopes" -Number $TotalScopesInSuperscopes -Subtitle "In Superscopes" -Icon "📋" -TitleColor Purple -NumberColor DarkMagenta
                        New-HTMLInfoCard -Title "Servers" -Number $ServersWithSuperscopes -Subtitle "With Superscopes" -Icon "🖥️" -TitleColor Orange -NumberColor DarkOrange
                    }

                    # Superscope details
                    foreach ($SuperscopeGroup in $SuperscopeGroups) {
                        New-HTMLSection -HeaderText "🏢 Superscope: $($SuperscopeGroup.Name)" -CanCollapse {
                            New-HTMLPanel -Invisible {
                                # Show relationships
                                New-HTMLText -Text "This superscope contains $($SuperscopeGroup.Group.Count) scope(s) across the following servers:" -FontSize 12pt
                                $Servers = $SuperscopeGroup.Group | Select-Object -ExpandProperty ServerName -Unique
                                foreach ($Server in $Servers) {
                                    New-HTMLText -Text "• $Server" -FontSize 11pt -Color DarkBlue
                                }

                                New-HTMLTable -DataTable $SuperscopeGroup.Group -HideFooter {
                                    New-HTMLTableCondition -Name 'SuperscopeState' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                                } -Title "Member Scopes in $($SuperscopeGroup.Name)"

                            }
                        }
                    }
                }
            }
        } else {
            New-HTMLSection -HeaderText "🏗️ Superscopes Architecture" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "ℹ️ No superscopes configured" -Color Blue -FontWeight bold -FontSize 14pt
                    New-HTMLText -Text "Superscopes are used to combine multiple scopes into a single administrative unit." -Color Gray -FontSize 12px

                    # New-HTMLText -Text "When to Use Superscopes:" -FontWeight bold -FontSize 14pt
                    # New-HTMLList {
                    #     New-HTMLListItem -Text "Multi-homed subnets (multiple IP ranges on same physical network)"
                    #     New-HTMLListItem -Text "Network expansion without re-addressing"
                    #     New-HTMLListItem -Text "Simplified scope management for related networks"
                    #     New-HTMLListItem -Text "Supporting legacy and new IP ranges simultaneously"
                    # }
                }
            }
        }

        # Server Network Analysis
        if ($DHCPData.ServerNetworkAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "🖥️ Server Network Topology" {
                New-HTMLTable -DataTable $DHCPData.ServerNetworkAnalysis -Filtering {
                    New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                    New-HTMLTableCondition -Name 'NetworkHealth' -ComparisonType string -Operator eq -Value 'Healthy' -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'NetworkHealth' -ComparisonType string -Operator contains -Value 'Issues' -BackgroundColor Orange
                    New-HTMLTableCondition -Name 'IsDomainController' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightBlue
                    New-HTMLTableCondition -Name 'DNSResolvable' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red
                    New-HTMLTableCondition -Name 'ReverseDNSValid' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Yellow
                } -DataStore JavaScript -ScrollX -Title "DHCP Server Network Configuration"
            }
        }

        # Network Segmentation Best Practices
        # New-HTMLSection -HeaderText "💡 Network Segmentation Best Practices" {
        #     New-HTMLPanel -Invisible {
        #         New-HTMLText -Text "📋 VLAN and Subnet Design:" -FontSize 16pt -FontWeight bold -Color Blue
        #         New-HTMLList {
        #             New-HTMLListItem -Text "Implement VLANs to separate different types of traffic (users, servers, IoT, guests)"
        #             New-HTMLListItem -Text "Use /24 subnets for user segments (254 hosts) unless larger segments are required"
        #             New-HTMLListItem -Text "Reserve smaller subnets (/28, /29) for server farms and management networks"
        #             New-HTMLListItem -Text "Implement RFC 1918 private addressing consistently across the organization"
        #             New-HTMLListItem -Text "Document all network segments and their purposes"
        #         }

        #         New-HTMLText -Text "🔒 Security Segmentation:" -FontSize 16pt -FontWeight bold -Color Blue
        #         New-HTMLList {
        #             New-HTMLListItem -Text "Isolate guest networks from corporate resources"
        #             New-HTMLListItem -Text "Create separate segments for IoT and building automation devices"
        #             New-HTMLListItem -Text "Implement DMZ segments for public-facing services"
        #             New-HTMLListItem -Text "Use separate management VLANs for infrastructure devices"
        #             New-HTMLListItem -Text "Consider microsegmentation for critical assets"
        #         }

        #         New-HTMLText -Text "📈 Scalability Considerations:" -FontSize 16pt -FontWeight bold -Color Blue
        #         New-HTMLList {
        #             New-HTMLListItem -Text "Plan for 30-50% growth when sizing subnets"
        #             New-HTMLListItem -Text "Use superscopes for network expansion without re-addressing"
        #             New-HTMLListItem -Text "Implement consistent addressing schemes across locations"
        #             New-HTMLListItem -Text "Reserve address space for future expansion"
        #             New-HTMLListItem -Text "Document IP allocation policies and procedures"
        #         }
        #     }
        # }
    }
}