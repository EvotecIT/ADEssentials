function New-DHCPFailoverTab {
    <#
    .SYNOPSIS
    Creates the Failover tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Failover tab which focuses on high availability,
    failover relationships, and redundancy analysis.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Failover tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Failover' {
        # Failover Overview at the top
        New-HTMLSection -HeaderText "🔄 High Availability Overview" {
            New-HTMLPanel -Invisible {
                # Calculate failover statistics
                $TotalFailoverRelationships = $DHCPData.FailoverRelationships.Count
                $ActiveFailovers = ($DHCPData.FailoverRelationships | Where-Object { $_.State -eq 'Normal' }).Count
                $FailoverIssues = ($DHCPData.FailoverRelationships | Where-Object { $_.State -ne 'Normal' }).Count
                $ScopesWithFailover = ($DHCPData.Scopes | Where-Object { $null -ne $_.FailoverPartner -and $_.FailoverPartner -ne '' }).Count
                $ScopesWithoutFailover = ($DHCPData.Scopes | Where-Object { $_.State -eq 'Active' -and ($null -eq $_.FailoverPartner -or $_.FailoverPartner -eq '') }).Count

                New-HTMLSection -HeaderText "Failover Health Dashboard" -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "Failover Relationships" -Number $TotalFailoverRelationships -Subtitle "Configured" -Icon "🔄" -TitleColor Blue -NumberColor DarkBlue
                    New-HTMLInfoCard -Title "Active Failovers" -Number $ActiveFailovers -Subtitle "Normal State" -Icon "✅" -TitleColor Green -NumberColor DarkGreen
                    New-HTMLInfoCard -Title "Failover Issues" -Number $FailoverIssues -Subtitle "Need Attention" -Icon "⚠️" -TitleColor $(if ($FailoverIssues -gt 0) { "Red" } else { "Green" }) -NumberColor $(if ($FailoverIssues -gt 0) { "DarkRed" } else { "DarkGreen" })
                    New-HTMLInfoCard -Title "Unprotected Scopes" -Number $ScopesWithoutFailover -Subtitle "No Failover" -Icon "🚨" -TitleColor $(if ($ScopesWithoutFailover -gt 0) { "Orange" } else { "Green" }) -NumberColor $(if ($ScopesWithoutFailover -gt 0) { "DarkOrange" } else { "DarkGreen" })
                    if ($DHCPData.FailoverAnalysis) {
                        New-HTMLInfoCard -Title "Only on Primary" -Number $($DHCPData.FailoverAnalysis.OnlyOnPrimary.Count) -Subtitle "Mismatch" -Icon "🟠" -TitleColor 'DarkOrange' -NumberColor 'DarkOrange'
                        New-HTMLInfoCard -Title "Only on Secondary" -Number $($DHCPData.FailoverAnalysis.OnlyOnSecondary.Count) -Subtitle "Mismatch" -Icon "🟠" -TitleColor 'DarkOrange' -NumberColor 'DarkOrange'
                        New-HTMLInfoCard -Title "Missing on Both" -Number $($DHCPData.FailoverAnalysis.MissingOnBoth.Count) -Subtitle "Gap" -Icon "⚠️" -TitleColor 'OrangeRed' -NumberColor 'OrangeRed'
                    }
                }

                # Failover coverage chart
                if ($DHCPData.Scopes.Count -gt 0) {
                    New-HTMLChart -Title "Failover Coverage Analysis" {
                        New-ChartPie -Name "With Failover" -Value $ScopesWithFailover -Color '#00FF00'
                        New-ChartPie -Name "Without Failover" -Value $ScopesWithoutFailover -Color '#FF6347'
                    } -Height 300
                }
            }
        }

        # Failover Relationships Details
        if ($DHCPData.FailoverRelationships.Count -gt 0) {
            New-HTMLSection -HeaderText "🤝 Failover Relationships" {
                New-HTMLTable -DataTable $DHCPData.FailoverRelationships -Filtering {
                    New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Normal' -BackgroundColor LightGreen -FailBackgroundColor Orange
                    New-HTMLTableCondition -Name 'Mode' -ComparisonType string -Operator eq -Value 'LoadBalance' -BackgroundColor LightBlue -HighlightHeaders 'Mode', 'LoadBalancePercent'
                    New-HTMLTableCondition -Name 'Mode' -ComparisonType string -Operator eq -Value 'HotStandby' -BackgroundColor LightYellow -HighlightHeaders 'Mode'
                    New-HTMLTableCondition -Name 'EnableAuth' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red -Color White
                } -DataStore JavaScript -ScrollX -Title "All Failover Relationships"
            }

            # Pair-wise analysis views
            New-HTMLSection -HeaderText "🔎 Relationship Pair View" -CanCollapse {
                # Build pairs keyed by normalized server tuple + relationship name
                $Pairs = @{}
                foreach ($rel in $DHCPData.FailoverRelationships) {
                    $a = $rel.ServerName.ToLower()
                    $b = $rel.PartnerServer.ToLower()
                    $sorted = @($a, $b) | Sort-Object
                    $key = "$($rel.Name.ToLower())|$($sorted -join '↔')"
                    if (-not $Pairs.ContainsKey($key)) {
                        $Pairs[$key] = [ordered]@{
                            Name    = $rel.Name
                            ServerA = $sorted[0]
                            ServerB = $sorted[1]
                            RelA    = $null
                            RelB    = $null
                        }
                    }
                    if ($rel.ServerName.ToLower() -eq $Pairs[$key].ServerA) { $Pairs[$key].RelA = $rel } else { $Pairs[$key].RelB = $rel }
                }

                foreach ($pair in $Pairs.Values) {
                    $relA = $pair.RelA
                    $relB = $pair.RelB
                    $scopesA = if ($relA -and $relA.ScopeId) { @($relA.ScopeId) } else { @() }
                    $scopesB = if ($relB -and $relB.ScopeId) { @($relB.ScopeId) } else { @() }

                    # All scopes hosted on both servers (for missing-on-both detection)
                    $serverScopes = $DHCPData.Scopes | Where-Object { $_.ServerName -and ($_.ServerName.ToLower() -in @($pair.ServerA, $pair.ServerB)) }
                    $scopesOnServers = @($serverScopes | Select-Object -ExpandProperty ScopeId -Unique)
                    $allScopes = @($scopesA + $scopesB + $scopesOnServers) | Select-Object -Unique

                    $rows = foreach ($s in $allScopes) {
                        $onA = $scopesA -contains $s
                        $onB = $scopesB -contains $s
                        $status = if ($onA -and $onB) { 'On both' } elseif ($onA) { 'Only on Primary' } elseif ($onB) { 'Only on Secondary' } else { 'Missing on both' }
                        $failoverConfig = switch ($status) {
                            'Only on Primary' { 'missing on secondary' }
                            'Only on Secondary' { 'missing on primary' }
                            'Missing on both' { 'missing on both' }
                            default { 'configured' }
                        }
                        [PSCustomObject]@{
                            Relationship          = $pair.Name
                            PrimaryServer         = $pair.ServerA
                            SecondaryServer       = $pair.ServerB
                            ScopeId               = $s
                            OnPrimary             = $onA
                            OnSecondary           = $onB
                            Status                = $status
                            FailoverConfiguration = $failoverConfig
                        }
                    }

                    New-HTMLSection -HeaderText "$($pair.Name) — $($pair.ServerA) ↔ $($pair.ServerB)" {
                        New-HTMLTable -DataTable $rows -Filtering {
                            New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Only on Primary' -BackgroundColor LightYellow
                            New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Only on Secondary' -BackgroundColor LightYellow
                            New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Missing on both' -BackgroundColor Orange
                        } -DataStore JavaScript -ScrollX -Title "Scope Assignment Comparison"
                    }
                }
            }

        }

        # High Availability Recommendations
        New-HTMLSection -HeaderText "💡 High Availability Recommendations" {
            New-HTMLPanel -Invisible {
                # Critical recommendations for scopes without failover
                if ($ScopesWithoutFailover -gt 0) {
                    New-HTMLText -Text "🚨 Critical Recommendations:" -FontSize 16pt -FontWeight bold -Color Red
                    New-HTMLList {
                        New-HTMLListItem -Text "$ScopesWithoutFailover active scope(s) have no failover configuration"
                        New-HTMLListItem -Text "Configure DHCP failover for all production scopes to ensure service availability"
                        New-HTMLListItem -Text "Consider Load Balance mode for even distribution or Hot Standby for primary/backup scenarios"
                    }
                }

                # Best practices
                # New-HTMLText -Text "✅ DHCP Failover Best Practices:" -FontSize 16pt -FontWeight bold -Color Blue
                # New-HTMLList {
                #     New-HTMLListItem -Text "Use Load Balance mode (50/50) for most scenarios to distribute load evenly"
                #     New-HTMLListItem -Text "Configure Hot Standby mode for scenarios requiring a primary/backup configuration"
                #     New-HTMLListItem -Text "Enable authentication between failover partners for security"
                #     New-HTMLListItem -Text "Monitor failover state regularly and configure alerts for state changes"
                #     New-HTMLListItem -Text "Test failover scenarios periodically to ensure proper configuration"
                #     New-HTMLListItem -Text "Keep Maximum Client Lead Time (MCLT) at default (1 hour) unless specific requirements exist"
                #     New-HTMLListItem -Text "Configure State Switchover Interval based on network reliability (default: 5 minutes)"
                # }

                # Failover modes explanation
                # New-HTMLText -Text "📚 Failover Modes Explained:" -FontSize 16pt -FontWeight bold -Color Blue
                New-HTMLSection -Invisible {
                    New-HTMLPanel {
                        New-HTMLText -Text "Load Balance Mode" -FontSize 14pt -FontWeight bold -Color DarkBlue
                        New-HTMLText -Text "Both servers actively respond to DHCP requests based on configured percentage" -FontSize 12pt
                        New-HTMLList {
                            New-HTMLListItem -Text "Default: 50/50 split of client requests"
                            New-HTMLListItem -Text "Provides active-active configuration"
                            New-HTMLListItem -Text "Best for redundancy and load distribution"
                        }
                    } -Width '48%'

                    New-HTMLPanel {
                        New-HTMLText -Text "Hot Standby Mode" -FontSize 14pt -FontWeight bold -Color DarkBlue
                        New-HTMLText -Text "Primary server handles all requests; standby activates on failure" -FontSize 12pt
                        New-HTMLList {
                            New-HTMLListItem -Text "Primary server handles 100% of requests"
                            New-HTMLListItem -Text "Standby server activates only on primary failure"
                            New-HTMLListItem -Text "Best for specific server preference scenarios"
                        }
                    } -Width '48%'
                }
            }
        }

        # Scope Redundancy Analysis
        if ($DHCPData.ScopeRedundancyAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "📊 Scope Redundancy Analysis" {
                New-HTMLTable -DataTable $DHCPData.ScopeRedundancyAnalysis -Filtering {
                    New-HTMLTableCondition -Name 'RedundancyStatus' -ComparisonType string -Operator eq -Value 'Failover Configured' -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'RedundancyStatus' -ComparisonType string -Operator contains -Value 'Risk' -BackgroundColor Salmon
                    New-HTMLTableCondition -Name 'RiskLevel' -ComparisonType string -Operator eq -Value 'High' -BackgroundColor Red -Color White
                    New-HTMLTableCondition -Name 'RiskLevel' -ComparisonType string -Operator eq -Value 'Medium' -BackgroundColor Orange
                    New-HTMLTableCondition -Name 'RiskLevel' -ComparisonType string -Operator eq -Value 'Low' -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Orange -HighlightHeaders 'UtilizationPercent'
                } -DataStore JavaScript -ScrollX -Title "Scope-Level Redundancy Status"
            }
        }
    }
}
