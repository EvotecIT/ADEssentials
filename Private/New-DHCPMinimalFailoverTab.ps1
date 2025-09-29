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
        $CoveragePercent = if ($DHCPData.Scopes.Count -gt 0) {
            [Math]::Round(($ScopesWithFailover.Count / $DHCPData.Scopes.Count) * 100, 1)
        } else { 0 }

        # Summary Info Cards
        New-HTMLSection -HeaderText "Failover Coverage Statistics" -Wrap wrap {
            New-HTMLSection -HeaderText "Failover Metrics" -Invisible -Density Compact {
                New-HTMLInfoCard -Title "Failover Relationships" -Number $FailoverRelationships.Count -Subtitle "Configured Partnerships" -Icon "🤝" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                New-HTMLInfoCard -Title "Scopes with Failover" -Number $ScopesWithFailover.Count -Subtitle "Protected Scopes" -Icon "✅" -TitleColor 'Green' -NumberColor 'DarkGreen' -ShadowColor 'rgba(0, 128, 0, 0.15)'

                $NoFailoverColor = if ($ScopesWithoutFailover.Count -eq 0) { 'Green' } else { 'Orange' }
                $NoFailoverIcon = if ($ScopesWithoutFailover.Count -eq 0) { '✅' } else { '⚠️' }
                New-HTMLInfoCard -Title "Scopes without Failover" -Number $ScopesWithoutFailover.Count -Subtitle "Unprotected Scopes" -Icon $NoFailoverIcon -TitleColor $NoFailoverColor -NumberColor $NoFailoverColor -ShadowColor 'rgba(255, 165, 0, 0.15)'

                $CoverageColor = if ($CoveragePercent -ge 90) { 'Green' } elseif ($CoveragePercent -ge 70) { 'Orange' } else { 'Red' }
                $CoverageIcon = if ($CoveragePercent -ge 90) { '🎆' } elseif ($CoveragePercent -ge 70) { '📋' } else { '📉' }
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
                                Name = $Failover.Name
                                PrimaryServer = if ($Failover.PrimaryServerName) { $Failover.PrimaryServerName } else { $Failover.ServerName }
                                SecondaryServer = $Failover.PartnerServer
                                Mode = $Failover.Mode
                                State = $Failover.State
                                ScopeCount = if ($Failover.ScopeId -is [Array]) { $Failover.ScopeId.Count } else { 1 }
                                Status = if ($Failover.State -eq 'Normal') { '✅ Healthy' } else { "⚠️ $($Failover.State)" }
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

            # Scopes without failover
            if ($ScopesWithoutFailover.Count -gt 0) {
                New-HTMLSection -HeaderText "⚠️ Scopes Without Failover Protection" {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "The following active scopes do not have failover configured:" -FontSize 14px -FontWeight bold -Color Red

                        $NoFailoverSummary = foreach ($Scope in $ScopesWithoutFailover) {
                            [PSCustomObject]@{
                                ServerName = $Scope.ServerName
                                ScopeId = $Scope.ScopeId
                                Name = $Scope.Name
                                State = $Scope.State
                                LeaseDuration = if ($Scope.LeaseDurationHours) { "$($Scope.LeaseDurationHours) hours" } else { 'N/A' }
                                HasFailover = 'No'
                                FailoverConfiguration = 'missing on both'
                                Issues = if ($Scope.HasIssues) { 'Yes' } else { 'No' }
                            }
                        }

                        New-HTMLTable -DataTable $NoFailoverSummary {
                            New-HTMLTableCondition -Name 'HasFailover' -ComparisonType string -Operator eq -Value 'No' -BackgroundColor Red -Color White
                            New-HTMLTableCondition -Name 'Issues' -ComparisonType string -Operator eq -Value 'Yes' -BackgroundColor Orange
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen
                        } -ScrollX -Filtering

                        New-HTMLText -Text "Recommendation:" -FontSize 12px -FontWeight bold -Color Blue
                        New-HTMLText -Text "Configure DHCP failover for these scopes to ensure service continuity in case of server failure." -FontSize 11px -Color Blue
                    }
                }
            } else {
                New-HTMLSection -HeaderText "✅ Failover Protection Status" {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "All Active Scopes Have Failover Protection" -FontSize 18px -FontWeight bold -Color Green -TextAlign center
                        New-HTMLText -Text "Excellent! All active DHCP scopes are protected with failover configuration." -FontSize 14px -TextAlign center
                    }
                }
            }

            # Failover analysis (uses precomputed results if available)
            $hasAnalysis = ($DHCPData.FailoverAnalysis -and (
                $DHCPData.FailoverAnalysis.OnlyOnPrimary.Count -gt 0 -or
                $DHCPData.FailoverAnalysis.OnlyOnSecondary.Count -gt 0 -or
                $DHCPData.FailoverAnalysis.MissingOnBoth.Count -gt 0))

            if ($hasAnalysis) {
                if ($DHCPData.FailoverAnalysis.OnlyOnPrimary.Count -gt 0) {
                    New-HTMLSection -HeaderText '🔶 Mismatches: Present only on Primary' {
                        $data = $DHCPData.FailoverAnalysis.OnlyOnPrimary | ForEach-Object {
                            [PSCustomObject]@{
                                Relationship        = $_.Relationship
                                PrimaryServer       = $_.PrimaryServer
                                SecondaryServer     = $_.SecondaryServer
                                ScopeId             = $_.ScopeId
                                FailoverConfiguration = 'missing on secondary'
                                Issue               = $_.Issue
                            }
                        }
                        New-HTMLTable -DataTable $data -ScrollX -Filtering {
                            New-HTMLTableCondition -Name 'FailoverConfiguration' -ComparisonType string -Operator eq -Value 'missing on secondary' -BackgroundColor Salmon -Color White
                        }
                    }
                }
                if ($DHCPData.FailoverAnalysis.OnlyOnSecondary.Count -gt 0) {
                    New-HTMLSection -HeaderText '🔶 Mismatches: Present only on Secondary' {
                        $data = $DHCPData.FailoverAnalysis.OnlyOnSecondary | ForEach-Object {
                            [PSCustomObject]@{
                                Relationship        = $_.Relationship
                                PrimaryServer       = $_.PrimaryServer
                                SecondaryServer     = $_.SecondaryServer
                                ScopeId             = $_.ScopeId
                                FailoverConfiguration = 'missing on primary'
                                Issue               = $_.Issue
                            }
                        }
                        New-HTMLTable -DataTable $data -ScrollX -Filtering {
                            New-HTMLTableCondition -Name 'FailoverConfiguration' -ComparisonType string -Operator eq -Value 'missing on primary' -BackgroundColor Orange
                        }
                    }
                }
                if ($DHCPData.FailoverAnalysis.MissingOnBoth.Count -gt 0) {
                    New-HTMLSection -HeaderText '⚠️ Scopes Missing on Both Partners' {
                        $data = $DHCPData.FailoverAnalysis.MissingOnBoth | ForEach-Object {
                            [PSCustomObject]@{
                                Relationship        = $_.Relationship
                                PrimaryServer       = $_.PrimaryServer
                                SecondaryServer     = $_.SecondaryServer
                                ScopeId             = $_.ScopeId
                                FailoverConfiguration = 'missing on both'
                                Issue               = $_.Issue
                            }
                        }
                        New-HTMLTable -DataTable $data -ScrollX -Filtering {
                            New-HTMLTableCondition -Name 'FailoverConfiguration' -ComparisonType string -Operator eq -Value 'missing on both' -BackgroundColor Salmon -Color White
                        }
                    }
                }
            }
        }
    }
}
