function New-DHCPIPv4IPv6Tab {
    <#
    .SYNOPSIS
    Creates the IPv4/IPv6 tab content for DHCP HTML report with nested tabs.

    .DESCRIPTION
    This private function generates the IPv4/IPv6 tab which uses nested tabs to separate
    IPv4 and IPv6 scope management, with summaries at the top of each section.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the IPv4/IPv6 tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'IPv4/IPv6' {
        # Protocol Overview at the top
        New-HTMLSection -HeaderText "📊 IP Protocol Deployment Overview" {
            New-HTMLPanel -Invisible {
                # Calculate IPv4/IPv6 statistics
                $IPv4Configured = $DHCPData.Scopes.Count -gt 0
                $IPv6Configured = $DHCPData.IPv6Scopes.Count -gt 0
                $DualStack = $IPv4Configured -and $IPv6Configured

                New-HTMLSection -HeaderText "Protocol Status" -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "IPv4 Status" -Number $(if ($IPv4Configured) { "Active" } else { "Not Configured" }) -Subtitle "$($DHCPData.Scopes.Count) Scopes" -Icon "🔵" -TitleColor $(if ($IPv4Configured) { "Green" } else { "Gray" }) -NumberColor $(if ($IPv4Configured) { "DarkGreen" } else { "DarkGray" })
                    New-HTMLInfoCard -Title "IPv6 Status" -Number $(if ($IPv6Configured) { "Active" } else { "Not Configured" }) -Subtitle "$($DHCPData.IPv6Scopes.Count) Scopes" -Icon "🔶" -TitleColor $(if ($IPv6Configured) { "Green" } else { "Gray" }) -NumberColor $(if ($IPv6Configured) { "DarkGreen" } else { "DarkGray" })
                    New-HTMLInfoCard -Title "Dual Stack" -Number $(if ($DualStack) { "Enabled" } else { "Disabled" }) -Subtitle "IPv4 & IPv6" -Icon "🔄" -TitleColor $(if ($DualStack) { "Blue" } else { "Orange" }) -NumberColor $(if ($DualStack) { "DarkBlue" } else { "DarkOrange" })
                    New-HTMLInfoCard -Title "Multicast" -Number "$($DHCPData.MulticastScopes.Count)" -Subtitle "Scopes" -Icon "📡" -TitleColor "Purple" -NumberColor "DarkMagenta"
                }

                # Protocol deployment chart
                New-HTMLChart -Title "Protocol Deployment Distribution" {
                    New-ChartBarOptions -Distributed
                    New-ChartBar -Name 'IPv4 Scopes' -Value $DHCPData.Scopes.Count -Color '#0066CC'
                    New-ChartBar -Name 'IPv6 Scopes' -Value $DHCPData.IPv6Scopes.Count -Color '#FF6600'
                    New-ChartBar -Name 'Multicast Scopes' -Value $DHCPData.MulticastScopes.Count -Color '#9933CC'
                } -Height 300
            }
        }

        # Create nested tabs for IPv4 and IPv6
        New-HTMLTabPanel {
            # IPv4 Tab
            New-HTMLTab -TabName '🔵 IPv4' {
                # IPv4 Summary at the top
                if ($DHCPData.Scopes.Count -gt 0) {
                    New-HTMLSection -HeaderText "🔵 IPv4 DHCP Summary" -Density Comfortable {
                        New-HTMLSection -Invisible {
                            # Utilization gauge
                            New-HTMLChart -Title "IPv4 Overall Utilization" {
                                New-ChartRadial -Name "Used" -Value $DHCPData.Statistics.OverallPercentageInUse
                                New-ChartRadialOptions -CircleType SemiCircleGauge
                            } -Height 500px
                        }
                        New-HTMLSection -Invisible {
                            # IPv4 Statistics
                            $IPv4Stats = [PSCustomObject]@{
                                'Total Scopes'    = $DHCPData.Scopes.Count
                                'Active Scopes'   = ($DHCPData.Scopes | Where-Object { $_.State -eq 'Active' }).Count
                                'Inactive Scopes' = ($DHCPData.Scopes | Where-Object { $_.State -ne 'Active' }).Count
                                'Total Addresses' = "{0:N0}" -f $DHCPData.Statistics.TotalAddresses
                                'In Use'          = "{0:N0}" -f $DHCPData.Statistics.AddressesInUse
                                'Available'       = "{0:N0}" -f $DHCPData.Statistics.AddressesFree
                                'Utilization %'   = "$($DHCPData.Statistics.OverallPercentageInUse)%"
                            }

                            New-HTMLTable -DataTable $IPv4Stats -HideFooter -DisableSearch -DisablePaging -DisableOrdering -Title "IPv4 Infrastructure Summary" -Buttons @()
                        }
                    }

                    # IPv4 Scopes Table
                    New-HTMLSection -HeaderText "📋 IPv4 Scopes Details" {
                        New-HTMLTable -DataTable $DHCPData.Scopes -Filtering {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                            New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Yellow -HighlightHeaders 'LeaseDurationHours'
                            New-HTMLTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackgroundColor LightYellow -HighlightHeaders 'FailoverPartner'
                        } -DataStore JavaScript -ScrollX -Title "All IPv4 Scopes" -ExcludeProperty 'DNSSettings'
                    }
                } else {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "No IPv4 scopes configured" -FontSize 16pt -Color Gray
                        New-HTMLText -Text "IPv4 DHCP is essential for most networks. Consider configuring IPv4 scopes." -FontSize 12pt
                    }
                }
            }

            # IPv6 Tab
            New-HTMLTab -TabName '🔶 IPv6' {
                # IPv6 Summary at the top
                if ($DHCPData.IPv6Scopes.Count -gt 0) {
                    New-HTMLSection -HeaderText "🔶 IPv6 DHCP Configuration" {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "IPv6 Scope Summary" -FontSize 16pt -FontWeight bold -Color DarkBlue
                            New-HTMLText -Text "IPv6 DHCP scopes are configured and operational." -FontSize 12pt -Color Green

                            # IPv6 Statistics
                            $ActiveIPv6 = ($DHCPData.IPv6Scopes | Where-Object { $_.State -eq 'Active' }).Count
                            $IPv6Stats = [PSCustomObject]@{
                                'Total IPv6 Scopes' = $DHCPData.IPv6Scopes.Count
                                'Active Scopes'     = $ActiveIPv6
                                'Inactive Scopes'   = $DHCPData.IPv6Scopes.Count - $ActiveIPv6
                                'Deployment Status' = 'Active'
                            }

                            New-HTMLTable -DataTable $IPv6Stats -HideFooter -DisableSearch -DisablePaging -DisableOrdering
                        }
                    }

                    # IPv6 Scopes Table
                    New-HTMLSection -HeaderText "📋 IPv6 Scopes Details" {
                        New-HTMLTable -DataTable $DHCPData.IPv6Scopes -Filtering {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        } -DataStore JavaScript -ScrollX -Title "IPv6 Scopes Configuration"
                    }
                } else {
                    New-HTMLSection -HeaderText "🔶 IPv6 Readiness Assessment" {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "IPv6 Status: Not Configured" -FontSize 16pt -FontWeight bold -Color Orange
                            New-HTMLText -Text "No IPv6 DHCP scopes are currently configured in your environment." -FontSize 12pt

                            New-HTMLText -Text "IPv6 Deployment Recommendations:" -FontSize 14pt -FontWeight bold -Color Blue
                            New-HTMLList {
                                New-HTMLListItem -Text "Plan IPv6 implementation strategy aligned with business needs"
                                New-HTMLListItem -Text "Most networks use SLAAC (Stateless Address Autoconfiguration) for IPv6"
                                New-HTMLListItem -Text "DHCPv6 is typically used for stateful configuration requirements"
                                New-HTMLListItem -Text "Ensure network infrastructure (routers, switches) supports IPv6"
                                New-HTMLListItem -Text "Test IPv6 deployment in a lab environment first"
                                New-HTMLListItem -Text "Consider dual-stack approach for gradual migration"
                            }

                            New-HTMLText -Text "Common IPv6 Use Cases:" -FontSize 14pt -FontWeight bold -Color Blue
                            New-HTMLList {
                                New-HTMLListItem -Text "Internet of Things (IoT) deployments requiring many addresses"
                                New-HTMLListItem -Text "Mobile device networks"
                                New-HTMLListItem -Text "Service provider networks"
                                New-HTMLListItem -Text "Future-proofing network infrastructure"
                            }
                        }
                    }
                }
            }

            # Multicast Tab
            New-HTMLTab -TabName '📡 Multicast' {
                # Multicast Summary at the top
                New-HTMLSection -HeaderText "📡 Multicast DHCP Overview" {
                    if ($DHCPData.MulticastScopes.Count -gt 0) {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Multicast Configuration Active" -FontSize 16pt -FontWeight bold -Color Green
                            New-HTMLText -Text "Multicast scopes enable dynamic IP allocation for multicast applications." -FontSize 12pt -Color DarkGray

                            # Multicast Statistics
                            $ActiveMulticast = ($DHCPData.MulticastScopes | Where-Object { $_.State -eq 'Active' }).Count
                            $MulticastStats = [PSCustomObject]@{
                                'Total Multicast Scopes' = $DHCPData.MulticastScopes.Count
                                'Active Scopes'          = $ActiveMulticast
                                'Inactive Scopes'        = $DHCPData.MulticastScopes.Count - $ActiveMulticast
                                'Status'                 = 'Configured'
                            }

                            New-HTMLTable -DataTable $MulticastStats -HideFooter -DisableSearch -DisablePaging -DisableOrdering
                        }

                        # Multicast Scopes Table
                        New-HTMLSection -HeaderText "📋 Multicast Scopes Details" {
                            New-HTMLTable -DataTable $DHCPData.MulticastScopes -Filtering {
                                New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                            } -DataStore JavaScript -Title "Multicast Scopes"
                        }
                    } else {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "No Multicast Scopes Configured" -FontSize 16pt -FontWeight bold -Color Gray
                            New-HTMLText -Text "Multicast DHCP (MADCAP) is specialized for automatic multicast address assignment." -FontSize 12pt

                            New-HTMLText -Text "Multicast DHCP Use Cases:" -FontSize 14pt -FontWeight bold -Color Blue
                            New-HTMLList {
                                New-HTMLListItem -Text "Video streaming and IPTV deployments"
                                New-HTMLListItem -Text "Audio/video conferencing systems"
                                New-HTMLListItem -Text "Software distribution systems"
                                New-HTMLListItem -Text "Financial market data feeds"
                                New-HTMLListItem -Text "Network-based gaming applications"
                                New-HTMLListItem -Text "Distance learning platforms"
                            }

                            New-HTMLText -Text "Benefits of Multicast DHCP:" -FontSize 14pt -FontWeight bold -Color Blue
                            New-HTMLList {
                                New-HTMLListItem -Text "Automatic multicast address management"
                                New-HTMLListItem -Text "Prevents address conflicts"
                                New-HTMLListItem -Text "Simplifies multicast deployment"
                                New-HTMLListItem -Text "Centralized management"
                            }
                        }
                    }
                }
            }
        }
    }
}