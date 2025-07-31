function New-DHCPValidationIssuesTab {
    <#
    .SYNOPSIS
    Creates the Validation Issues tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Validation Issues tab which includes scopes with issues,
    high utilization scopes, critical utilization, scopes without failover, and inactive scopes.

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
        # Calculate total issues from validation results
        $TotalIssuesCount = $DHCPData.ValidationResults.Summary.TotalCriticalIssues + 
                           $DHCPData.ValidationResults.Summary.TotalUtilizationIssues + 
                           $DHCPData.ValidationResults.Summary.TotalWarningIssues + 
                           $DHCPData.ValidationResults.Summary.TotalInfoIssues
        
        if ($TotalIssuesCount -eq 0) {
            New-HTMLSection -HeaderText "Validation Status" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "✅ No validation issues found" -Color Green -FontSize 16pt -FontWeight bold
                    New-HTMLText -Text "All DHCP servers and scopes appear to be properly configured and operating within normal parameters." -FontSize 12pt
                }
            }
        }

        # Critical Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0) {
            New-HTMLSection -HeaderText "Critical Issues" -BackgroundColor '#ffe0e0' -HeaderTextColor '#8b0000' {
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

        # Utilization Issues Section (new separate category)
        if ($DHCPData.ValidationResults.Summary.TotalUtilizationIssues -gt 0) {
            New-HTMLSection -HeaderText "Utilization Issues" -BackgroundColor '#fff3e0' -HeaderTextColor '#ff6600' {
                # High Utilization (>90%)
                if ($DHCPData.ValidationResults.UtilizationIssues.HighUtilization.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "🔴 Critical Utilization Scopes (>90%)" -FontSize 14pt -FontWeight bold -Color '#cc3300'
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.UtilizationIssues.HighUtilization -Filtering {
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 95 -BackgroundColor Red -HighlightHeaders 'PercentageInUse'
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                        } -DataStore JavaScript -ScrollX
                    }
                }
                
                # Moderate Utilization (75-90%)
                if ($DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization.Count -gt 0) {
                    New-HTMLContainer {
                        New-HTMLText -Text "🟠 High Utilization Scopes (75-90%)" -FontSize 14pt -FontWeight bold -Color '#ff6600'
                        New-HTMLTable -DataTable $DHCPData.ValidationResults.UtilizationIssues.ModerateUtilization -Filtering {
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 85 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Yellow -HighlightHeaders 'PercentageInUse'
                        } -DataStore JavaScript -ScrollX
                    }
                }
            }
        }

        # Warning Issues Section
        if ($DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) {
            New-HTMLSection -HeaderText "Warning Issues" -BackgroundColor '#fff9e6' -HeaderTextColor '#cc8800' {
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