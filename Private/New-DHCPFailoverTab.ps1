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

                # Failover enumeration issues (from centralized error log)
                $FailoverEnumWarnings = @($DHCPData.Warnings | Where-Object { $_.Component -eq 'Failover Relationships' -and $_.Operation -eq 'Get-DhcpServerv4Failover' })
                $FailoverEnumErrors   = @($DHCPData.Errors   | Where-Object { $_.Component -eq 'Failover Relationships' -and $_.Operation -eq 'Get-DhcpServerv4Failover' })

                New-HTMLSection -HeaderText "Failover Health Dashboard" -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "Failover Relationships" -Number $TotalFailoverRelationships -Subtitle "Configured" -Icon "🔄" -TitleColor Blue -NumberColor DarkBlue
                    New-HTMLInfoCard -Title "Active Failovers" -Number $ActiveFailovers -Subtitle "Normal State" -Icon "✅" -TitleColor Green -NumberColor DarkGreen
                    New-HTMLInfoCard -Title "Failover Issues" -Number $FailoverIssues -Subtitle "Need Attention" -Icon "⚠️" -TitleColor $(if ($FailoverIssues -gt 0) { "Red" } else { "Green" }) -NumberColor $(if ($FailoverIssues -gt 0) { "DarkRed" } else { "DarkGreen" })
                    New-HTMLInfoCard -Title "Unprotected Scopes" -Number $ScopesWithoutFailover -Subtitle "No Failover" -Icon "🚨" -TitleColor $(if ($ScopesWithoutFailover -gt 0) { "Orange" } else { "Green" }) -NumberColor $(if ($ScopesWithoutFailover -gt 0) { "DarkOrange" } else { "DarkGreen" })
                    if ($DHCPData.FailoverAnalysis) {
                        New-HTMLInfoCard -Title "Missing on Partner B" -Number $($DHCPData.FailoverAnalysis.OnlyOnPrimary.Count) -Subtitle "Scopes assigned on A only" -Icon "🟠" -TitleColor 'DarkOrange' -NumberColor 'DarkOrange'
                        New-HTMLInfoCard -Title "Missing on Partner A" -Number $($DHCPData.FailoverAnalysis.OnlyOnSecondary.Count) -Subtitle "Scopes assigned on B only" -Icon "🟠" -TitleColor 'DarkOrange' -NumberColor 'DarkOrange'
                        New-HTMLInfoCard -Title "Missing on Both" -Number $($DHCPData.FailoverAnalysis.MissingOnBoth.Count) -Subtitle "Gap" -Icon "⚠️" -TitleColor 'OrangeRed' -NumberColor 'OrangeRed'
                        if ($FailoverEnumWarnings.Count -gt 0 -or $FailoverEnumErrors.Count -gt 0) {
                            $warnColor = if ($FailoverEnumWarnings.Count -gt 0) { 'Orange' } else { 'Green' }
                            $errColor  = if ($FailoverEnumErrors.Count   -gt 0) { 'Red'    } else { 'Green' }
                            New-HTMLInfoCard -Title "Enum Warnings" -Number $FailoverEnumWarnings.Count -Subtitle "Get-DhcpServerv4Failover" -Icon "⚠️" -TitleColor $warnColor -NumberColor $warnColor
                            New-HTMLInfoCard -Title "Enum Errors"   -Number $FailoverEnumErrors.Count   -Subtitle "Get-DhcpServerv4Failover" -Icon "❌" -TitleColor $errColor  -NumberColor $errColor
                        }
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

        # Normalized (deduped) view per partner pair for clarity
        New-HTMLSection -HeaderText "🤝 Failover Relationships (normalized per partner pair)" -CanCollapse {
            $rels = $DHCPData.FailoverRelationships
            $pairs = @{}
            foreach ($rel in $rels) {
                # Canonicalize names (prefer FQDN) to avoid short/FQDN mismatches
                $a = Resolve-DHCPServerName -Name $rel.ServerName -DHCPSummary $DHCPData
                $b = Resolve-DHCPServerName -Name $rel.PartnerServer -DHCPSummary $DHCPData
                $sorted = @($a, $b) | Sort-Object
                $key = $sorted -join '↔'
                if (-not $pairs.ContainsKey($key)) {
                    $pairs[$key] = [ordered]@{
                        NameSet     = New-Object System.Collections.Generic.HashSet[string]
                        ServerA     = $sorted[0]
                        ServerB     = $sorted[1]
                        Modes       = New-Object System.Collections.Generic.HashSet[string]
                        States      = New-Object System.Collections.Generic.HashSet[string]
                        ScopesUnion = New-Object System.Collections.Generic.HashSet[string]
                        Sources     = New-Object System.Collections.Generic.HashSet[string]
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
                    PartnerA   = $p.ServerA
                    PartnerB   = $p.ServerB
                    Mode       = (@($p.Modes) -join ', ')
                    State      = $state
                    ScopeCount = @($p.ScopesUnion).Count
                    DataSource = $dataSrc
                }
            }

            New-HTMLTable -DataTable $FailoverSummary -Filtering {
                New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Normal' -BackgroundColor LightGreen -FailBackgroundColor Orange
                New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator ne -Value 'Normal' -BackgroundColor Yellow
                New-HTMLTableCondition -Name 'ScopeCount' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Red -Color White
                New-HTMLTableCondition -Name 'DataSource' -ComparisonType string -Operator like -Value 'Only *' -BackgroundColor LightYellow
            } -DataStore JavaScript -ScrollX -Title "Failover Relationships by Partner Pair"
        }

        # Consolidated per-subnet failover issues (simplified view)
        if ($DHCPData.FailoverAnalysis -and $DHCPData.FailoverAnalysis.PerSubnetIssues -and $DHCPData.FailoverAnalysis.PerSubnetIssues.Count -gt 0) {
            New-HTMLSection -HeaderText "🚦 Per-Subnet Failover Issues" {
                $perSubnet = $DHCPData.FailoverAnalysis.PerSubnetIssues | ForEach-Object {
                    [PSCustomObject]@{
                        ScopeId      = $_.ScopeId
                        PartnerA     = $_.PrimaryServer
                        PartnerB     = $_.SecondaryServer
                        Relationship = if ($_.Relationship) { $_.Relationship } else { '' }
                        Status       = $_.Issue
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
                $verified = ($relA -ne $null -and $relB -ne $null)

                # Only include common scopes on both servers to detect 'Missing on both'
                # Use canonicalized names to avoid short/FQDN mismatches
                $scopesOnA = @(
                    $DHCPData.Scopes |
                        Where-Object {
                            if (-not $_.ServerName) { return $false }
                            $srv = Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPData
                            return ($srv -eq $pair.ServerA)
                        } |
                        Select-Object -ExpandProperty ScopeId -Unique
                )
                $scopesOnB = @(
                    $DHCPData.Scopes |
                        Where-Object {
                            if (-not $_.ServerName) { return $false }
                            $srv = Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPData
                            return ($srv -eq $pair.ServerB)
                        } |
                        Select-Object -ExpandProperty ScopeId -Unique
                )
                $commonScopes = @($scopesOnA | Where-Object { $scopesOnB -contains $_ })
                $allScopes = @($scopesA + $scopesB + $commonScopes) | Select-Object -Unique

                $rows = foreach ($s in $allScopes) {
                    $onA = $scopesA -contains $s
                    $onB = $scopesB -contains $s
                    $statusBase = if ($onA -and $onB) { 'On both partners' } elseif ($onA) { "Missing on $($pair.ServerB)" } elseif ($onB) { "Missing on $($pair.ServerA)" } else { 'Missing on both' }
                    $status = $statusBase + $(if (-not $verified -and $statusBase -ne 'On both partners') { ' (Unverified)' } else { '' })
                    $failoverConfig = switch ($status) {
                        { $_ -like 'Missing on *' } { 'missing on one partner' }
                        'Missing on both' { 'missing on both' }
                        default { 'configured' }
                    }
                    [PSCustomObject]@{
                        Relationship          = $pair.Name
                        PartnerA              = $pair.ServerA
                        PartnerB              = $pair.ServerB
                        ScopeId               = $s
                        OnPartnerA            = $onA
                        OnPartnerB            = $onB
                        Status                = $status
                        FailoverConfiguration = $failoverConfig
                    }
                }

                New-HTMLSection -HeaderText "$($pair.Name) — $($pair.ServerA) ↔ $($pair.ServerB)" {
                    New-HTMLTable -DataTable $rows -Filtering {
                        # Critical
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator like -Value 'Missing on *' -BackgroundColor Salmon
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Missing on both' -BackgroundColor Salmon
                    } -DataStore JavaScript -ScrollX -Title "Scope Assignment Comparison"
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

        # Failover enumeration issues table (if any)
        if (($FailoverEnumWarnings.Count -gt 0) -or ($FailoverEnumErrors.Count -gt 0)) {
            New-HTMLSection -HeaderText "🚨 Failover Enumeration Issues" -CanCollapse {
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
                New-HTMLTable -DataTable $enumDisplay -Filtering -ScrollX {
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
            New-HTMLSection -HeaderText "ℹ️ Servers Without Any Failover Relationships (Standalone)" -CanCollapse {
                $rows = foreach ($srv in $standalone) {
                    $active = @($DHCPData.Scopes | Where-Object { $_.ServerName -and $_.ServerName.ToLower() -eq $srv -and $_.State -eq 'Active' }).Count
                    [PSCustomObject]@{ Server = $srv; ActiveScopes = $active }
                }
                New-HTMLTable -DataTable $rows -Filtering -ScrollX -Title 'Standalone DHCP Servers'
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
