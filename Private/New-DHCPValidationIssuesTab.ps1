function New-DHCPValidationIssuesTab {
    <#
    .SYNOPSIS
    Creates the Validation Issues tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Validation Issues tab which includes critical issues,
    warning issues, and informational issues. Utilization issues are shown in the dedicated
    Utilization tab for comprehensive analysis.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Validation Issues tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Validation Issues' {
        # Calculate total issues from validation results (excluding utilization which has its own tab)
        $TotalIssuesCount = $DHCPData.ValidationResults.Summary.TotalCriticalIssues +
        $DHCPData.ValidationResults.Summary.TotalWarningIssues +
        $DHCPData.ValidationResults.Summary.TotalInfoIssues

        if ($TotalIssuesCount -eq 0) {
            New-HTMLSection -HeaderText "Validation Status" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "✅ No validation issues found" -Color Green -FontSize 16pt -FontWeight bold
                    New-HTMLText -Text "All DHCP servers and scopes appear to be properly configured and operating within normal parameters." -FontSize 12pt
                    New-HTMLText -Text "Note: Check the Utilization tab for capacity planning and utilization analysis." -FontSize 11pt -Color Blue
                }
            }
        }

        # Critical Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0) {
            New-HTMLSection -HeaderText "Critical Issues" -HeaderTextColor '#8b0000' -Density Compact {
                # Public DNS with Updates
                if ($DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count -gt 0) {
                    # New-HTMLSection -Invisible {
                    New-HTMLText -Text "⚠️ Public DNS Servers with Dynamic Updates Enabled" -FontSize 14pt -FontWeight bold -Color '#cc0000'
                    New-HTMLTable -DataTable $DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates -Filtering {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                    } -DataStore JavaScript -ScrollX
                    # }
                }

                # DNS configuration problems (aggregated when policy enabled)
                if ($DHCPData.ValidationResults.CriticalIssues.DNSConfigurationProblems.Count -gt 0) {
                    #New-HTMLSection -Invisible {
                    New-HTMLText -Text "⚠️ Scopes with DNS Configuration Problems" -FontSize 14pt -FontWeight bold -Color '#cc0000'
                    New-HTMLTable -DataTable $DHCPData.ValidationResults.CriticalIssues.DNSConfigurationProblems -Filtering -DataStore JavaScript -ScrollX
                    #}
                }

                # Servers Offline
                if ($DHCPData.ValidationResults.CriticalIssues.ServersOffline.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "⚠️ Offline DHCP Servers" -FontSize 14pt -FontWeight bold -Color '#cc0000'
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.CriticalIssues.ServersOffline -Filtering -DataStore JavaScript
                    }
                }

                # Failover only on primary (means missing on secondary) — critical
                if ($DHCPData.ValidationResults.CriticalIssues.FailoverOnlyOnPrimary.Count -gt 0) {
                    New-HTMLSection -HeaderText "🔴 Failover Scope Mismatches: Present only on Primary (missing on secondary)" -CanCollapse {
                        $data = $DHCPData.ValidationResults.CriticalIssues.FailoverOnlyOnPrimary | ForEach-Object {
                            [PSCustomObject]@{
                                Relationship          = $_.Relationship
                                PrimaryServer         = $_.PrimaryServer
                                SecondaryServer       = $_.SecondaryServer
                                ScopeId               = $_.ScopeId
                                FailoverConfiguration = 'missing on secondary'
                                Issue                 = $_.Issue
                            }
                        }
                        New-HTMLTable -DataTable $data -Filtering {
                            New-HTMLTableCondition -Name 'FailoverConfiguration' -ComparisonType string -Operator contains -Value 'missing' -BackgroundColor Salmon
                        } -DataStore JavaScript -ScrollX
                    }
                }

                # Missing on both partners — critical
                if ($DHCPData.ValidationResults.CriticalIssues.FailoverMissingOnBoth.Count -gt 0) {
                    New-HTMLSection -HeaderText "🔴 Scopes Missing from Failover on Both Partners" -CanCollapse {
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.CriticalIssues.FailoverMissingOnBoth -Filtering {
                            New-HTMLTableCondition -Name 'Issue' -ComparisonType string -Operator contains -Value 'both' -BackgroundColor Salmon -HighlightHeaders 'Issue'
                        } -DataStore JavaScript -ScrollX
                    }
                }
            }
        }

        # Warning Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) {
            New-HTMLSection -HeaderText "Warning Issues" -HeaderTextColor '#cc8800' -Density Compact {
                # Missing Failover
                if ($DHCPData.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
                    New-HTMLSection -HeaderText "⚡ Active Scopes without Failover Configuration" -CanCollapse {
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.WarningIssues.MissingFailover -Filtering {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        } -DataStore JavaScript -ScrollX
                    }
                }

                # NOTE: 'Failover only on primary' moved to Critical section

                # Failover only on secondary
                if ($DHCPData.ValidationResults.WarningIssues.FailoverOnlyOnSecondary.Count -gt 0) {
                    New-HTMLSection -HeaderText "🔄 Failover Scope Mismatches: Present only on Secondary" -CanCollapse {
                        $data = $DHCPData.ValidationResults.WarningIssues.FailoverOnlyOnSecondary | ForEach-Object {
                            [PSCustomObject]@{
                                Relationship          = $_.Relationship
                                PrimaryServer         = $_.PrimaryServer
                                SecondaryServer       = $_.SecondaryServer
                                ScopeId               = $_.ScopeId
                                FailoverConfiguration = 'missing on primary'
                                Issue                 = $_.Issue
                            }
                        }
                        New-HTMLTable -DataTable $data -Filtering {
                            New-HTMLTableCondition -Name 'FailoverConfiguration' -ComparisonType string -Operator contains -Value 'missing' -BackgroundColor LightYellow
                        } -DataStore JavaScript -ScrollX
                    }
                }

                # NOTE: 'Missing on both' moved to Critical section

                # Extended Lease Duration
                if ($DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count -gt 0) {
                    New-HTMLSection -HeaderText "Scopes with Extended Lease Duration (>48 hours)" -CanCollapse {
                        # Title moved to section header
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration -Filtering {
                            New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 168 -BackgroundColor Salmon -HighlightHeaders 'LeaseDurationHours'
                            New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                        } -DataStore JavaScript -ScrollX
                    }
                }

                # DNS Record Management Issues
                if ($DHCPData.ValidationResults.WarningIssues.DNSRecordManagement.Count -gt 0) {
                    New-HTMLSection -HeaderText "DNS Record Management Issues" -CanCollapse {
                        # Title moved to section header
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.WarningIssues.DNSRecordManagement -Filtering -DataStore JavaScript -ScrollX
                    }
                }
            }
        }

        # Information Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalInfoIssues -gt 0) {
            New-HTMLSection -HeaderText "Information Issues" -BackgroundColor '#e6f3ff' -HeaderTextColor '#0066cc' -Density Compact {
                # Missing Domain Name
                if ($DHCPData.ValidationResults.InfoIssues.MissingDomainName.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "ℹ️ Scopes Missing Domain Name Option" -FontSize 14pt -FontWeight bold -Color DarkBlue
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.InfoIssues.MissingDomainName -Filtering -DataStore JavaScript -ScrollX
                    }
                }

                # Inactive Scopes
                if ($DHCPData.ValidationResults.InfoIssues.InactiveScopes.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "💤 Inactive DHCP Scopes" -FontSize 14pt -FontWeight bold -Color DarkBlue
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.InfoIssues.InactiveScopes -Filtering {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator ne -Value 'Active' -BackgroundColor LightYellow -HighlightHeaders 'State'
                        } -DataStore JavaScript -ScrollX
                    }
                }
            }
        }
    }
}
