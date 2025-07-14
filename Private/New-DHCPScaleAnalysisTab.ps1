function New-DHCPScaleAnalysisTab {
    <#
    .SYNOPSIS
    Creates the Scale Analysis tab for DHCP environments requiring advanced monitoring.

    .DESCRIPTION
    This tab provides critical monitoring for DHCP deployments of all sizes, with
    specialized sections for enterprise-scale environments and detection of stale AD entries.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    # Smart logic to determine if this tab should show advanced scale analysis
    $TotalLeases = $DHCPData.Statistics.AddressesInUse
    $TotalServers = $DHCPData.Statistics.TotalServers
    $OnlineServers = $DHCPData.Statistics.ServersOnline

        # Show this tab if ANY of these conditions are met:
    # - 10+ servers (medium to large environment)
    # - 100K+ leases (high lease volume)
    # - Significant number of offline servers (indicates stale entries)
    # - OR if there's any interesting data to show (for test mode and small environments)
    $OfflineServers = $TotalServers - $OnlineServers
    $ShowAdvancedAnalysis = ($TotalServers -ge 10) -or ($TotalLeases -ge 100000) -or ($OfflineServers -gt 5) -or ($TotalServers -ge 2 -and $TotalLeases -gt 0)

    if (-not $ShowAdvancedAnalysis) {
        return  # Skip this tab for very small environments
    }

    New-HTMLTab -TabName 'Scale Analysis' {
        New-HTMLSection -HeaderText "📊 DHCP Environment Scale Analysis" {
            New-HTMLPanel -Invisible {
                # Determine environment classification
                $EnvironmentSize = if ($TotalLeases -gt 1000000 -or $OnlineServers -gt 50) { "Enterprise (Large)" }
                                  elseif ($TotalLeases -gt 100000 -or $OnlineServers -gt 10) { "Corporate (Medium)" }
                                  else { "Business (Small-Medium)" }

                $ScaleColor = switch ($EnvironmentSize) {
                    "Enterprise (Large)" { "DarkRed" }
                    "Corporate (Medium)" { "DarkOrange" }
                    default { "DarkBlue" }
                }

                New-HTMLText -Text "DHCP Environment Scale Analysis" -FontSize 18pt -FontWeight bold -Color $ScaleColor
                New-HTMLText -Text "Environment Classification: $EnvironmentSize | Specialized analysis for your DHCP infrastructure scale and complexity." -FontSize 12pt -Color DarkGray

                # Scale metrics summary with intelligent thresholds
                $LeasesPerServer = if ($OnlineServers -gt 0) { [Math]::Round($TotalLeases / $OnlineServers, 0) } else { 0 }
                $AverageUtilization = $DHCPData.Statistics.OverallPercentageInUse
                $HighUtilizationScopes = @($DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 80 }).Count
                $CriticalScopes = @($DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 90 }).Count

                New-HTMLSection -HeaderText "Environment Overview" -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "Environment Type" -Number $EnvironmentSize -Subtitle "Classification" -Icon "🏢" -TitleColor $ScaleColor -NumberColor $(if ($EnvironmentSize -eq "Enterprise (Large)") { "DarkRed" } else { "Navy" })
                    New-HTMLInfoCard -Title "Active Leases" -Number $TotalLeases.ToString("N0") -Subtitle "Total Environment" -Icon "📊" -TitleColor DodgerBlue -NumberColor Navy
                    New-HTMLInfoCard -Title "Online Servers" -Number $OnlineServers -Subtitle "Operational" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen

                    if ($OfflineServers -gt 0) {
                        New-HTMLInfoCard -Title "Stale Entries" -Number $OfflineServers -Subtitle "Offline/Dead Servers" -Icon "⚠️" -TitleColor Crimson -NumberColor DarkRed -ShadowColor 'rgba(220, 20, 60, 0.3)' -ShadowIntensity Bold
                    } else {
                        New-HTMLInfoCard -Title "Server Health" -Number "Clean" -Subtitle "No Stale Entries" -Icon "✨" -TitleColor LimeGreen -NumberColor DarkGreen
                    }
                }
            }
        }

        # Stale AD Entries Detection (Critical for environments with dead servers)
        if ($OfflineServers -gt 0) {
            New-HTMLSection -HeaderText "🚨 Stale DHCP Server Registrations in Active Directory" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Dead Server Detection" -FontSize 16pt -FontWeight bold -Color DarkRed
                    New-HTMLText -Text "Found $OfflineServers servers registered in Active Directory that are not responding. These stale entries can cause confusion and should be cleaned up." -FontSize 12pt -Color DarkRed

                    # Get offline servers for detailed analysis
                    $OfflineServersList = $DHCPData.Servers | Where-Object { $_.Status -ne 'Online' }
                    if ($OfflineServersList.Count -gt 0) {
                        New-HTMLSection -HeaderText "Dead/Stale DHCP Servers" -CanCollapse {
                            New-HTMLTable -DataTable $OfflineServersList -Filtering {
                                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator ne -Value 'Online' -BackgroundColor Red -Color White
                                New-HTMLTableCondition -Name 'PingSuccessful' -ComparisonType bool -Operator eq -Value $false -BackgroundColor Salmon -HighlightHeaders 'PingSuccessful'
                                New-HTMLTableCondition -Name 'DNSResolvable' -ComparisonType bool -Operator eq -Value $false -BackgroundColor Orange -HighlightHeaders 'DNSResolvable'
                            } -DataStore JavaScript -ScrollX -Title "Servers Requiring Cleanup"
                        }
                    }

                    New-HTMLSection -HeaderText "🔧 Cleanup Recommendations" -CanCollapse {
                        New-HTMLPanel {
                            New-HTMLText -Text "Actions to Clean Up Stale Entries:" -FontSize 14px -FontWeight bold -Color DarkRed
                            New-HTMLList {
                                New-HTMLListItem -Text "🔍 Verify servers are truly dead (not just temporarily offline)"
                                New-HTMLListItem -Text "📋 Document decommissioned servers for change management"
                                New-HTMLListItem -Text "🗑️ Remove stale DHCP server authorizations from Active Directory"
                                New-HTMLListItem -Text "🧹 Clean up DNS entries for decommissioned servers"
                                New-HTMLListItem -Text "📊 Update monitoring systems to remove dead servers"
                                New-HTMLListItem -Text "🔄 Redistribute scopes from dead servers to active ones"
                            } -FontSize 12px

                            $CleanupScript = @"
# PowerShell script to remove stale DHCP server authorizations
# WARNING: Test in non-production first!

# Get current DHCP servers in AD
`$AuthorizedServers = Get-DhcpServerInDC

# Servers to remove (replace with your dead servers)
`$ServersToRemove = @(
    'dead-dhcp-server1.domain.com',
    'dead-dhcp-server2.domain.com'
)

foreach (`$Server in `$ServersToRemove) {
    try {
        # Test if server is really dead
        if (-not (Test-Connection -ComputerName `$Server -Count 2 -Quiet)) {
            Write-Host "Removing stale DHCP server: `$Server" -ForegroundColor Yellow
            Remove-DhcpServerInDC -DnsName `$Server -WhatIf  # Remove -WhatIf when ready
        } else {
            Write-Warning "Server `$Server is responding - skipping removal"
        }
    } catch {
        Write-Error "Failed to process `$Server : `$(`$_.Exception.Message)"
    }
}
"@
                            New-HTMLCodeBlock -Code $CleanupScript -Style powershell
                        }
                    }
                }
            }
        }

        # Adaptive Recommendations based on environment size
        New-HTMLSection -HeaderText "🎯 Scale-Appropriate Recommendations" -CanCollapse {
            New-HTMLPanel {
                if ($EnvironmentSize -eq "Enterprise (Large)") {
                    New-HTMLText -Text "Enterprise-Scale Recommendations (1M+ Leases):" -FontSize 14px -FontWeight bold -Color DarkRed
                    New-HTMLList {
                        New-HTMLListItem -Text "🔥 CRITICAL: Max 250K leases per server - redistribute load immediately if exceeded"
                        New-HTMLListItem -Text "⚡ Implement sub-100ms DHCP response time monitoring"
                        New-HTMLListItem -Text "💾 Run jetpack.exe monthly to compact database (reduces size by 30-50%)"
                        New-HTMLListItem -Text "📊 Deploy real-time monitoring with SCOM/Splunk integration"
                        New-HTMLListItem -Text "🔄 Mandatory failover for ALL scopes - use Load Balance mode"
                        New-HTMLListItem -Text "🗂️ Database backup every 15-30 minutes with offsite storage"
                        New-HTMLListItem -Text "🏗️ Dedicated DHCP servers on enterprise hardware with SSD storage"
                        New-HTMLListItem -Text "🔍 Avoid mega-scopes >65K addresses - split into multiple scopes"
                    } -FontSize 12px
                } elseif ($EnvironmentSize -eq "Corporate (Medium)") {
                    New-HTMLText -Text "Corporate-Scale Recommendations (100K-1M Leases):" -FontSize 14px -FontWeight bold -Color DarkOrange
                    New-HTMLList {
                        New-HTMLListItem -Text "⚡ Target max 500K leases per server for optimal performance"
                        New-HTMLListItem -Text "🔄 Implement failover for critical scopes (business hours)"
                        New-HTMLListItem -Text "💾 Run jetpack.exe quarterly to maintain database performance"
                        New-HTMLListItem -Text "📊 Set up automated monitoring with PowerShell scripts"
                        New-HTMLListItem -Text "🗂️ Database backup every 60 minutes during business hours"
                        New-HTMLListItem -Text "🔍 Monitor scope utilization - alert at 85%"
                        New-HTMLListItem -Text "🏗️ Consider SSD storage for DHCP database files"
                        New-HTMLListItem -Text "📈 Plan capacity 6 months ahead based on growth trends"
                    } -FontSize 12px
                } else {
                    New-HTMLText -Text "Business-Scale Recommendations (<100K Leases):" -FontSize 14px -FontWeight bold -Color DarkBlue
                    New-HTMLList {
                        New-HTMLListItem -Text "📊 Monitor scope utilization monthly - alert at 80%"
                        New-HTMLListItem -Text "🔄 Consider failover for mission-critical sites"
                        New-HTMLListItem -Text "💾 Run jetpack.exe annually or when database >500MB"
                        New-HTMLListItem -Text "🗂️ Daily database backup is sufficient"
                        New-HTMLListItem -Text "🔍 Regular health checks via PowerShell scripts"
                        New-HTMLListItem -Text "📈 Plan capacity 3-6 months ahead"
                        New-HTMLListItem -Text "🏗️ Standard server hardware is acceptable"
                        New-HTMLListItem -Text "⚡ Focus on scope design and proper DNS configuration"
                    } -FontSize 12px
                }
            } -Invisible
        }

        # Server Load Distribution Analysis (only for medium/large environments)
        if ($OnlineServers -ge 5) {
            New-HTMLSection -HeaderText "⚖️ Server Load Distribution Analysis" {
                # Create load distribution data
                $LoadAnalysis = foreach ($Server in ($DHCPData.Servers | Where-Object { $_.Status -eq 'Online' })) {
                    $ServerScopes = $DHCPData.Scopes | Where-Object { $_.ServerName -eq $Server.ServerName }
                    $ServerLeases = ($ServerScopes | Measure-Object -Property AddressesInUse -Sum).Sum
                    $ServerCapacity = ($ServerScopes | Measure-Object -Property TotalAddresses -Sum).Sum
                    $ServerUtilization = if ($ServerCapacity -gt 0) { [Math]::Round(($ServerLeases / $ServerCapacity) * 100, 2) } else { 0 }

                    # Adaptive load rating based on environment size
                    $LoadRating = if ($EnvironmentSize -eq "Enterprise (Large)") {
                        switch ($ServerLeases) {
                            {$_ -gt 250000} { "Overloaded" }
                            {$_ -gt 150000} { "High Load" }
                            {$_ -gt 75000} { "Medium Load" }
                            {$_ -gt 25000} { "Light Load" }
                            default { "Very Light" }
                        }
                    } elseif ($EnvironmentSize -eq "Corporate (Medium)") {
                        switch ($ServerLeases) {
                            {$_ -gt 500000} { "Overloaded" }
                            {$_ -gt 250000} { "High Load" }
                            {$_ -gt 100000} { "Medium Load" }
                            {$_ -gt 50000} { "Light Load" }
                            default { "Very Light" }
                        }
                    } else {
                        switch ($ServerLeases) {
                            {$_ -gt 100000} { "Overloaded" }
                            {$_ -gt 50000} { "High Load" }
                            {$_ -gt 25000} { "Medium Load" }
                            {$_ -gt 10000} { "Light Load" }
                            default { "Very Light" }
                        }
                    }

                    $RecommendedAction = if ($LoadRating -eq "Overloaded") { "URGENT: Redistribute load" }
                                        elseif ($LoadRating -eq "High Load") { "Consider load balancing" }
                                        elseif ($ServerUtilization -gt 85) { "Monitor closely" }
                                        else { "Optimal" }

                    [PSCustomObject]@{
                        ServerName = $Server.ServerName
                        Status = $Server.Status
                        ActiveLeases = $ServerLeases
                        TotalCapacity = $ServerCapacity
                        UtilizationPercent = $ServerUtilization
                        LoadRating = $LoadRating
                        ScopeCount = $ServerScopes.Count
                        FailoverConfigured = ($ServerScopes | Where-Object { $_.FailoverPartner -ne '' }).Count
                        RecommendedAction = $RecommendedAction
                    }
                }

                New-HTMLTable -DataTable $LoadAnalysis -Filtering {
                    New-HTMLTableCondition -Name 'LoadRating' -ComparisonType string -Operator eq -Value 'Overloaded' -BackgroundColor Red -Color White
                    New-HTMLTableCondition -Name 'LoadRating' -ComparisonType string -Operator eq -Value 'High Load' -BackgroundColor Orange -Color White
                    New-HTMLTableCondition -Name 'UtilizationPercent' -ComparisonType number -Operator gt -Value 85 -BackgroundColor Orange -HighlightHeaders 'UtilizationPercent'
                    New-HTMLTableCondition -Name 'RecommendedAction' -ComparisonType string -Operator like -Value '*URGENT*' -BackgroundColor Red -Color White
                } -DataStore JavaScript -ScrollX -Title "Server Load Distribution Analysis"
            }
        }

        # Capacity Forecasting (adaptive to environment size)
        New-HTMLSection -HeaderText "📈 Capacity Forecasting & Growth Planning" -CanCollapse {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Growth Trend Analysis" -FontSize 16pt -FontWeight bold -Color DarkBlue
                New-HTMLText -Text "Based on current utilization patterns and environment size, plan capacity expansion appropriately." -FontSize 12pt -Color DarkGray

                # Calculate forecasting metrics with adaptive growth rates
                $CurrentCapacity = $DHCPData.Statistics.TotalAddresses
                $CurrentUsage = $DHCPData.Statistics.AddressesInUse
                $UtilizationRate = $DHCPData.Statistics.OverallPercentageInUse
                $AvailableAddresses = $CurrentCapacity - $CurrentUsage

                # Adaptive growth rate based on environment size
                $MonthlyGrowthRate = if ($EnvironmentSize -eq "Enterprise (Large)") { 0.03 }  # 3% monthly for enterprise
                                    elseif ($EnvironmentSize -eq "Corporate (Medium)") { 0.05 }  # 5% monthly for corporate
                                    else { 0.07 }  # 7% monthly for smaller businesses (higher growth rate)

                $TargetUtilization = 85  # More conservative for all environments
                $AddressesNeededForTarget = ($CurrentCapacity * $TargetUtilization / 100) - $CurrentUsage
                $MonthsToTarget = if ($MonthlyGrowthRate -gt 0 -and $AddressesNeededForTarget -gt 0) {
                    [Math]::Max(0, [Math]::Round($AddressesNeededForTarget / ($CurrentUsage * $MonthlyGrowthRate), 1))
                } else { "N/A" }

                $GrowthRateText = "$([Math]::Round($MonthlyGrowthRate * 100, 1))%/month"

                New-HTMLSection -HeaderText "Capacity Planning Metrics" -Invisible -Density Compact {
                    New-HTMLInfoCard -Title "Available Capacity" -Number $AvailableAddresses.ToString("N0") -Subtitle "Addresses Remaining" -Icon "🆓" -TitleColor LimeGreen -NumberColor DarkGreen
                    New-HTMLInfoCard -Title "Estimated Growth" -Number $GrowthRateText -Subtitle "Based on Size" -Icon "📈" -TitleColor Orange -NumberColor DarkOrange
                    New-HTMLInfoCard -Title "Time to 85%" -Number "$MonthsToTarget months" -Subtitle "Capacity Planning" -Icon "⏰" -TitleColor Purple -NumberColor DarkMagenta
                    New-HTMLInfoCard -Title "Planning Window" -Number $(if ($EnvironmentSize -eq "Enterprise (Large)") { "12 months" } elseif ($EnvironmentSize -eq "Corporate (Medium)") { "6 months" } else { "3-6 months" }) -Subtitle "Recommended" -Icon "🏗️" -TitleColor DodgerBlue -NumberColor Navy
                }
            }
        }

        # Performance Monitoring (adaptive alerts based on environment size)
        if ($EnvironmentSize -eq "Enterprise (Large)" -and $TotalLeases -gt 1000000) {
            New-HTMLSection -HeaderText "🚨 Critical Monitoring Alerts for Large Environment" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "ENTERPRISE MONITORING REQUIRED" -FontSize 16px -FontWeight bold -Color Red
                    New-HTMLText -Text "Your environment has 1M+ leases. Implement these monitoring alerts immediately:" -FontSize 12pt -Color DarkRed

                    New-HTMLList {
                        New-HTMLListItem -Text "🔥 DHCP response time >100ms = CRITICAL ALERT"
                        New-HTMLListItem -Text "⚡ Scope utilization >85% = WARNING ALERT"
                        New-HTMLListItem -Text "🚨 Scope utilization >90% = CRITICAL ALERT"
                        New-HTMLListItem -Text "💾 Database size >2GB = WARNING (run jetpack)"
                        New-HTMLListItem -Text "🖥️ DHCP service memory >4GB = WARNING"
                        New-HTMLListItem -Text "📊 Failed DHCP requests >1% = CRITICAL"
                        New-HTMLListItem -Text "🔄 Failover partner offline >5min = CRITICAL"
                        New-HTMLListItem -Text "💿 Backup failure = CRITICAL ALERT"
                    } -FontSize 12px -Color Red
                }
            }
        } elseif ($EnvironmentSize -eq "Corporate (Medium)") {
            New-HTMLSection -HeaderText "📊 Recommended Monitoring for Corporate Environment" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Corporate Monitoring Guidelines" -FontSize 14px -FontWeight bold -Color DarkOrange
                    New-HTMLList {
                        New-HTMLListItem -Text "⚡ Monitor scope utilization daily - alert at 80%"
                        New-HTMLListItem -Text "🔄 Check failover status weekly"
                        New-HTMLListItem -Text "💾 Monitor database size monthly"
                        New-HTMLListItem -Text "📊 Review DHCP logs for errors weekly"
                        New-HTMLListItem -Text "🖥️ Check server health weekly"
                    } -FontSize 12px
                }
            }
        }
    }
}