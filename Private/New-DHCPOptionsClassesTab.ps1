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