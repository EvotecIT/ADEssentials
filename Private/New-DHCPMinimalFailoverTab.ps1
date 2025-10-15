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
        # Show two decimals to avoid rounding 99.97% up to 100%
        $CoveragePercentRaw = if ($DHCPData.Scopes.Count -gt 0) { (100.0 * $ScopesWithFailover.Count / $DHCPData.Scopes.Count) } else { 0 }
        $CoveragePercent = [Math]::Round($CoveragePercentRaw, 2)

        # Failover enumeration issues (from centralized error log)
        $FailoverEnumWarnings = @($DHCPData.Warnings | Where-Object { $_.Component -eq 'Failover Relationships' -and $_.Operation -eq 'Get-DhcpServerv4Failover' })
        $FailoverEnumErrors   = @($DHCPData.Errors   | Where-Object { $_.Component -eq 'Failover Relationships' -and $_.Operation -eq 'Get-DhcpServerv4Failover' })

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

                # Surface enumeration problems prominently
                if ($FailoverEnumWarnings.Count -gt 0 -or $FailoverEnumErrors.Count -gt 0) {
                    $warnColor = if ($FailoverEnumWarnings.Count -gt 0) { 'Orange' } else { 'Green' }
                    $errColor  = if ($FailoverEnumErrors.Count   -gt 0) { 'Red'    } else { 'Green' }
                    New-HTMLInfoCard -Title "Failover Enum Warnings" -Number $FailoverEnumWarnings.Count -Subtitle "Query issues" -Icon "⚠️" -TitleColor $warnColor -NumberColor $warnColor -ShadowColor 'rgba(255, 165, 0, 0.15)'
                    New-HTMLInfoCard -Title "Failover Enum Errors"   -Number $FailoverEnumErrors.Count   -Subtitle "Query failures" -Icon "❌" -TitleColor $errColor  -NumberColor $errColor  -ShadowColor 'rgba(255, 0, 0, 0.15)'
                }
            }
        }

        # Failover relationships table
        New-HTMLSection -Invisible -Wrap wrap {
            if ($FailoverRelationships.Count -gt 0) {
                New-HTMLSection -HeaderText "Failover Relationships (normalized per partner pair)" {
                    New-HTMLPanel -Invisible {
                        # Aggregate by partner pair, union scope sets from both sides
                        $pairs = @{}
                        foreach ($rel in $FailoverRelationships) {
                            # Canonicalize names (prefer FQDN) to avoid short/FQDN mismatches
                            $a = Resolve-DHCPServerName -Name $rel.ServerName -DHCPSummary $DHCPData
                            $b = Resolve-DHCPServerName -Name $rel.PartnerServer -DHCPSummary $DHCPData
                            $sorted = @($a,$b) | Sort-Object
                            $key = $sorted -join '↔'
                            if (-not $pairs.ContainsKey($key)) {
                                $pairs[$key] = [ordered]@{
                                    NameSet      = New-Object System.Collections.Generic.HashSet[string]
                                    ServerA      = $sorted[0]
                                    ServerB      = $sorted[1]
                                    Modes        = New-Object System.Collections.Generic.HashSet[string]
                                    States       = New-Object System.Collections.Generic.HashSet[string]
                                    ScopesUnion  = New-Object System.Collections.Generic.HashSet[string]
                                    Sources      = New-Object System.Collections.Generic.HashSet[string]
                                }
                            }
                            if ($rel.Name) { [void]$pairs[$key].NameSet.Add([string]$rel.Name) }
                            if ($rel.Mode) { [void]$pairs[$key].Modes.Add([string]$rel.Mode) }
                            if ($rel.State) { [void]$pairs[$key].States.Add([string]$rel.State) }
                            foreach ($sid in @($rel.ScopeId)) { if ($sid) { [void]$pairs[$key].ScopesUnion.Add(([string]$sid).Trim()) } }
                            if ($rel.GatheredFrom) { [void]$pairs[$key].Sources.Add((([string]$rel.GatheredFrom).Trim().ToLower())) }
                        }

                        $FailoverSummary = foreach ($p in $pairs.Values) {
                            $state = if ($p.States.Count -eq 1) { @($p.States)[0] } elseif ($p.States.Count -eq 0) { '' } else { 'Mixed' }
                            $complete = ($p.Sources.Contains($p.ServerA) -and $p.Sources.Contains($p.ServerB))
                            $dataSrc  = if ($complete) { 'Both partners' } elseif ($p.Sources.Contains($p.ServerA)) { "Only $($p.ServerA)" } elseif ($p.Sources.Contains($p.ServerB)) { "Only $($p.ServerB)" } else { 'Unknown' }
                            [PSCustomObject]@{
                                Name       = (@($p.NameSet) -join ', ')
                                PartnerA   = $p.ServerA  # alphabetical label
                                PartnerB   = $p.ServerB
                                Mode       = (@($p.Modes) -join ', ')
                                State      = $state
                                ScopeCount = @($p.ScopesUnion).Count
                                DataSource = $dataSrc
                                Status     = if ($state -eq 'Normal') { '✅ Healthy' } elseif ([string]::IsNullOrWhiteSpace($state)) { '⚠️ Unknown' } else { "⚠️ $state" }
                            }
                        }

                        New-HTMLTable -DataTable $FailoverSummary {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Normal' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator ne -Value 'Normal' -BackgroundColor Yellow
                            New-HTMLTableCondition -Name 'ScopeCount' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Red -Color White
                            New-HTMLTableCondition -Name 'DataSource' -ComparisonType string -Operator like -Value 'Only *' -BackgroundColor LightYellow
                        } -ScrollX -Filtering
                    }
                }
            }

            # Consolidated per-subnet failover issues (single table)
            if ($DHCPData.FailoverAnalysis -and $DHCPData.FailoverAnalysis.PerSubnetIssues -and $DHCPData.FailoverAnalysis.PerSubnetIssues.Count -gt 0) {
                New-HTMLSection -HeaderText "🚦 Per-Subnet Failover Issues" {
                    $perSubnet = $DHCPData.FailoverAnalysis.PerSubnetIssues | ForEach-Object {
                        [PSCustomObject]@{
                            ScopeId   = $_.ScopeId
                            PartnerA  = $_.PrimaryServer
                            PartnerB  = $_.SecondaryServer
                            Relation  = if ($_.Relationship) { $_.Relationship } else { '' }
                            Status    = $_.Issue  # e.g., "Missing on <server>" or "Missing from both partners"
                        }
                    }
                    New-HTMLTable -DataTable $perSubnet -ScrollX -Filtering {
                        # Status now includes server names (e.g., "Missing on dhcp01")
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator like -Value 'Missing on *' -BackgroundColor Orange
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

            # Enumeration problems table
            if ($FailoverEnumWarnings.Count -gt 0 -or $FailoverEnumErrors.Count -gt 0) {
                New-HTMLSection -HeaderText "🚨 Failover Enumeration Issues" {
                    $enumIssues = @($FailoverEnumWarnings + $FailoverEnumErrors) | Sort-Object -Property Timestamp
                    $enumDisplay = $enumIssues | ForEach-Object {
                        [PSCustomObject]@{
                            Time       = $_.Timestamp
                            Server     = $_.ServerName
                            Severity   = $_.Severity
                            Component  = $_.Component
                            Operation  = $_.Operation
                            Category   = $_.Category
                            Reason     = $_.Reason
                            ErrorId    = $_.ErrorId
                            Target     = $_.Target
                            HResult    = $_.HResult
                            Message    = $_.ErrorMessage
                        }
                    }
                    New-HTMLTable -DataTable $enumDisplay -ScrollX -Filtering {
                        New-HTMLTableCondition -Name 'Severity' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Yellow
                        New-HTMLTableCondition -Name 'Severity' -ComparisonType string -Operator eq -Value 'Error'   -BackgroundColor Red -Color White
                    } -Title 'Enumeration errors/warnings when calling Get-DhcpServerv4Failover'
                }
            }

            # Standalone DHCP servers (no failover relationships and no enumeration error recorded)
            $allServers = @($DHCPData.Servers | ForEach-Object { ([string]$_.ServerName).Trim().ToLower() })
            $mentioned  = @()
            foreach ($rel in $DHCPData.FailoverRelationships) {
                if ($rel.ServerName)   { $mentioned += ([string]$rel.ServerName).Trim().ToLower() }
                if ($rel.PartnerServer){ $mentioned += ([string]$rel.PartnerServer).Trim().ToLower() }
            }
            $mentioned = $mentioned | Select-Object -Unique
            $enumFailed = @(@($FailoverEnumWarnings + $FailoverEnumErrors) | ForEach-Object { ([string]$_.ServerName).Trim().ToLower() }) | Select-Object -Unique
            $standalone = @($allServers | Where-Object { ($_ -notin $mentioned) -and ($_ -notin $enumFailed) })
            if ($standalone.Count -gt 0) {
                New-HTMLSection -HeaderText "ℹ️ Servers Without Any Failover Relationships (Standalone)" {
                    $rows = foreach ($srv in $standalone) {
                        $active = @($DHCPData.Scopes | Where-Object { $_.ServerName -and $_.ServerName.ToLower() -eq $srv -and $_.State -eq 'Active' }).Count
                        [PSCustomObject]@{ Server = $srv; ActiveScopes = $active }
                    }
                    New-HTMLTable -DataTable $rows -ScrollX -Filtering -Title 'Standalone DHCP Servers'
                }
            }

            # NOTE: We no longer render a separate "scopes without failover" list.
            # The consolidated per-subnet table below captures all cases, including
            # subnets missing on both partners and those present on only one side.
        }
    }
}
