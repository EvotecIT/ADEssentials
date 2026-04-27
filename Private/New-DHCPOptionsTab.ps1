function New-DHCPOptionsTab {
    <#
    .SYNOPSIS
    Creates the Options tab content for DHCP HTML report.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    New-HTMLTab -TabName '⚙️ Options' {
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
                            $IssueDetails = foreach ($Issue in $Analysis.OptionIssues) {
                                ConvertTo-DHCPOptionIssueRecord -Issue $Issue
                            }
                            $IssueSummary = $IssueDetails | Group-Object -Property Category | Sort-Object Count -Descending | ForEach-Object {
                                $sample = $_.Group | Select-Object -First 1
                                [PSCustomObject]@{
                                    Category       = $_.Name
                                    IssueCount     = $_.Count
                                    AffectedScopes = (@($_.Group.ScopeId | Where-Object { $_ } | Sort-Object -Unique)).Count
                                    AffectedServers= (@($_.Group.ServerName | Where-Object { $_ } | Sort-Object -Unique)).Count
                                    Recommendation = $sample.Recommendation
                                }
                            }

                            New-HTMLSection -HeaderText "⚠️ Configuration Issues Found" -CanCollapse {
                                New-HTMLPanel {
                                    New-HTMLText -Text "The same issues are now grouped by category first, with detailed scope-level records below." -Color DarkOrange -FontSize 12pt -FontWeight bold
                                    New-HTMLTable -DataTable $IssueSummary -Filtering {
                                        New-HTMLTableCondition -Name 'IssueCount' -ComparisonType number -Operator gt -Value 0 -BackgroundColor LightYellow -HighlightHeaders 'IssueCount'
                                    } -DataStore JavaScript -ScrollX -Title 'Issue Summary by Category'

                                    New-HTMLTable -DataTable $IssueDetails -Filtering {
                                        New-HTMLTableCondition -Name 'Category' -ComparisonType string -Operator eq -Value 'Public DNS' -BackgroundColor LightYellow
                                        New-HTMLTableCondition -Name 'Category' -ComparisonType string -Operator eq -Value 'Lease Time' -BackgroundColor Moccasin
                                        New-HTMLTableCondition -Name 'Category' -ComparisonType string -Operator eq -Value 'Domain Name' -BackgroundColor Lavender
                                    } -DataStore JavaScript -ScrollX -Title 'Issue Details'
                                }
                            }
                        }
                        
                        # Recommendations
                        if ($Analysis.OptionRecommendations.Count -gt 0) {
                            New-HTMLSection -HeaderText "💡 Recommendations" -CanCollapse {
                                New-HTMLPanel {
                                    New-HTMLList {
                                        foreach ($Recommendation in $Analysis.OptionRecommendations) {
                                            New-HTMLListItem -Text $Recommendation
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        # Server Options Table - Check both DHCPOptions and Options
        $ServerOptions = @()
        if ($DHCPData.DHCPOptions) {
            $ServerOptions = $DHCPData.DHCPOptions | Where-Object { $_.Level -eq 'Server' }
        }
        if ($ServerOptions.Count -eq 0 -and $DHCPData.Options) {
            # If no server-level options in DHCPOptions, check Options
            $ServerOptions = $DHCPData.Options | Where-Object { $_.ScopeId -eq 'Server-Level' }
        }
        if ($ServerOptions.Count -gt 0) {
            New-HTMLSection -HeaderText "🖥️ Server-Level Options" -CanCollapse {
                New-HTMLTable -DataTable $ServerOptions -Filtering {
                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 3 -BackgroundColor LightGreen -HighlightHeaders 'OptionId', 'Name'
                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 6 -BackgroundColor LightBlue -HighlightHeaders 'OptionId', 'Name'
                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 15 -BackgroundColor LightYellow -HighlightHeaders 'OptionId', 'Name'
                    New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '8.8.8.8' -BackgroundColor Orange -HighlightHeaders 'Value'
                    New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '1.1.1.1' -BackgroundColor Orange -HighlightHeaders 'Value'
                } -DataStore JavaScript -ScrollX -Title "Server-Level DHCP Options"
            }
        }

        # Scope Options Table
        $ScopeOptions = $DHCPData.Options | Where-Object { $_.ScopeId -ne 'Server-Level' }
        if ($ScopeOptions.Count -gt 0) {
            New-HTMLSection -HeaderText "📊 Scope-Level Options" -CanCollapse {
                New-HTMLTable -DataTable $ScopeOptions -Filtering {
                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 3 -BackgroundColor LightGreen -HighlightHeaders 'OptionId', 'Name'
                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 6 -BackgroundColor LightBlue -HighlightHeaders 'OptionId', 'Name'
                    New-HTMLTableCondition -Name 'OptionId' -ComparisonType number -Operator eq -Value 15 -BackgroundColor LightYellow -HighlightHeaders 'OptionId', 'Name'
                    New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '8.8.8.8' -BackgroundColor Orange -HighlightHeaders 'Value'
                    New-HTMLTableCondition -Name 'Value' -ComparisonType string -Operator contains -Value '1.1.1.1' -BackgroundColor Orange -HighlightHeaders 'Value'
                } -DataStore JavaScript -ScrollX -Title "Scope-Level DHCP Options"
            }
        }

        # No Options Configured
        if ($DHCPData.DHCPOptions.Count -eq 0 -and $DHCPData.Options.Count -eq 0) {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "No DHCP options configured" -FontSize 16pt -Color Gray
                New-HTMLText -Text "DHCP options provide essential network configuration to clients:" -FontSize 12pt -FontWeight bold
                New-HTMLList {
                    New-HTMLListItem -Text "Option 3: Router (Default Gateway)"
                    New-HTMLListItem -Text "Option 6: DNS Servers"
                    New-HTMLListItem -Text "Option 15: Domain Name"
                    New-HTMLListItem -Text "Option 42: NTP Servers"
                    New-HTMLListItem -Text "Option 66/67: TFTP Server and Boot File"
                }
            }
        }
    }
}
