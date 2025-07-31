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
            New-HTMLSection -HeaderText "Critical Issues" -BackgroundColor '#ffe0e0' -HeaderTextColor '#8b0000' -Density Compact {
                # Public DNS with Updates
                if ($DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "⚠️ Public DNS Servers with Dynamic Updates Enabled" -FontSize 14pt -FontWeight bold -Color '#cc0000'
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates -Filtering {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        } -DataStore JavaScript -ScrollX
                    }
                }
                
                # Servers Offline
                if ($DHCPData.ValidationResults.CriticalIssues.ServersOffline.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "⚠️ Offline DHCP Servers" -FontSize 14pt -FontWeight bold -Color '#cc0000'
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.CriticalIssues.ServersOffline -Filtering -DataStore JavaScript
                    }
                }
            }
        }
        
        # Note about utilization
        if ($DHCPData.ValidationResults.Summary.TotalUtilizationIssues -gt 0) {
            New-HTMLSection -HeaderText "Utilization Alert" -BackgroundColor '#fff3e0' -HeaderTextColor '#ff6600' {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "🔴 $($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count) scope(s) with critical utilization (>90%)" -FontSize 14pt -FontWeight bold -Color Red
                    New-HTMLText -Text "🟠 $($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count) scope(s) with high utilization (75-90%)" -FontSize 14pt -FontWeight bold -Color DarkOrange
                    New-HTMLText -Text "➡️ See the Utilization tab for detailed analysis and capacity planning" -FontSize 12pt -Color Blue
                }
            }
        }

        # Warning Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) {
            New-HTMLSection -HeaderText "Warning Issues" -BackgroundColor '#fff9e6' -HeaderTextColor '#cc8800' -Density Compact {
                # Missing Failover
                if ($DHCPData.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "⚡ Active Scopes without Failover Configuration" -FontSize 14pt -FontWeight bold -Color DarkOrange
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.WarningIssues.MissingFailover -Filtering {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        } -DataStore JavaScript -ScrollX
                    }
                }
                
                # Extended Lease Duration
                if ($DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "⏱️ Scopes with Extended Lease Duration (>48 hours)" -FontSize 14pt -FontWeight bold -Color DarkOrange
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration -Filtering {
                            New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 168 -BackgroundColor Salmon -HighlightHeaders 'LeaseDurationHours'
                            New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                        } -DataStore JavaScript -ScrollX
                    }
                }
                
                # DNS Record Management Issues
                if ($DHCPData.ValidationResults.WarningIssues.DNSRecordManagement.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "🔧 DNS Record Management Issues" -FontSize 14pt -FontWeight bold -Color DarkOrange
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.WarningIssues.DNSRecordManagement -Filtering -DataStore JavaScript -ScrollX
                    }
                }
            }
        }

        # Information Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalInfoIssues -gt 0) {
            New-HTMLSection -HeaderText "Information Issues" -BackgroundColor '#e6f3ff' -HeaderTextColor '#0066cc' {
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