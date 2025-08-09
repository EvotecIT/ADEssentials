function New-DHCPOptionsClassesTab {
    <#
    .SYNOPSIS
    Creates the Options & Classes tab content for DHCP HTML report with nested tabs.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    New-HTMLTab -TabName 'Options & Classes' {
        # Create nested tabs for Options and Classes
        New-HTMLTabPanel {
            # DHCP Options Tab
            New-HTMLTab -TabName 'Options' {
                # Options Health Dashboard at the top
                if ($DHCPData.OptionsAnalysis.Count -gt 0) {
                    New-HTMLSection -HeaderText "⚙️ DHCP Options Health Dashboard" {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "DHCP Options Configuration Analysis" -FontSize 18pt -FontWeight bold -Color DarkBlue
                            New-HTMLText -Text "Critical analysis of DHCP options configuration across all servers and scopes." -FontSize 12pt -Color DarkGray

                            foreach ($Analysis in $DHCPData.OptionsAnalysis) {
                                # Health Overview Cards
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

                                # Missing Critical Options
                                if ($Analysis.MissingCriticalOptions.Count -gt 0) {
                                    New-HTMLSection -HeaderText "🚨 Missing Critical Options" -CanCollapse {
                                        New-HTMLPanel {
                                            New-HTMLText -Text "The following critical DHCP options are not configured:" -FontSize 12pt -Color DarkRed -FontWeight bold
                                            foreach ($MissingOption in $Analysis.MissingCriticalOptions) {
                                                New-HTMLText -Text "🔴 $MissingOption" -Color Red -FontSize 14px
                                            }
                                        }
                                    }
                                }

                                # Configuration Issues
                                if ($Analysis.OptionIssues.Count -gt 0) {
                                    New-HTMLSection -HeaderText "⚠️ Configuration Issues Found" -CanCollapse {
                                        New-HTMLPanel {
                                            foreach ($Issue in $Analysis.OptionIssues) {
                                                New-HTMLText -Text "⚠️ $Issue" -Color Orange -FontSize 14px
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                # Server-Level Options
                if ($DHCPData.DHCPOptions.Count -gt 0) {
                    New-HTMLSection -HeaderText "🖥️ Server-Level DHCP Options" -CanCollapse {
                        $ServerOptions = $DHCPData.DHCPOptions | Group-Object ServerName
                        foreach ($ServerGroup in $ServerOptions) {
                            New-HTMLPanel {
                                New-HTMLTable -DataTable $ServerGroup.Group -Filtering {
                                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 6 -BackgroundColor LightBlue -HighlightHeaders 'OptionId', 'Name'
                                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 3 -BackgroundColor LightGreen -HighlightHeaders 'OptionId', 'Name'
                                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 15 -BackgroundColor LightYellow -HighlightHeaders 'OptionId', 'Name'
                                    New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '8.8.8.8' -BackgroundColor Orange -HighlightHeaders 'Value'
                                    New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '1.1.1.1' -BackgroundColor Orange -HighlightHeaders 'Value'
                                } -Title "Server Options for $($ServerGroup.Name)"
                            }
                        }
                    }
                }

                # Scope-Level Options
                if ($DHCPData.Options.Count -gt 0) {
                    New-HTMLSection -HeaderText "📁 Scope-Level DHCP Options" -CanCollapse {
                        New-HTMLTable -DataTable $DHCPData.Options -Filtering {
                            New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 6 -BackgroundColor LightBlue -HighlightHeaders 'OptionId', 'Name'
                            New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 3 -BackgroundColor LightGreen -HighlightHeaders 'OptionId', 'Name'
                            New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '8.8.8.8' -BackgroundColor Orange -HighlightHeaders 'Value'
                        } -Title "All Scope-Level Options" -DataStore JavaScript -ScrollX
                    }
                }
            }

            # DHCP Classes Tab
            New-HTMLTab -TabName 'Classes' {
                # Classes Overview at the top
                if ($DHCPData.DHCPClasses.Count -gt 0) {
                    New-HTMLSection -HeaderText "📋 DHCP Classes Overview" {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Vendor & User Classes Configuration" -FontSize 16pt -FontWeight bold -Color DarkBlue
                            New-HTMLText -Text "DHCP classes allow different configuration based on client type." -FontSize 12pt -Color DarkGray

                            # Summary statistics
                            $VendorClasses = ($DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'Vendor' }).Count
                            $UserClasses = ($DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'User' }).Count
                            $TotalServers = ($DHCPData.DHCPClasses | Group-Object ServerName).Count

                            New-HTMLSection -HeaderText "Classes Summary" -Invisible -Density Compact {
                                New-HTMLInfoCard -Title "Total Classes" -Number $DHCPData.DHCPClasses.Count -Subtitle "Configured" -Icon "📋" -TitleColor Purple -NumberColor DarkMagenta
                                New-HTMLInfoCard -Title "Vendor Classes" -Number $VendorClasses -Subtitle "Device Manufacturers" -Icon "🏭" -TitleColor Blue -NumberColor DarkBlue
                                New-HTMLInfoCard -Title "User Classes" -Number $UserClasses -Subtitle "Custom Categories" -Icon "👥" -TitleColor Green -NumberColor DarkGreen
                                New-HTMLInfoCard -Title "Servers" -Number $TotalServers -Subtitle "With Classes" -Icon "🖥️" -TitleColor Orange -NumberColor DarkOrange
                            }
                        }
                    }
                }

                # Vendor Classes
                $VendorClassData = $DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'Vendor' }
                if ($VendorClassData.Count -gt 0) {
                    New-HTMLSection -HeaderText "🏭 Vendor Classes" -CanCollapse {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Vendor classes identify device manufacturers and types" -FontSize 12pt
                            New-HTMLTable -DataTable $VendorClassData -Filtering {
                                New-HTMLTableCondition -Name 'Name' -ComparisonType string -Operator contains -Value 'Microsoft' -BackgroundColor LightYellow -HighlightHeaders 'Name'
                                New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Vendor' -BackgroundColor LightBlue -HighlightHeaders 'Type'
                            } -DataStore JavaScript
                        }
                    }
                }

                # User Classes
                $UserClassData = $DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'User' }
                if ($UserClassData.Count -gt 0) {
                    New-HTMLSection -HeaderText "👥 User Classes" -CanCollapse {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "User classes provide custom device categorization" -FontSize 12pt
                            New-HTMLTable -DataTable $UserClassData -Filtering {
                                New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'User' -BackgroundColor LightGreen -HighlightHeaders 'Type'
                            } -DataStore JavaScript
                        }
                    }
                }

                # All Classes Table
                if ($DHCPData.DHCPClasses.Count -gt 0) {
                    New-HTMLSection -HeaderText "📊 All DHCP Classes" -CanCollapse {
                        New-HTMLTable -DataTable $DHCPData.DHCPClasses -Filtering {
                            New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Vendor' -BackgroundColor LightBlue -HighlightHeaders 'Type'
                            New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'User' -BackgroundColor LightGreen -HighlightHeaders 'Type'
                            New-HTMLTableCondition -Name 'Name' -ComparisonType string -Operator contains -Value 'Microsoft' -BackgroundColor LightYellow -HighlightHeaders 'Name'
                        } -DataStore JavaScript -ScrollX -Title "Complete Classes Configuration"
                    }
                } else {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "No DHCP classes configured" -FontSize 14pt -Color Gray
                        New-HTMLText -Text "DHCP classes can be used for:" -FontSize 12pt -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Different configurations for different device types"
                            New-HTMLListItem -Text "Vendor-specific options (e.g., VoIP phones)"
                            New-HTMLListItem -Text "Custom grouping of devices"
                            New-HTMLListItem -Text "Policy-based option assignment"
                        }
                    }
                }
            }
        }
    }
}