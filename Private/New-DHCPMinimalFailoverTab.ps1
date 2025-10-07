function New-DHCPMinimalFailoverTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPData
    )

    New-HTMLTab -TabName 'Failover Status' {
        # Get failover data
        $FailoverRelationships = if ($DHCPData.FailoverRelationships) { $DHCPData.FailoverRelationships } else { @() }
        $ScopesWithFailover = $DHCPData.Scopes | Where-Object { $_.FailoverPartner }
        $ScopesWithoutFailover = $DHCPData.Scopes | Where-Object { -not $_.FailoverPartner -and $_.State -eq 'Active' }
        $CoveragePercent = if ($DHCPData.Scopes.Count -gt 0) { [Math]::Round(($ScopesWithFailover.Count / $DHCPData.Scopes.Count) * 100, 1) } else { 0 }

        # Summary Info Cards
        New-HTMLSection -HeaderText "Failover Coverage Statistics" -Wrap wrap {
            New-HTMLSection -HeaderText "Failover Metrics" -Invisible -Density Compact {
                New-HTMLInfoCard -Title "Failover Relationships" -Number $FailoverRelationships.Count -Subtitle "Configured Partnerships" -Icon "🤝" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                New-HTMLInfoCard -Title "Scopes with Failover" -Number $ScopesWithFailover.Count -Subtitle "Protected Scopes" -Icon "✅" -TitleColor 'Green' -NumberColor 'DarkGreen' -ShadowColor 'rgba(0, 128, 0, 0.15)'

                $NoFailoverColor = if ($ScopesWithoutFailover.Count -eq 0) { 'Green' } else { 'Orange' }
                $NoFailoverIcon  = if ($ScopesWithoutFailover.Count -eq 0) { '✅' } else { '⚠️' }
                New-HTMLInfoCard -Title "Scopes without Failover" -Number $ScopesWithoutFailover.Count -Subtitle "Unprotected Scopes" -Icon $NoFailoverIcon -TitleColor $NoFailoverColor -NumberColor $NoFailoverColor -ShadowColor 'rgba(255, 165, 0, 0.15)'

                $CoverageColor = if ($CoveragePercent -ge 90) { 'Green' } elseif ($CoveragePercent -ge 70) { 'Orange' } else { 'Red' }
                $CoverageIcon  = if ($CoveragePercent -ge 90) { '🎆' } elseif ($CoveragePercent -ge 70) { '📋' } else { '📉' }
                New-HTMLInfoCard -Title "Failover Coverage" -Number "$CoveragePercent%" -Subtitle "Scope Protection Rate" -Icon $CoverageIcon -TitleColor $CoverageColor -NumberColor $CoverageColor -ShadowColor 'rgba(0, 0, 0, 0.15)'
            }
        }

        # Failover relationships table
        New-HTMLSection -Invisible -Wrap wrap {
            if ($FailoverRelationships.Count -gt 0) {
                New-HTMLSection -HeaderText "Failover Relationships" {
                    New-HTMLPanel -Invisible {
                        $FailoverSummary = foreach ($Failover in $FailoverRelationships) {
                            [PSCustomObject]@{
                                Name            = $Failover.Name
                                PrimaryServer   = if ($Failover.PrimaryServerName) { $Failover.PrimaryServerName } else { $Failover.ServerName }
                                SecondaryServer = $Failover.PartnerServer
                                Mode            = $Failover.Mode
                                State           = $Failover.State
                                ScopeCount      = if ($Failover.ScopeId -is [Array]) { $Failover.ScopeId.Count } elseif ($null -eq $Failover.ScopeId) { 0 } else { 1 }
                                Status          = if ($Failover.State -eq 'Normal') { '✅ Healthy' } else { "⚠️ $($Failover.State)" }
                            }
                        }
                        New-HTMLTable -DataTable $FailoverSummary {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Normal' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator ne -Value 'Normal' -BackgroundColor Yellow
                            New-HTMLTableCondition -Name 'ScopeCount' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Red -Color White
                        } -ScrollX -Filtering
                    }
                }
            }

            # Consolidated per-subnet failover issues (single table)
            if ($DHCPData.FailoverAnalysis -and $DHCPData.FailoverAnalysis.PerSubnetIssues -and $DHCPData.FailoverAnalysis.PerSubnetIssues.Count -gt 0) {
                New-HTMLSection -HeaderText "🚦 Per-Subnet Failover Issues" {
                    $perSubnet = $DHCPData.FailoverAnalysis.PerSubnetIssues | ForEach-Object {
                        [PSCustomObject]@{
                            ScopeId         = $_.ScopeId
                            PrimaryServer   = $_.PrimaryServer
                            SecondaryServer = $_.SecondaryServer
                            FailoverName    = if ($_.Relationship) { $_.Relationship } else { '' }
                            Status          = $_.Issue
                        }
                    }
                    New-HTMLTable -DataTable $perSubnet -ScrollX -Filtering {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Present only on primary' -BackgroundColor Orange
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Present only on secondary' -BackgroundColor Orange
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Missing from both partners' -BackgroundColor Salmon -Color White
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'No failover configured' -BackgroundColor Salmon -Color White
                    } -Title 'Subnets requiring attention'
                }
            }

            # Stale failover relationships (no subnets)
            if ($DHCPData.FailoverAnalysis -and $DHCPData.FailoverAnalysis.StaleRelationships -and $DHCPData.FailoverAnalysis.StaleRelationships.Count -gt 0) {
                New-HTMLSection -HeaderText "🧹 Stale Failover Relationships (no subnets)" {
                    New-HTMLTable -DataTable $DHCPData.FailoverAnalysis.StaleRelationships -ScrollX -Filtering {
                        New-HTMLTableCondition -Name 'ScopeCount' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Yellow
                    }
                }
            }

            # NOTE: We no longer render a separate "scopes without failover" list.
            # The consolidated per-subnet table below captures all cases, including
            # subnets missing on both partners and those present on only one side.
        }
    }
}
