function New-DHCPMonitoringTab {
    <#
    .SYNOPSIS
    Creates an advanced monitoring tab for DHCP environments requiring real-time oversight.

    .DESCRIPTION
    This tab provides monitoring recommendations, PowerShell scripts for automation,
    and integration guidance for enterprise monitoring solutions. Adapts recommendations
    based on environment size (small, medium, large).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    # Determine environment size for adaptive recommendations
    $TotalLeases = $DHCPData.Statistics.AddressesInUse
    $OnlineServers = $DHCPData.Statistics.ServersOnline

    $EnvironmentSize = if ($TotalLeases -gt 1000000 -or $OnlineServers -gt 50) { "Enterprise" }
                      elseif ($TotalLeases -gt 100000 -or $OnlineServers -gt 10) { "Corporate" }
                      else { "Business" }

    New-HTMLTab -TabName 'Monitoring & Alerts' {
        New-HTMLSection -HeaderText "📊 DHCP Monitoring Strategy" {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "DHCP Monitoring Framework" -FontSize 18pt -FontWeight bold -Color DarkBlue
                New-HTMLText -Text "Environment: $EnvironmentSize Scale | Monitoring approach tailored to your infrastructure size and complexity." -FontSize 12pt -Color DarkGray
            }
        }

        # Environment-specific monitoring approach
        New-HTMLSection -HeaderText "🎯 Monitoring Approach for $EnvironmentSize Environments" -CanCollapse {
            New-HTMLPanel -Invisible {
                if ($EnvironmentSize -eq "Enterprise") {
                    New-HTMLText -Text "Enterprise Monitoring Requirements:" -FontSize 14px -FontWeight bold -Color DarkRed
                    New-HTMLList {
                        New-HTMLListItem -Text "🔥 Real-time monitoring with automated alerting (24/7)"
                        New-HTMLListItem -Text "📊 SCOM/Splunk integration for centralized monitoring"
                        New-HTMLListItem -Text "⚡ Performance counter monitoring every 1-5 minutes"
                        New-HTMLListItem -Text "🤖 Automated remediation scripts for common issues"
                        New-HTMLListItem -Text "📈 Capacity planning with predictive analytics"
                        New-HTMLListItem -Text "🚨 Multi-tier alerting with escalation procedures"
                        New-HTMLListItem -Text "📋 Compliance reporting and audit trail"
                    } -FontSize 12px
                } elseif ($EnvironmentSize -eq "Corporate") {
                    New-HTMLText -Text "Corporate Monitoring Requirements:" -FontSize 14px -FontWeight bold -Color DarkOrange
                    New-HTMLList {
                        New-HTMLListItem -Text "📊 Scheduled monitoring with email alerts (business hours)"
                        New-HTMLListItem -Text "⚡ Performance monitoring every 15-30 minutes"
                        New-HTMLListItem -Text "🔍 PowerShell scripts for automated health checks"
                        New-HTMLListItem -Text "📈 Monthly capacity planning reviews"
                        New-HTMLListItem -Text "🚨 Critical alerts with on-call procedures"
                        New-HTMLListItem -Text "📋 Regular reporting for management"
                    } -FontSize 12px
                } else {
                    New-HTMLText -Text "Business Monitoring Requirements:" -FontSize 14px -FontWeight bold -Color DarkBlue
                    New-HTMLList {
                        New-HTMLListItem -Text "📊 Daily/weekly manual checks with email notifications"
                        New-HTMLListItem -Text "⚡ Basic health monitoring every hour"
                        New-HTMLListItem -Text "🔍 Simple PowerShell scripts for key metrics"
                        New-HTMLListItem -Text "📈 Quarterly capacity planning reviews"
                        New-HTMLListItem -Text "🚨 Critical alerts via email/SMS"
                        New-HTMLListItem -Text "📋 Monthly summary reports"
                    } -FontSize 12px
                }
            }
        }

        # Performance Counters Section (adaptive)
        New-HTMLSection -HeaderText "📈 Performance Counters to Monitor" -CanCollapse {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Windows Performance Counters for DHCP Monitoring:" -FontSize 14px -FontWeight bold -Color DarkBlue

                # Create adaptive performance counter table based on environment size
                $PerformanceCounters = if ($EnvironmentSize -eq "Enterprise") {
                    @(
                        [PSCustomObject]@{
                            Category = "DHCP Server"
                            Counter = "Discovers/sec"
                            Threshold = "< 1000/sec"
                            Criticality = "High"
                            MonitoringFreq = "Real-time"
                            Description = "DHCP discovery requests per second"
                            AlertCondition = "> 1000/sec indicates potential DoS or network storm"
                        },
                        [PSCustomObject]@{
                            Category = "DHCP Server"
                            Counter = "Requests/sec"
                            Threshold = "< 2000/sec"
                            Criticality = "High"
                            MonitoringFreq = "Real-time"
                            Description = "Total DHCP requests per second"
                            AlertCondition = "> 2000/sec may indicate server overload"
                        },
                        [PSCustomObject]@{
                            Category = "DHCP Server"
                            Counter = "Naks/sec"
                            Threshold = "< 10/sec"
                            Criticality = "Critical"
                            MonitoringFreq = "Real-time"
                            Description = "Rejected DHCP requests per second"
                            AlertCondition = "> 10/sec indicates configuration problems"
                        },
                        [PSCustomObject]@{
                            Category = "Process"
                            Counter = "Working Set (dhcp)"
                            Threshold = "< 4GB"
                            Criticality = "High"
                            MonitoringFreq = "Every 5 min"
                            Description = "DHCP service memory usage"
                            AlertCondition = "> 4GB indicates memory pressure"
                        },
                        [PSCustomObject]@{
                            Category = "LogicalDisk"
                            Counter = "% Free Space (C:)"
                            Threshold = "> 20%"
                            Criticality = "Critical"
                            MonitoringFreq = "Every 15 min"
                            Description = "Free disk space on DHCP server"
                            AlertCondition = "< 20% affects database backup and logging"
                        }
                    )
                } elseif ($EnvironmentSize -eq "Corporate") {
                    @(
                        [PSCustomObject]@{
                            Category = "DHCP Server"
                            Counter = "Requests/sec"
                            Threshold = "< 500/sec"
                            Criticality = "High"
                            MonitoringFreq = "Every 15 min"
                            Description = "Total DHCP requests per second"
                            AlertCondition = "> 500/sec may indicate server stress"
                        },
                        [PSCustomObject]@{
                            Category = "DHCP Server"
                            Counter = "Naks/sec"
                            Threshold = "< 5/sec"
                            Criticality = "Critical"
                            MonitoringFreq = "Every 15 min"
                            Description = "Rejected DHCP requests per second"
                            AlertCondition = "> 5/sec indicates configuration problems"
                        },
                        [PSCustomObject]@{
                            Category = "Process"
                            Counter = "Working Set (dhcp)"
                            Threshold = "< 2GB"
                            Criticality = "Medium"
                            MonitoringFreq = "Every 30 min"
                            Description = "DHCP service memory usage"
                            AlertCondition = "> 2GB should be monitored"
                        },
                        [PSCustomObject]@{
                            Category = "LogicalDisk"
                            Counter = "% Free Space (C:)"
                            Threshold = "> 15%"
                            Criticality = "High"
                            MonitoringFreq = "Every 30 min"
                            Description = "Free disk space on DHCP server"
                            AlertCondition = "< 15% affects operations"
                        }
                    )
                } else {
                    @(
                        [PSCustomObject]@{
                            Category = "DHCP Server"
                            Counter = "Naks/sec"
                            Threshold = "< 2/sec"
                            Criticality = "High"
                            MonitoringFreq = "Hourly"
                            Description = "Rejected DHCP requests per second"
                            AlertCondition = "> 2/sec indicates issues"
                        },
                        [PSCustomObject]@{
                            Category = "Process"
                            Counter = "Working Set (dhcp)"
                            Threshold = "< 1GB"
                            Criticality = "Medium"
                            MonitoringFreq = "Daily"
                            Description = "DHCP service memory usage"
                            AlertCondition = "> 1GB should be checked"
                        },
                        [PSCustomObject]@{
                            Category = "LogicalDisk"
                            Counter = "% Free Space (C:)"
                            Threshold = "> 10%"
                            Criticality = "High"
                            MonitoringFreq = "Daily"
                            Description = "Free disk space on DHCP server"
                            AlertCondition = "< 10% critical for operations"
                        }
                    )
                }

                New-HTMLTable -DataTable $PerformanceCounters -Filtering {
                    New-HTMLTableCondition -Name 'Criticality' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                    New-HTMLTableCondition -Name 'Criticality' -ComparisonType string -Operator eq -Value 'High' -BackgroundColor Orange -Color White
                    New-HTMLTableCondition -Name 'Criticality' -ComparisonType string -Operator eq -Value 'Medium' -BackgroundColor Yellow
                } -DataStore JavaScript -Title "DHCP Performance Counters Monitoring Matrix"
            }
        }

        # PowerShell Monitoring Scripts (adaptive complexity)
        New-HTMLSection -HeaderText "⚡ PowerShell Monitoring Scripts" -CanCollapse {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Automated Monitoring Scripts for $EnvironmentSize Infrastructure:" -FontSize 14px -FontWeight bold -Color DarkBlue

                if ($EnvironmentSize -eq "Enterprise") {
                    New-HTMLText -Text "Enterprise-grade scripts with comprehensive monitoring and automated remediation. Run every 5-15 minutes." -FontSize 12pt -Color DarkGray
                } elseif ($EnvironmentSize -eq "Corporate") {
                    New-HTMLText -Text "Corporate-level scripts with essential monitoring and alerting. Run every 15-30 minutes." -FontSize 12pt -Color DarkGray
                } else {
                    New-HTMLText -Text "Business-focused scripts for key health metrics. Run hourly or daily as needed." -FontSize 12pt -Color DarkGray
                }

                # DHCP Health Check Script (adaptive)
                New-HTMLSection -HeaderText "🔍 DHCP Health Check Script" -CanCollapse {
                    $HealthCheckScript = if ($EnvironmentSize -eq "Enterprise") {
                        @"
# Enterprise DHCP Health Check Script
# Run every 5 minutes via scheduled task with comprehensive monitoring

`$DHCPServers = Get-DhcpServerInDC
`$AlertThresholds = @{
    CriticalUtilization = 90
    HighUtilization = 80
    MaxResponseTime = 100    # Enterprise: 100ms threshold
    MaxNakRate = 10
    MaxMemoryGB = 4
    MinDiskSpacePercent = 20
}

foreach (`$Server in `$DHCPServers) {
    try {
        # Test DHCP service responsiveness with timing
        `$ResponseTime = Measure-Command { Get-DhcpServerv4Scope -ComputerName `$Server.DnsName }

        # Get scope utilization and detailed metrics
        `$Scopes = Get-DhcpServerv4ScopeStatistics -ComputerName `$Server.DnsName
        `$CriticalScopes = `$Scopes | Where-Object { `$_.PercentageInUse -gt `$AlertThresholds.CriticalUtilization }

        # Get performance counters
        `$Counters = Get-Counter -ComputerName `$Server.DnsName -Counter "\DHCP Server\Naks/sec", "\Process(dhcp)\Working Set"
        `$NakRate = (`$Counters.CounterSamples | Where-Object { `$_.Path -like "*Naks/sec" }).CookedValue
        `$MemoryMB = (`$Counters.CounterSamples | Where-Object { `$_.Path -like "*Working Set" }).CookedValue / 1MB

        # Generate enterprise-level alerts with detailed information
        if (`$CriticalScopes.Count -gt 0) {
            `$ScopeDetails = (`$CriticalScopes | ForEach-Object { "`$(`$_.ScopeId) (`$(`$_.PercentageInUse)%)" }) -join ", "
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1001 -Message "CRITICAL: `$(`$CriticalScopes.Count) scopes >90% on `$(`$Server.DnsName): `$ScopeDetails"
        }

        if (`$ResponseTime.TotalMilliseconds -gt `$AlertThresholds.MaxResponseTime) {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Warning -EventId 1002 -Message "SLOW RESPONSE: `$(`$Server.DnsName) response time `$(`$ResponseTime.TotalMilliseconds)ms (threshold: `$(`$AlertThresholds.MaxResponseTime)ms)"
        }

        if (`$NakRate -gt `$AlertThresholds.MaxNakRate) {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1003 -Message "HIGH NAK RATE: `$(`$Server.DnsName) NAK rate `$NakRate/sec (threshold: `$(`$AlertThresholds.MaxNakRate)/sec)"
        }

        if (`$MemoryMB -gt (`$AlertThresholds.MaxMemoryGB * 1024)) {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Warning -EventId 1006 -Message "HIGH MEMORY: `$(`$Server.DnsName) using `$([Math]::Round(`$MemoryMB/1024, 2))GB memory"
        }

        # Log successful check for audit trail
        Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Information -EventId 1999 -Message "HEALTH CHECK OK: `$(`$Server.DnsName) - Scopes: `$(`$Scopes.Count), Utilization: `$((`$Scopes | Measure-Object PercentageInUse -Average).Average)%"

    } catch {
        Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1000 -Message "DHCP SERVER UNREACHABLE: `$(`$Server.DnsName) - `$(`$_.Exception.Message)"

        # Enterprise: Attempt automatic service restart if configured
        if (`$env:DHCP_AUTO_RESTART -eq "true") {
            try {
                Restart-Service -Name DHCPServer -ComputerName `$Server.DnsName -Force
                Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Warning -EventId 1007 -Message "AUTO-RESTART: Attempted service restart on `$(`$Server.DnsName)"
            } catch {
                Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1008 -Message "AUTO-RESTART FAILED: `$(`$Server.DnsName) - `$(`$_.Exception.Message)"
            }
        }
    }
}
"@
                    } elseif ($EnvironmentSize -eq "Corporate") {
                        @"
# Corporate DHCP Health Check Script
# Run every 15-30 minutes via scheduled task

`$DHCPServers = Get-DhcpServerInDC
`$AlertThresholds = @{
    CriticalUtilization = 85
    HighUtilization = 75
    MaxResponseTime = 200    # Corporate: 200ms threshold
    MaxNakRate = 5
}

foreach (`$Server in `$DHCPServers) {
    try {
        # Test DHCP service responsiveness
        `$ResponseTime = Measure-Command { Get-DhcpServerv4Scope -ComputerName `$Server.DnsName }

        # Get scope utilization
        `$Scopes = Get-DhcpServerv4ScopeStatistics -ComputerName `$Server.DnsName
        `$CriticalScopes = `$Scopes | Where-Object { `$_.PercentageInUse -gt `$AlertThresholds.CriticalUtilization }
        `$HighScopes = `$Scopes | Where-Object { `$_.PercentageInUse -gt `$AlertThresholds.HighUtilization -and `$_.PercentageInUse -le `$AlertThresholds.CriticalUtilization }

        # Generate alerts
        if (`$CriticalScopes.Count -gt 0) {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1001 -Message "CRITICAL: `$(`$CriticalScopes.Count) scopes >85% on `$(`$Server.DnsName)"
        }

        if (`$HighScopes.Count -gt 0) {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Warning -EventId 1002 -Message "WARNING: `$(`$HighScopes.Count) scopes >75% on `$(`$Server.DnsName)"
        }

        if (`$ResponseTime.TotalMilliseconds -gt `$AlertThresholds.MaxResponseTime) {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Warning -EventId 1003 -Message "SLOW RESPONSE: `$(`$Server.DnsName) response time `$(`$ResponseTime.TotalMilliseconds)ms"
        }

    } catch {
        Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1000 -Message "DHCP SERVER UNREACHABLE: `$(`$Server.DnsName) - `$(`$_.Exception.Message)"
    }
}
"@
                    } else {
                        @"
# Business DHCP Health Check Script
# Run hourly or daily as needed

`$DHCPServers = Get-DhcpServerInDC
`$AlertThresholds = @{
    CriticalUtilization = 80
    MaxResponseTime = 500    # Business: 500ms threshold (more lenient)
}

foreach (`$Server in `$DHCPServers) {
    try {
        # Basic connectivity test
        if (Test-Connection -ComputerName `$Server.DnsName -Count 2 -Quiet) {
            # Get scope utilization
            `$Scopes = Get-DhcpServerv4ScopeStatistics -ComputerName `$Server.DnsName
            `$CriticalScopes = `$Scopes | Where-Object { `$_.PercentageInUse -gt `$AlertThresholds.CriticalUtilization }

            if (`$CriticalScopes.Count -gt 0) {
                Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Warning -EventId 1001 -Message "HIGH UTILIZATION: `$(`$CriticalScopes.Count) scopes >80% on `$(`$Server.DnsName)"
            }

            # Check overall server health
            `$AvgUtilization = (`$Scopes | Measure-Object PercentageInUse -Average).Average
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Information -EventId 1999 -Message "HEALTH CHECK: `$(`$Server.DnsName) - `$(`$Scopes.Count) scopes, avg utilization: `$([Math]::Round(`$AvgUtilization, 1))%"

        } else {
            Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1000 -Message "DHCP SERVER UNREACHABLE: `$(`$Server.DnsName)"
        }
    } catch {
        Write-EventLog -LogName Application -Source "DHCP Monitor" -EntryType Error -EventId 1000 -Message "DHCP CHECK FAILED: `$(`$Server.DnsName) - `$(`$_.Exception.Message)"
    }
}
"@
                    }
                    New-HTMLCodeBlock -Code $HealthCheckScript -Style powershell
                }
            }
        }

        # Monitoring Integration (environment-specific)
        if ($EnvironmentSize -eq "Enterprise") {
            New-HTMLSection -HeaderText "🔔 Enterprise Monitoring Integration" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Integration with Enterprise Monitoring Solutions" -FontSize 14px -FontWeight bold -Color DarkBlue

                    # SCOM Configuration
                    New-HTMLSection -HeaderText "📊 SCOM (System Center Operations Manager)" -CanCollapse {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "SCOM Management Pack Recommendations:" -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Install Microsoft DHCP Server Management Pack"
                                New-HTMLListItem -Text "Configure custom performance counter monitors for DHCP counters"
                                New-HTMLListItem -Text "Set up distributed application monitoring for DHCP service dependencies"
                                New-HTMLListItem -Text "Create custom rules for scope utilization monitoring"
                                New-HTMLListItem -Text "Implement heartbeat monitoring for DHCP service availability"
                            } -FontSize 12px

                            New-HTMLText -Text "Critical SCOM Rules to Configure:" -FontWeight bold -Color DarkRed
                            New-HTMLList {
                                New-HTMLListItem -Text "DHCP Server Service Down - Immediate Alert"
                                New-HTMLListItem -Text "Scope Utilization >85% - Warning Alert"
                                New-HTMLListItem -Text "Scope Utilization >90% - Critical Alert"
                                New-HTMLListItem -Text "DHCP Response Time >100ms - Warning"
                                New-HTMLListItem -Text "Database Size >2GB - Information Alert"
                                New-HTMLListItem -Text "Failover Partner Down - Critical Alert"
                            } -FontSize 12px
                        }
                    }

                    # Splunk Configuration
                    New-HTMLSection -HeaderText "🔍 Splunk/Log Analytics" -CanCollapse {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Log Collection and Analysis:" -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Enable DHCP audit logging on all servers"
                                New-HTMLListItem -Text "Forward DHCP audit logs to Splunk/Azure Log Analytics"
                                New-HTMLListItem -Text "Create dashboards for lease trends and utilization"
                                New-HTMLListItem -Text "Set up alerts for abnormal DHCP request patterns"
                                New-HTMLListItem -Text "Monitor for potential security issues (DHCP starvation attacks)"
                            } -FontSize 12px

                            $SplunkQuery = @"
# Sample Splunk Query for DHCP Monitoring
index=dhcp sourcetype=dhcp_audit
| stats count by DHCPServer, EventType
| where EventType="NAK" AND count > 10
| sort -count
"@
                            New-HTMLCodeBlock -Code $SplunkQuery -Style javascript
                        }
                    }
                }
            }
        } elseif ($EnvironmentSize -eq "Corporate") {
            New-HTMLSection -HeaderText "📊 Corporate Monitoring Solutions" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Recommended Monitoring Tools for Corporate Environments:" -FontSize 14px -FontWeight bold -Color DarkOrange
                    New-HTMLList {
                        New-HTMLListItem -Text "📧 Email-based alerting with PowerShell scripts"
                        New-HTMLListItem -Text "📊 Windows Performance Monitor for basic counters"
                        New-HTMLListItem -Text "🔍 Event log monitoring with custom views"
                        New-HTMLListItem -Text "📈 Excel-based reporting for capacity planning"
                        New-HTMLListItem -Text "🤖 Task Scheduler for automated health checks"
                        New-HTMLListItem -Text "📱 SMS alerts for critical issues (via PowerShell)"
                    } -FontSize 12px
                }
            }
        } else {
            New-HTMLSection -HeaderText "📧 Business Monitoring Approach" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Simple Monitoring for Business Environments:" -FontSize 14px -FontWeight bold -Color DarkBlue
                    New-HTMLList {
                        New-HTMLListItem -Text "📧 Email notifications for critical issues"
                        New-HTMLListItem -Text "📋 Weekly manual health check procedures"
                        New-HTMLListItem -Text "🔍 Basic PowerShell scripts for key metrics"
                        New-HTMLListItem -Text "📊 Simple Excel tracking for capacity trends"
                        New-HTMLListItem -Text "📱 Phone/SMS alerts for server down situations"
                    } -FontSize 12px
                }
            }
        }

        # Alerting Matrix (adaptive to environment size)
        New-HTMLSection -HeaderText "🚨 Recommended Alerting Matrix" -CanCollapse {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Alert Configuration for $EnvironmentSize Environments" -FontSize 14px -FontWeight bold -Color DarkBlue

                $AlertMatrix = if ($EnvironmentSize -eq "Enterprise") {
                    @(
                        [PSCustomObject]@{
                            Metric = "DHCP Service Down"
                            Severity = "Critical"
                            Threshold = "Service not responding"
                            ResponseTime = "Immediate"
                            Escalation = "Page on-call team + Auto-remediation"
                            Method = "SCOM/Splunk + SMS"
                        },
                        [PSCustomObject]@{
                            Metric = "Scope Utilization"
                            Severity = "Critical"
                            Threshold = ">90%"
                            ResponseTime = "5 minutes"
                            Escalation = "Network team + Management"
                            Method = "Real-time monitoring"
                        },
                        [PSCustomObject]@{
                            Metric = "Response Time"
                            Severity = "Warning"
                            Threshold = ">100ms"
                            ResponseTime = "15 minutes"
                            Escalation = "Network team"
                            Method = "Performance counters"
                        },
                        [PSCustomObject]@{
                            Metric = "NAK Rate"
                            Severity = "High"
                            Threshold = ">10/sec"
                            ResponseTime = "10 minutes"
                            Escalation = "Network team"
                            Method = "Real-time counters"
                        }
                    )
                } elseif ($EnvironmentSize -eq "Corporate") {
                    @(
                        [PSCustomObject]@{
                            Metric = "DHCP Service Down"
                            Severity = "Critical"
                            Threshold = "Service not responding"
                            ResponseTime = "15 minutes"
                            Escalation = "IT team + Management"
                            Method = "Email + SMS"
                        },
                        [PSCustomObject]@{
                            Metric = "Scope Utilization"
                            Severity = "High"
                            Threshold = ">85%"
                            ResponseTime = "30 minutes"
                            Escalation = "Network team"
                            Method = "Scheduled checks"
                        },
                        [PSCustomObject]@{
                            Metric = "Response Time"
                            Severity = "Warning"
                            Threshold = ">200ms"
                            ResponseTime = "1 hour"
                            Escalation = "IT team"
                            Method = "Periodic monitoring"
                        },
                        [PSCustomObject]@{
                            Metric = "Server Unreachable"
                            Severity = "High"
                            Threshold = "Ping failure"
                            ResponseTime = "15 minutes"
                            Escalation = "IT team"
                            Method = "Network monitoring"
                        }
                    )
                } else {
                    @(
                        [PSCustomObject]@{
                            Metric = "DHCP Service Down"
                            Severity = "Critical"
                            Threshold = "Service not responding"
                            ResponseTime = "1 hour"
                            Escalation = "Admin + Management"
                            Method = "Email notification"
                        },
                        [PSCustomObject]@{
                            Metric = "Scope Utilization"
                            Severity = "Warning"
                            Threshold = ">80%"
                            ResponseTime = "4 hours"
                            Escalation = "Admin team"
                            Method = "Daily checks"
                        },
                        [PSCustomObject]@{
                            Metric = "Server Unreachable"
                            Severity = "High"
                            Threshold = "Ping failure"
                            ResponseTime = "2 hours"
                            Escalation = "Admin team"
                            Method = "Manual checks"
                        }
                    )
                }

                New-HTMLTable -DataTable $AlertMatrix -Filtering {
                    New-HTMLTableCondition -Name 'Severity' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                    New-HTMLTableCondition -Name 'Severity' -ComparisonType string -Operator eq -Value 'High' -BackgroundColor Orange -Color White
                    New-HTMLTableCondition -Name 'Severity' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Yellow
                } -DataStore JavaScript -Title "$EnvironmentSize DHCP Alerting Matrix"
            }
        }
    }
}