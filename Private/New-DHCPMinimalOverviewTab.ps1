function New-DHCPMinimalOverviewTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPData
    )

    New-HTMLTab -TabName 'Overview' {
        New-HTMLSection -Invisible {
            New-HTMLSection -HeaderText "DHCP Validation Summary" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Validation Report Focus" -FontSize 16px -FontWeight bold
                    New-HTMLText -Text "This minimal report focuses on critical DHCP configuration validation based on DHCL_validatorV2.ps1 requirements:" -FontSize 12px
                    New-HTMLList {
                        New-HTMLListItem -Text "Lease Duration: ", "Validates scopes with lease time > 48 hours" -FontWeight bold, normal
                        New-HTMLListItem -Text "DNS Configuration: ", "Checks for public DNS servers and missing domain options" -FontWeight bold, normal
                        New-HTMLListItem -Text "Failover Status: ", "Identifies scopes without proper failover configuration" -FontWeight bold, normal
                    } -FontSize 12px
                }
            }
        }

        # Status Cards Row
        New-HTMLSection -HeaderText "Validation Status" -Wrap wrap {
            New-HTMLSection -HeaderText "Infrastructure Overview" -Invisible -Density Compact {
                New-HTMLInfoCard -Title "Servers Checked" -Number $DHCPData.Statistics.TotalServers -Subtitle "DHCP Servers" -Icon "🖥️" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                New-HTMLInfoCard -Title "Total Scopes" -Number $DHCPData.Statistics.TotalScopes -Subtitle "Configured Scopes" -Icon "🔍" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'

                $IssueColor = if ($DHCPData.ScopesWithIssues.Count -eq 0) { 'Green' } elseif ($DHCPData.ScopesWithIssues.Count -le 5) { 'Orange' } else { 'Red' }
                $IssueIcon = if ($DHCPData.ScopesWithIssues.Count -eq 0) { '✅' } else { '⚠️' }
                New-HTMLInfoCard -Title "Issues Found" -Number $DHCPData.ScopesWithIssues.Count -Subtitle "Configuration Issues" -Icon $IssueIcon -TitleColor $IssueColor -NumberColor $IssueColor -ShadowColor "rgba(255, 0, 0, 0.15)"

                $Status = if ($DHCPData.ScopesWithIssues.Count -eq 0) { 'PASSED' } else { 'FAILED' }
                $StatusColor = if ($DHCPData.ScopesWithIssues.Count -eq 0) { 'Green' } else { 'Red' }
                $StatusIcon = if ($DHCPData.ScopesWithIssues.Count -eq 0) { '✅' } else { '❌' }
                New-HTMLInfoCard -Title "Validation" -Number $Status -Subtitle "Overall Status" -Icon $StatusIcon -TitleColor $StatusColor -NumberColor $StatusColor -ShadowColor "rgba(0, 255, 0, 0.15)"
            }

            # Validation categories chart
            if ($DHCPData.ScopesWithIssues.Count -gt 0) {
                $LeaseDurationCount = ($DHCPData.ScopesWithIssues | Where-Object { $_.Issues -contains 'Lease duration greater than 48 hours' }).Count
                $DNSConfigCount = ($DHCPData.ScopesWithIssues | Where-Object {
                        $_.Issues -contains 'DNS updates enabled with public DNS servers' -or
                        $_.Issues -contains 'DNS updates enabled but missing domain name option' -or
                        $_.Issues -contains 'DNS update settings misconfigured'
                    }).Count
                $FailoverCount = ($DHCPData.ScopesWithIssues | Where-Object { $_.Issues -contains 'Missing DHCP failover configuration' }).Count

                New-HTMLSection -HeaderText "Issue Categories" -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "Lease Duration" -Number $LeaseDurationCount -Subtitle "Scopes > 48 hours" -Icon "⏱️" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.15)'
                    New-HTMLInfoCard -Title "DNS Config" -Number $DNSConfigCount -Subtitle "DNS Issues" -Icon "🌐" -TitleColor 'OrangeRed' -NumberColor 'Red' -ShadowColor 'rgba(255, 69, 0, 0.15)'
                    New-HTMLInfoCard -Title "Failover" -Number $FailoverCount -Subtitle "Missing Failover" -Icon "🔄" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.15)'
                }
            }
        }

        # Quick recommendations section
        if ($DHCPData.ScopesWithIssues.Count -gt 0) {
            New-HTMLSection -HeaderText '🚨 Priority Actions Required' {
                New-HTMLPanel -Invisible {
                    $LeaseDurationCount = ($DHCPData.ScopesWithIssues | Where-Object { $_.Issues -contains 'Lease duration greater than 48 hours' }).Count
                    $DNSCount = ($DHCPData.ScopesWithIssues | Where-Object { $_.Issues -match 'DNS' }).Count
                    $FailoverCount = ($DHCPData.ScopesWithIssues | Where-Object { $_.Issues -match 'failover' }).Count

                    New-HTMLText -Text 'IMMEDIATE ACTIONS REQUIRED' -Color Red -FontSize 18px -FontWeight bold
                    New-HTMLList {
                        if ($LeaseDurationCount -gt 0) {
                            New-HTMLListItem -Text "🔴 Review and adjust $LeaseDurationCount scope(s) with lease duration > 48 hours" -Color Red -FontWeight bold
                        }
                        if ($DNSCount -gt 0) {
                            New-HTMLListItem -Text "🔴 Fix DNS configuration issues in $DNSCount scope(s)" -Color Red -FontWeight bold
                        }
                        if ($FailoverCount -gt 0) {
                            New-HTMLListItem -Text "🔴 Configure failover for $FailoverCount scope(s) to ensure high availability" -Color Red -FontWeight bold
                        }
                    } -FontSize 14px
                }
            }
        } else {
            New-HTMLSection -HeaderText '✅ Validation Status' {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text 'All Validations Passed' -Color Green -FontSize 18px -FontWeight bold
                    New-HTMLText -Text 'No configuration issues detected. Your DHCP infrastructure meets all validation requirements.' -Color Green -FontSize 14px
                }
            }
        }
        
        # Server validation summary
        New-HTMLSection -Invisible {
            New-HTMLSection -HeaderText "Server Validation Results" {
                $ServerSummary = foreach ($Server in $DHCPData.Servers) {
                    $ServerScopes = $DHCPData.Scopes | Where-Object { $_.ServerName -eq $Server.ServerName }
                    $ServerIssues = $DHCPData.ScopesWithIssues | Where-Object { $_.ServerName -eq $Server.ServerName }

                    [PSCustomObject]@{
                        ServerName       = $Server.ServerName
                        Status           = $Server.Status
                        TotalScopes      = $ServerScopes.Count
                        ScopesWithIssues = $ServerIssues.Count
                        ValidationStatus = if ($ServerIssues.Count -eq 0) { '✅ Passed' } else { "⚠️ $($ServerIssues.Count) Issues" }
                        IssueTypes       = if ($ServerIssues.Count -gt 0) {
                            $Types = @()
                            if ($ServerIssues | Where-Object { $_.Issues -contains 'Lease duration greater than 48 hours' }) { $Types += 'Lease' }
                            if ($ServerIssues | Where-Object { $_.Issues -match 'DNS' }) { $Types += 'DNS' }
                            if ($ServerIssues | Where-Object { $_.Issues -match 'failover' }) { $Types += 'Failover' }
                            $Types -join ', '
                        } else { 'None' }
                    }
                }

                New-HTMLTable -DataTable $ServerSummary {
                    New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator ne -Value 'Online' -BackgroundColor Salmon
                    New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator eq -Value 0 -BackgroundColor LightGreen -HighlightHeaders 'ValidationStatus'
                    New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Yellow -HighlightHeaders 'ValidationStatus'
                    New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 5 -BackgroundColor Orange -HighlightHeaders 'ValidationStatus'
                } -ScrollX -Title "Server Validation Summary"
            }
        }
    }
}