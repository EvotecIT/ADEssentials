function New-DHCPInfrastructureTab {
    <#
    .SYNOPSIS
    Creates the Infrastructure tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Infrastructure tab which includes server health,
    scopes overview, IPv6/multicast status, security filters, policies, reservations, and network bindings.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Infrastructure tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Infrastructure' {
        # Enhanced Server Health Status
        New-HTMLSection -HeaderText "Server Health & Connectivity Analysis" {
            New-HTMLTable -DataTable $DHCPData.Servers -Filtering {
                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                New-HTMLTableCondition -Name 'DHCPResponding' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Salmon
                New-HTMLTableCondition -Name 'PingSuccessful' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                New-HTMLTableCondition -Name 'DNSResolvable' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red -Color White
                New-HTMLTableCondition -Name 'ReverseDNSValid' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Yellow
                New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Orange -HighlightHeaders 'ScopesWithIssues'
                New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                New-HTMLTableCondition -Name 'IsADDomainController' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightBlue -HighlightHeaders 'IsADDomainController'
            } -DataStore JavaScript -Title "DHCP Server Connectivity & Health Analysis"
        }

        New-HTMLSection -HeaderText "DHCP Scopes Overview" {
            New-HTMLTable -DataTable $DHCPData.Scopes -Filtering {
                New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'HasIssues', 'Issues'
                New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                New-HTMLTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackgroundColor LightYellow -HighlightHeaders 'FailoverPartner'
            } -DataStore JavaScript -ScrollX -Title "All DHCP Scopes Configuration"
        }

        # IPv6 Readiness & Status
        New-HTMLSection -HeaderText "IPv6 DHCP Status" -CanCollapse {
            New-HTMLPanel -Invisible {
                if ($DHCPData.IPv6Scopes.Count -gt 0) {
                    New-HTMLText -Text "✅ IPv6 DHCP is configured and active in this environment." -Color Green -FontWeight bold
                    New-HTMLTable -DataTable $DHCPData.IPv6Scopes -ScrollX -HideFooter -PagingLength 10 {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'HasIssues', 'Issues'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                    } -Title "IPv6 DHCP Scopes Configuration"
                } else {
                    New-HTMLText -Text "ℹ️ No IPv6 DHCP scopes found in this environment." -Color Blue -FontWeight bold
                    New-HTMLText -Text "This is normal in most environments as IPv6 DHCP is rarely deployed. Most networks use IPv6 stateless autoconfiguration (SLAAC) instead of DHCP for IPv6 address assignment." -Color Gray -FontSize 12px

                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "IPv6 DHCP Deployment Considerations:" -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Most environments use SLAAC (Stateless Address Autoconfiguration) for IPv6"
                            New-HTMLListItem -Text "IPv6 DHCP is typically only needed for stateful configuration requirements"
                            New-HTMLListItem -Text "Windows DHCP Server supports IPv6 starting with Windows Server 2008"
                            New-HTMLListItem -Text "IPv6 DHCP requires separate scope configuration from IPv4"
                        } -FontSize 11px
                    }
                }
            }
        }

        # Multicast DHCP Status
        New-HTMLSection -HeaderText "Multicast DHCP Status" -CanCollapse {
            New-HTMLPanel -Invisible {
                if ($DHCPData.MulticastScopes.Count -gt 0) {
                    New-HTMLText -Text "✅ Multicast DHCP scopes are configured in this environment." -Color Green -FontWeight bold
                    New-HTMLTable -DataTable $DHCPData.MulticastScopes -ScrollX -HideFooter -PagingLength 10 {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                    } -Title "Multicast DHCP Scopes"
                } else {
                    New-HTMLText -Text "ℹ️ No Multicast DHCP scopes found in this environment." -Color Blue -FontWeight bold
                    New-HTMLText -Text "This is typical for most environments. Multicast DHCP is specialized for applications requiring automatic multicast address assignment, such as video streaming or specialized network applications." -Color Gray -FontSize 12px

                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "Multicast DHCP Use Cases:" -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Automatic assignment of multicast IP addresses"
                            New-HTMLListItem -Text "Video streaming and multimedia applications"
                            New-HTMLListItem -Text "Network-based applications requiring group communication"
                            New-HTMLListItem -Text "Reduces manual multicast address management"
                        } -FontSize 11px
                    }
                }
            }
        }

        # Security Filters Status
        New-HTMLSection -HeaderText "Security Filters Status" -CanCollapse {
            New-HTMLPanel -Invisible {
                if ($DHCPData.SecurityFilters.Count -gt 0) {
                    New-HTMLText -Text "✅ DHCP Security filters are configured in this environment." -Color Green -FontWeight bold
                    New-HTMLTable -DataTable $DHCPData.SecurityFilters -ScrollX -HideFooter {
                        New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'None' -BackgroundColor LightYellow -HighlightHeaders 'FilteringMode'
                        New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'Allow' -BackgroundColor LightGreen -HighlightHeaders 'FilteringMode'
                        New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'Deny' -BackgroundColor Orange -HighlightHeaders 'FilteringMode'
                        New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'Both' -BackgroundColor LightBlue -HighlightHeaders 'FilteringMode'
                    } -Title "MAC Address Filtering Configuration"
                } else {
                    New-HTMLText -Text "ℹ️ No DHCP security filters configured in this environment." -Color Blue -FontWeight bold
                    New-HTMLText -Text "Security filters are optional and provide MAC address-based filtering. This feature may not be available on older DHCP servers or may not be configured for security policy reasons." -Color Gray -FontSize 12px

                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "DHCP Security Filter Options:" -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Allow List: Only specified MAC addresses can receive DHCP leases"
                            New-HTMLListItem -Text "Deny List: Specified MAC addresses are blocked from DHCP"
                            New-HTMLListItem -Text "Vendor/User Class Filtering: Filter based on DHCP client classes"
                            New-HTMLListItem -Text "Requires Windows Server 2008 R2 or later for full functionality"
                        } -FontSize 11px
                    }
                }
            }
        }

        # DHCP Policies Status
        New-HTMLSection -HeaderText "DHCP Policies Status" -CanCollapse {
            New-HTMLPanel -Invisible {
                if ($DHCPData.Policies.Count -gt 0) {
                    New-HTMLText -Text "✅ DHCP Policies are configured in this environment." -Color Green -FontWeight bold
                    New-HTMLTable -DataTable $DHCPData.Policies -ScrollX -HideFooter -PagingLength 15 {
                        New-HTMLTableCondition -Name 'Enabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'ProcessingOrder' -ComparisonType number -Operator lt -Value 5 -BackgroundColor LightBlue -HighlightHeaders 'ProcessingOrder'
                    } -Title "DHCP Policy Configuration"
                } else {
                    New-HTMLText -Text "ℹ️ No DHCP Policies configured in this environment." -Color Blue -FontWeight bold
                    New-HTMLText -Text "DHCP Policies provide advanced configuration options and require Windows Server 2012 or later. Many environments operate effectively without policies using standard scope configuration." -Color Gray -FontSize 12px

                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "DHCP Policy Capabilities (Windows Server 2012+):" -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Conditional IP address assignment based on client attributes"
                            New-HTMLListItem -Text "Different lease durations for different device types"
                            New-HTMLListItem -Text "Custom DHCP options based on vendor class or user class"
                            New-HTMLListItem -Text "Advanced filtering based on MAC address patterns or client identifiers"
                        } -FontSize 11px
                    }
                }
            }
        }

        if ($DHCPData.Reservations.Count -gt 0) {
            New-HTMLSection -HeaderText "Static Reservations" -CanCollapse {
                New-HTMLTable -DataTable $DHCPData.Reservations -ScrollX -HideFooter -PagingLength 20 {
                    New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Dhcp' -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Both' -BackgroundColor LightBlue
                } -Title "Static IP Reservations"
            }
        }

        if ($DHCPData.NetworkBindings.Count -gt 0) {
            New-HTMLSection -HeaderText "Network Bindings" -CanCollapse {
                New-HTMLTable -DataTable $DHCPData.NetworkBindings -ScrollX -HideFooter {
                    New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'True' -BackgroundColor LightGreen -FailBackgroundColor Orange
                } -Title "DHCP Server Network Interface Bindings"
            }
        }

        # Comprehensive Security and Best Practices Summary
        if ($DHCPData.ServerSettings.Count -gt 0) {
            New-HTMLSection -HeaderText "Security & Best Practices Summary" -CanCollapse {
                New-HTMLTable -DataTable $DHCPData.ServerSettings -HideFooter {
                    New-HTMLTableCondition -Name 'IsAuthorized' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red
                    New-HTMLTableCondition -Name 'ActivatePolicies' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'ConflictDetectionAttempts' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Orange -HighlightHeaders 'ConflictDetectionAttempts'
                    New-HTMLTableCondition -Name 'IsDomainJoined' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                } -Title "DHCP Server Security Configuration"
            }
        }
    }
}