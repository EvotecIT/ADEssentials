function New-DHCPSecurityComplianceTab {
    <#
    .SYNOPSIS
    Creates the Security & Compliance tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Security & Compliance tab which focuses on:
    - Security configuration checklist
    - Security risk assessment
    - Audit logs configuration
    - Database & backup configuration
    - Server security settings
    - Backup analysis

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Security & Compliance tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Security & Compliance' {
        # Configuration recommendations
        New-HTMLSection -HeaderText "🔐 Security & Compliance Overview" {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "DHCP Security Best Practices Dashboard" -FontSize 18pt -FontWeight bold -Color DarkBlue
                New-HTMLText -Text "Comprehensive security analysis covering authorization, logging, backup, and compliance requirements for your DHCP infrastructure." -FontSize 12pt -Color DarkGray
            }
        }

        New-HTMLSection -HeaderText "📋 Security Configuration Checklist" -CanCollapse {
            New-HTMLPanel {
                New-HTMLText -Text "Essential Security Practices for DHCP:" -FontSize 14px -FontWeight bold -Color DarkBlue
                New-HTMLList {
                    New-HTMLListItem -Text "✅ Authorize all DHCP servers in Active Directory to prevent rogue servers"
                    New-HTMLListItem -Text "✅ Enable DHCP audit logging on all servers for security monitoring and compliance"
                    New-HTMLListItem -Text "✅ Configure appropriate lease durations (8-24 hours) to balance security and performance"
                    New-HTMLListItem -Text "✅ Implement DHCP failover for high availability in critical environments"
                    New-HTMLListItem -Text "✅ Use consistent and secure DNS server assignments across all scopes"
                    New-HTMLListItem -Text "✅ Regularly backup DHCP database configuration for disaster recovery"
                    New-HTMLListItem -Text "✅ Monitor and document IP address assignments and reservations"
                    New-HTMLListItem -Text "✅ Review and validate scope options against security policies"
                    New-HTMLListItem -Text "✅ Implement conflict detection to prevent IP address conflicts"
                    New-HTMLListItem -Text "✅ Use dedicated service accounts for DHCP services"
                } -FontSize 12px
            } -Invisible
        }

        # Enhanced Security Analysis Section
        if ($DHCPData.SecurityAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "🔒 Security Risk Assessment" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Server Security Analysis" -FontSize 16pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Detailed analysis of DHCP server authorization status, security configurations, and potential risks across your infrastructure." -FontSize 12pt -Color DarkGray
                    New-HTMLText -Text "⚠️ Note: Some security details require administrative access to DHCP servers for complete analysis." -FontSize 10pt -Color Gray

                    # Security summary
                    $AuthorizedServers = ($DHCPData.SecurityAnalysis | Where-Object { $_.IsAuthorized -eq $true }).Count
                    $CriticalRisk = ($DHCPData.SecurityAnalysis | Where-Object { $_.SecurityRiskLevel -eq 'Critical' }).Count
                    $HighRisk = ($DHCPData.SecurityAnalysis | Where-Object { $_.SecurityRiskLevel -eq 'High' }).Count
                    $AuditEnabled = ($DHCPData.SecurityAnalysis | Where-Object { $_.AuditLoggingEnabled -eq $true }).Count

                    New-HTMLSection -HeaderText "Security Health Dashboard" -Invisible -Density Compact {
                        if ($AuthorizedServers -eq $DHCPData.SecurityAnalysis.Count) {
                            New-HTMLInfoCard -Title "Authorization" -Number "$AuthorizedServers/$($DHCPData.SecurityAnalysis.Count)" -Subtitle "All Authorized" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen
                        } else {
                            New-HTMLInfoCard -Title "Authorization" -Number "$AuthorizedServers/$($DHCPData.SecurityAnalysis.Count)" -Subtitle "Need Attention" -Icon "⚠️" -TitleColor Crimson -NumberColor DarkRed -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                        }

                        if ($CriticalRisk -eq 0) {
                            New-HTMLInfoCard -Title "Critical Risks" -Number $CriticalRisk -Subtitle "None Found" -Icon "🛡️" -TitleColor LimeGreen -NumberColor DarkGreen
                        } else {
                            New-HTMLInfoCard -Title "Critical Risks" -Number $CriticalRisk -Subtitle "Immediate Action" -Icon "🚨" -TitleColor Crimson -NumberColor DarkRed -ShadowColor 'rgba(220, 20, 60, 0.3)' -ShadowIntensity ExtraBold
                        }

                        New-HTMLInfoCard -Title "High Risks" -Number $HighRisk -Subtitle "Review Required" -Icon "⚠️" -TitleColor Orange -NumberColor DarkOrange
                        New-HTMLInfoCard -Title "Audit Logging" -Number "$AuditEnabled/$($DHCPData.SecurityAnalysis.Count)" -Subtitle "Enabled" -Icon "📊" -TitleColor Purple -NumberColor DarkMagenta
                    }

                    New-HTMLTable -DataTable $DHCPData.SecurityAnalysis -Filtering {
                        New-HTMLTableCondition -Name 'IsAuthorized' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red
                        New-HTMLTableCondition -Name 'SecurityRiskLevel' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'SecurityRiskLevel' -ComparisonType string -Operator eq -Value 'High' -BackgroundColor Orange -Color White
                        New-HTMLTableCondition -Name 'SecurityRiskLevel' -ComparisonType string -Operator eq -Value 'Medium' -BackgroundColor Yellow
                        New-HTMLTableCondition -Name 'SecurityRiskLevel' -ComparisonType string -Operator eq -Value 'Low' -BackgroundColor LightGreen
                        New-HTMLTableCondition -Name 'AuditLoggingEnabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                    } -DataStore JavaScript -ScrollX -Title "Complete Security Assessment"

                    # Security recommendations summary
                    $SecurityRecommendations = $DHCPData.SecurityAnalysis | Where-Object { $_.SecurityRecommendations.Count -gt 0 }
                    if ($SecurityRecommendations.Count -gt 0) {
                        New-HTMLSection -HeaderText "🚨 Immediate Security Actions Required" -CanCollapse {
                            foreach ($Server in $SecurityRecommendations) {
                                New-HTMLSection -HeaderText "🖥️ $($Server.ServerName)" -CanCollapse {
                                    New-HTMLPanel {
                                        New-HTMLText -Text "Risk Level: " -FontWeight bold -Color DarkRed
                                        New-HTMLText -Text $Server.SecurityRiskLevel -FontWeight bold -Color $(
                                            switch ($Server.SecurityRiskLevel) {
                                                'Critical' { 'Red' }
                                                'High' { 'Orange' }
                                                'Medium' { 'GoldenRod' }
                                                'Low' { 'Green' }
                                                default { 'Black' }
                                            }
                                        )
                                        foreach ($Recommendation in $Server.SecurityRecommendations) {
                                            New-HTMLText -Text "🔴 $Recommendation" -Color Red -FontSize 12px
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        # Audit Logs with enhanced presentation
        if ($DHCPData.AuditLogs.Count -gt 0) {
            New-HTMLSection -HeaderText "📋 DHCP Audit Log Configuration" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Compliance & Monitoring" -FontSize 16pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Audit logging is essential for security monitoring, troubleshooting, and compliance requirements. Monitor log file sizes and retention policies." -FontSize 12pt -Color DarkGray

                    # Audit summary
                    $AuditEnabled = ($DHCPData.AuditLogs | Where-Object { $_.Enable -eq $true }).Count
                    $SmallLogFiles = ($DHCPData.AuditLogs | Where-Object { $_.MaxMBFileSize -lt 10 }).Count

                    New-HTMLSection -HeaderText "Audit Configuration Summary" -Invisible -Density Compact {
                        if ($AuditEnabled -eq $DHCPData.AuditLogs.Count) {
                            New-HTMLInfoCard -Title "Logging Status" -Number "Enabled" -Subtitle "All Servers" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen
                        } else {
                            New-HTMLInfoCard -Title "Logging Status" -Number "$AuditEnabled/$($DHCPData.AuditLogs.Count)" -Subtitle "Partially Enabled" -Icon "⚠️" -TitleColor Orange -NumberColor DarkOrange
                        }

                        New-HTMLInfoCard -Title "Servers" -Number $DHCPData.AuditLogs.Count -Subtitle "Configured" -Icon "🖥️" -TitleColor DodgerBlue -NumberColor Navy

                        if ($SmallLogFiles -gt 0) {
                            New-HTMLInfoCard -Title "Small Log Files" -Number $SmallLogFiles -Subtitle "< 10MB (Review)" -Icon "📁" -TitleColor Orange -NumberColor DarkOrange
                        } else {
                            New-HTMLInfoCard -Title "Log File Sizes" -Number "Adequate" -Subtitle "≥ 10MB" -Icon "📁" -TitleColor LimeGreen -NumberColor DarkGreen
                        }
                    }

                    New-HTMLTable -DataTable $DHCPData.AuditLogs -Filtering {
                        New-HTMLTableCondition -Name 'Enable' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'MaxMBFileSize' -ComparisonType number -Operator lt -Value 10 -BackgroundColor Orange -HighlightHeaders 'MaxMBFileSize'
                        New-HTMLTableCondition -Name 'MinMBDiskSpace' -ComparisonType number -Operator lt -Value 100 -BackgroundColor Yellow -HighlightHeaders 'MinMBDiskSpace'
                    } -DataStore JavaScript -Title "Detailed Audit Log Configuration"
                }
            }
        }

        # Database Configuration with enhanced visuals
        if ($DHCPData.Databases.Count -gt 0) {
            New-HTMLSection -HeaderText "💾 Database & Backup Configuration" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Data Protection Analysis" -FontSize 16pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "DHCP database backup and maintenance configuration is critical for disaster recovery and maintaining service availability." -FontSize 12pt -Color DarkGray

                    # Database summary
                    $BackupEnabled = ($DHCPData.Databases | Where-Object { $_.LoggingEnabled -eq $true }).Count
                    $ShortBackupInterval = ($DHCPData.Databases | Where-Object { $_.BackupIntervalMinutes -gt 0 -and $_.BackupIntervalMinutes -le 60 }).Count
                    $LongCleanupInterval = ($DHCPData.Databases | Where-Object { $_.CleanupIntervalMinutes -gt 10080 }).Count

                    New-HTMLSection -HeaderText "Database Health Summary" -Invisible -Density Compact {
                        if ($BackupEnabled -eq $DHCPData.Databases.Count) {
                            New-HTMLInfoCard -Title "Backup Status" -Number "Enabled" -Subtitle "All Databases" -Icon "✅" -TitleColor LimeGreen -NumberColor DarkGreen
                        } else {
                            New-HTMLInfoCard -Title "Backup Status" -Number "$BackupEnabled/$($DHCPData.Databases.Count)" -Subtitle "Check Config" -Icon "⚠️" -TitleColor Orange -NumberColor DarkOrange
                        }

                        New-HTMLInfoCard -Title "Databases" -Number $DHCPData.Databases.Count -Subtitle "Configured" -Icon "💾" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "Optimal Backup" -Number $ShortBackupInterval -Subtitle "≤60min Interval" -Icon "⏱️" -TitleColor Purple -NumberColor DarkMagenta

                        if ($LongCleanupInterval -gt 0) {
                            New-HTMLInfoCard -Title "Cleanup Issues" -Number $LongCleanupInterval -Subtitle ">7 Days" -Icon "🧹" -TitleColor Orange -NumberColor DarkOrange
                        } else {
                            New-HTMLInfoCard -Title "Cleanup Config" -Number "Optimal" -Subtitle "≤7 Days" -Icon "🧹" -TitleColor LimeGreen -NumberColor DarkGreen
                        }
                    }

                    New-HTMLTable -DataTable $DHCPData.Databases -Filtering {
                        New-HTMLTableCondition -Name 'LoggingEnabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'BackupIntervalMinutes' -ComparisonType number -Operator gt -Value 1440 -BackgroundColor Orange -HighlightHeaders 'BackupIntervalMinutes'
                        New-HTMLTableCondition -Name 'BackupIntervalMinutes' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Red -Color White -HighlightHeaders 'BackupIntervalMinutes'
                        New-HTMLTableCondition -Name 'CleanupIntervalMinutes' -ComparisonType number -Operator gt -Value 10080 -BackgroundColor Orange -HighlightHeaders 'CleanupIntervalMinutes'
                        New-HTMLTableCondition -Name 'RestoreFromBackup' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightYellow -HighlightHeaders 'RestoreFromBackup'
                    } -DataStore JavaScript -Title "Complete Database Configuration"
                }
            }
        }

        # Server Configuration Summary with enhanced presentation
        if ($DHCPData.ServerSettings.Count -gt 0) {
            New-HTMLSection -HeaderText "⚙️ Server Security Settings" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Server-Level Security Configuration" -FontSize 16pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "Core security settings that affect the entire DHCP server operation, including authorization, policies, and conflict detection." -FontSize 12pt -Color DarkGray

                    # Server settings summary
                    $AuthorizedServers = ($DHCPData.ServerSettings | Where-Object { $_.IsAuthorized -eq $true }).Count
                    $DomainJoinedServers = ($DHCPData.ServerSettings | Where-Object { $_.IsDomainJoined -eq $true }).Count
                    $ConflictDetectionEnabled = ($DHCPData.ServerSettings | Where-Object { $_.ConflictDetectionAttempts -gt 0 }).Count
                    $PoliciesActive = ($DHCPData.ServerSettings | Where-Object { $_.ActivatePolicies -eq $true }).Count

                    New-HTMLSection -HeaderText "Security Settings Overview" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "AD Authorization" -Number "$AuthorizedServers/$($DHCPData.ServerSettings.Count)" -Subtitle "Servers" -Icon "🔐" -TitleColor LimeGreen -NumberColor DarkGreen
                        New-HTMLInfoCard -Title "Domain Joined" -Number "$DomainJoinedServers/$($DHCPData.ServerSettings.Count)" -Subtitle "Servers" -Icon "🏢" -TitleColor DodgerBlue -NumberColor Navy
                        New-HTMLInfoCard -Title "Conflict Detection" -Number "$ConflictDetectionEnabled/$($DHCPData.ServerSettings.Count)" -Subtitle "Enabled" -Icon "🛡️" -TitleColor Purple -NumberColor DarkMagenta
                        New-HTMLInfoCard -Title "Policies Active" -Number "$PoliciesActive/$($DHCPData.ServerSettings.Count)" -Subtitle "Servers" -Icon "📋" -TitleColor Orange -NumberColor DarkOrange
                    }

                    New-HTMLTable -DataTable $DHCPData.ServerSettings -HideFooter {
                        New-HTMLTableCondition -Name 'IsAuthorized' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red
                        New-HTMLTableCondition -Name 'ActivatePolicies' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen
                        New-HTMLTableCondition -Name 'ConflictDetectionAttempts' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Orange -HighlightHeaders 'ConflictDetectionAttempts'
                        New-HTMLTableCondition -Name 'IsDomainJoined' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                    } -Title "DHCP Server Security Configuration"
                }
            }
        }

        # Enhanced Backup Analysis Section
        if ($DHCPData.BackupAnalysis -and $DHCPData.BackupAnalysis.Count -gt 0) {
            New-HTMLSection -HeaderText "💾 Backup Analysis & Data Protection" {
                New-HTMLPanel -Invisible {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "DHCP Database Backup Assessment" -FontSize 16pt -FontWeight bold -Color DarkBlue
                        New-HTMLText -Text "Analysis of backup configurations, schedules, and data protection strategies." -FontSize 12pt
                    }

                    New-HTMLTable -DataTable $DHCPData.BackupAnalysis -Filtering {
                        New-HTMLTableCondition -Name 'BackupEnabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red
                        New-HTMLTableCondition -Name 'BackupStatus' -ComparisonType string -Operator eq -Value 'Critical' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'BackupStatus' -ComparisonType string -Operator eq -Value 'Warning' -BackgroundColor Orange -Color White
                        New-HTMLTableCondition -Name 'BackupStatus' -ComparisonType string -Operator eq -Value 'Healthy' -BackgroundColor LightGreen
                        New-HTMLTableCondition -Name 'BackupIntervalMinutes' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Red -Color White -HighlightHeaders 'BackupIntervalMinutes'
                        New-HTMLTableCondition -Name 'BackupIntervalMinutes' -ComparisonType number -Operator gt -Value 120 -BackgroundColor Orange -HighlightHeaders 'BackupIntervalMinutes'
                        New-HTMLTableCondition -Name 'CleanupIntervalMinutes' -ComparisonType number -Operator eq -Value 0 -BackgroundColor Red -Color White -HighlightHeaders 'CleanupIntervalMinutes'
                    } -DataStore JavaScript -ScrollX

                    # Backup recommendations summary
                    $BackupRecommendations = $DHCPData.BackupAnalysis | Where-Object { $_.Recommendations.Count -gt 0 }
                    if ($BackupRecommendations.Count -gt 0) {
                        New-HTMLSection -HeaderText "🔧 Backup Recommendations" -Density Compact {
                            foreach ($Server in $BackupRecommendations) {
                                New-HTMLPanel {
                                    New-HTMLText -Text "Server: $($Server.ServerName)" -FontWeight bold -Color DarkRed
                                    foreach ($Recommendation in $Server.Recommendations) {
                                        New-HTMLText -Text "• $Recommendation" -Color Red
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        # If no security configuration data available
        if ($DHCPData.AuditLogs.Count -eq 0 -and $DHCPData.Databases.Count -eq 0 -and $DHCPData.SecurityAnalysis.Count -eq 0) {
            New-HTMLSection -HeaderText "Security Configuration Status" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "ℹ️ Limited security configuration data available" -Color Blue -FontSize 14pt -FontWeight bold
                    New-HTMLText -Text "This may indicate limited access to DHCP server configuration or that detailed security collection was not performed. Consider running with Extended mode for complete analysis." -FontSize 12pt -Color DarkGray
                }
            }
        }
    }
}