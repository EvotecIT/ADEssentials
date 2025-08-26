function New-DHCPMinimalFailoverTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPData
    )

    New-HTMLTab -TabName 'Failover Status' {
        # Get failover data
        $FailoverRelationships = $DHCPData.Failover | Where-Object { $_ }
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
        New-HTMLSection -Invisible {
            if ($FailoverRelationships.Count -gt 0) {
                New-HTMLSection -HeaderText "Failover Relationships" {
                    New-HTMLPanel -Invisible {
                        $FailoverSummary = foreach ($Failover in $FailoverRelationships) {
                            [PSCustomObject]@{
                                Name = $Failover.Name
                                PrimaryServer = $Failover.PrimaryServerName
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

            # Failover scope mismatch detection
            $FailoverMismatches = @()
            foreach ($Failover in $FailoverRelationships) {
                if ($Failover.PartnerServer) {
                    # Check if partner has same failover configuration
                    $PartnerFailover = $FailoverRelationships | Where-Object {
                        $_.PrimaryServerName -eq $Failover.PartnerServer -and
                        $_.Name -eq $Failover.Name
                    }

                    if ($PartnerFailover) {
                        # Compare scope lists
                        $PrimaryScopes = if ($Failover.ScopeId -is [Array]) { $Failover.ScopeId } else { @($Failover.ScopeId) }
                        $PartnerScopes = if ($PartnerFailover.ScopeId -is [Array]) { $PartnerFailover.ScopeId } else { @($PartnerFailover.ScopeId) }

                        $Differences = Compare-Object $PrimaryScopes $PartnerScopes
                        if ($Differences) {
                            foreach ($Diff in $Differences) {
                                $FailoverMismatches += [PSCustomObject]@{
                                    FailoverName = $Failover.Name
                                    Scope = $Diff.InputObject
                                    Issue = if ($Diff.SideIndicator -eq '<=') { "Missing on $($Failover.PartnerServer)" } else { "Missing on $($Failover.PrimaryServerName)" }
                                }
                            }
                        }
                    }
                }
            }

            if ($FailoverMismatches.Count -gt 0) {
                New-HTMLSection -HeaderText '🔴 Critical: Failover Configuration Mismatches' {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text 'Failover scope mismatches detected between partners' -FontSize 14px -FontWeight bold -Color Red
                        New-HTMLTable -DataTable $FailoverMismatches {
                            New-HTMLTableCondition -Name 'Issue' -ComparisonType string -Operator contains -Value 'Missing' -BackgroundColor Red -Color White
                        } -ScrollX
                        New-HTMLText -Text 'Action Required:' -FontSize 12px -FontWeight bold -Color Red
                        New-HTMLText -Text 'Synchronize failover configurations between partner servers immediately.' -FontSize 11px -Color Red
                    }
                }
            }
        }
    }
}