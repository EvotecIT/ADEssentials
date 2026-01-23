function New-DHCPMinimalValidationTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPData
    )

    New-HTMLTab -TabName 'Validation Results' {
        if ($DHCPData.ScopesWithIssues.Count -gt 0) {
            # Group issues by type for summary (align with full report categories)
            $LeaseDurationIssues = $DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration
            $PublicDNSWithUpdates = $DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates
            $DNSConfigurationProblems = $DHCPData.ValidationResults.CriticalIssues.DNSConfigurationProblems
            $DNSRecordManagement = $DHCPData.ValidationResults.WarningIssues.DNSRecordManagement
            $MissingDomainName = $DHCPData.ValidationResults.InfoIssues.MissingDomainName
            $FailoverIssues = $DHCPData.ValidationResults.WarningIssues.MissingFailover

            $LeaseDurationCount = @($LeaseDurationIssues).Count
            $PublicDNSCount = @($PublicDNSWithUpdates).Count
            $DNSConfigProblemsCount = @($DNSConfigurationProblems).Count
            $DNSRecordMgmtCount = @($DNSRecordManagement).Count
            $MissingDomainNameCount = @($MissingDomainName).Count
            $FailoverCount = @($FailoverIssues).Count

            # Summary Section
            New-HTMLSection -Invisible {
                New-HTMLSection -HeaderText "Configuration Validation Summary" {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "Issues Detected" -FontSize 18px -FontWeight bold -Color Red
                        New-HTMLText -Text "The following configuration issues were found during validation:" -FontSize 12px
                        New-HTMLList {
                            New-HTMLListItem -Text "Total Issues: ", "$($DHCPData.ScopesWithIssues.Count) scope(s) with problems" -FontWeight bold, normal -Color Red, Black
                            if ($LeaseDurationCount -gt 0) {
                                New-HTMLListItem -Text "Lease Duration: ", "$LeaseDurationCount scope(s) exceed 48 hours" -FontWeight bold, normal -Color Orange, Black
                            }
                            if ($PublicDNSCount -gt 0) {
                                New-HTMLListItem -Text "Public DNS + Updates: ", "$PublicDNSCount scope(s)" -FontWeight bold, normal -Color Orange, Black
                            }
                            if ($DNSConfigProblemsCount -gt 0) {
                                New-HTMLListItem -Text "DNS Configuration Problems: ", "$DNSConfigProblemsCount scope(s)" -FontWeight bold, normal -Color Orange, Black
                            }
                            if ($DNSRecordMgmtCount -gt 0) {
                                New-HTMLListItem -Text "DNS Record Management: ", "$DNSRecordMgmtCount scope(s)" -FontWeight bold, normal -Color Orange, Black
                            }
                            if ($MissingDomainNameCount -gt 0) {
                                New-HTMLListItem -Text "Missing Domain Name Option: ", "$MissingDomainNameCount scope(s)" -FontWeight bold, normal -Color Orange, Black
                            }
                            if ($FailoverCount -gt 0) {
                                New-HTMLListItem -Text "Failover Missing: ", "$FailoverCount scope(s) without redundancy" -FontWeight bold, normal -Color Orange, Black
                            }
                        } -FontSize 14px
                    }
                }
            }

            # Lease Duration Issues
            if ($LeaseDurationCount -gt 0) {
                New-HTMLSection -HeaderText "⏱️ Lease Duration Issues (> 48 hours)" -CanCollapse {
                    New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Scopes with excessive lease duration:" -FontSize 14px -FontWeight bold
                            New-HTMLTable -DataTable $LeaseDurationIssues {
                                New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 168 -BackgroundColor Red -Color White
                                New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 96 -BackgroundColor Orange
                                New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Yellow
                            } -ScrollX -IncludeProperty @(
                                'ServerName', 'ScopeId', 'Name', 'LeaseDurationHours', 'Description'
                            ) -Filtering
                            New-HTMLText -Text "Recommendation:" -FontSize 12px -FontWeight bold -Color Blue
                            New-HTMLText -Text "Reduce lease duration to ≤ 48 hours or add 'DHCP lease time=Xd' to scope description for approved exceptions." -FontSize 11px -Color Blue
                        }
                }
            }

            # Public DNS with updates (critical)
            if ($PublicDNSCount -gt 0) {
                New-HTMLSection -HeaderText "🌐 Public DNS Servers with Dynamic Updates Enabled" -CanCollapse {
                    New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Scopes using public DNS servers while dynamic updates are enabled:" -FontSize 14px -FontWeight bold
                            New-HTMLTable -DataTable $PublicDNSWithUpdates {
                                New-HTMLTableCondition -Name 'DNSServers' -ComparisonType string -Operator contains -Value '8.8.8.8' -BackgroundColor Red -Color White
                                New-HTMLTableCondition -Name 'DNSServers' -ComparisonType string -Operator contains -Value '1.1.1.1' -BackgroundColor Red -Color White
                                New-HTMLTableCondition -Name 'DNSServers' -ComparisonType string -Operator contains -Value '8.8.4.4' -BackgroundColor Red -Color White
                                New-HTMLTableCondition -Name 'DNSServers' -ComparisonType string -Operator contains -Value '1.0.0.1' -BackgroundColor Red -Color White
                            } -ScrollX -IncludeProperty @(
                                'ServerName', 'ScopeId', 'Name', 'DNSServers', 'DynamicUpdates'
                            ) -Filtering
                            New-HTMLText -Text "Recommendation:" -FontSize 12px -FontWeight bold -Color Blue
                            New-HTMLText -Text "Replace public DNS servers with internal DNS servers (10.x.x.x)." -FontSize 11px -Color Blue
                        }
                }
            }

            # DNS configuration problems (aggregated when policy enabled)
            if ($DNSConfigProblemsCount -gt 0) {
                New-HTMLSection -HeaderText "⚠️ Scopes with DNS Configuration Problems" -CanCollapse {
                    New-HTMLPanel -Invisible {
                        New-HTMLTable -DataTable $DNSConfigurationProblems -Filtering -ScrollX
                    }
                }
            }

            # DNS record management issues (warning)
            if ($DNSRecordMgmtCount -gt 0) {
                New-HTMLSection -HeaderText "DNS Record Management Issues" -CanCollapse {
                    New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Scopes with DNS record management problems:" -FontSize 14px -FontWeight bold
                            New-HTMLTable -DataTable $DNSRecordManagement {
                                New-HTMLTableCondition -Name 'UpdateDnsRRForOlderClients' -ComparisonType bool -Operator eq -Value $false -BackgroundColor Yellow
                                New-HTMLTableCondition -Name 'DeleteDnsRROnLeaseExpiry' -ComparisonType bool -Operator eq -Value $false -BackgroundColor Yellow
                            } -ScrollX -IncludeProperty @(
                                'ServerName', 'ScopeId', 'Name', 'UpdateDnsRRForOlderClients', 'DeleteDnsRROnLeaseExpiry', 'DynamicUpdates'
                            ) -Filtering
                            New-HTMLText -Text "Recommendation:" -FontSize 12px -FontWeight bold -Color Blue
                            New-HTMLText -Text "Enable 'Update DNS RR for Older Clients' and 'Delete DNS RR on Lease Expiry'." -FontSize 11px -Color Blue
                        }
                }
            }

            # Missing domain name (info)
            if ($MissingDomainNameCount -gt 0) {
                New-HTMLSection -HeaderText "Scopes Missing Domain Name Option" -CanCollapse {
                    New-HTMLPanel -Invisible {
                        New-HTMLTable -DataTable $MissingDomainName -Filtering -ScrollX -IncludeProperty @(
                            'ServerName', 'ScopeId', 'Name', 'DomainNameOption', 'DynamicUpdates'
                        )
                        New-HTMLText -Text "Recommendation:" -FontSize 12px -FontWeight bold -Color Blue
                        New-HTMLText -Text "Configure Domain Name option (015) when DNS updates are enabled." -FontSize 11px -Color Blue
                    }
                }
            }

            # Failover Issues
            if ($FailoverCount -gt 0) {
                New-HTMLSection -HeaderText "🔄 Failover Configuration Issues" -CanCollapse {
                    New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Scopes without proper failover configuration:" -FontSize 14px -FontWeight bold
                            New-HTMLTable -DataTable $FailoverIssues {
                                New-HTMLTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackgroundColor Red -Color White
                            } -ScrollX -IncludeProperty @(
                                'ServerName', 'ScopeId', 'Name', 'State', 'FailoverPartner'
                            ) -Filtering
                            New-HTMLText -Text "Recommendation:" -FontSize 12px -FontWeight bold -Color Blue
                            New-HTMLText -Text "Configure DHCP failover for high availability and redundancy." -FontSize 11px -Color Blue
                    }
                }
            }

            # Complete Issues Table
            New-HTMLSection -HeaderText "📄 Complete Issue List" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLTable -DataTable $DHCPData.ScopesWithIssues {
                        New-HTMLTableCondition -Name 'Issues' -ComparisonType string -Operator contains -Value 'duration' -BackgroundColor Yellow
                        New-HTMLTableCondition -Name 'Issues' -ComparisonType string -Operator contains -Value 'DNS' -BackgroundColor Orange
                        New-HTMLTableCondition -Name 'Issues' -ComparisonType string -Operator contains -Value 'failover' -BackgroundColor Red -Color White
                    } -ScrollX -IncludeProperty @(
                        'ServerName', 'ScopeId', 'Name', 'State', 'Issues'
                    ) -Filtering
                }
            }
        } else {
            # No issues found
            New-HTMLSection -Invisible {
                New-HTMLSection -HeaderText "✅ Validation Results" {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "All Validations Passed" -FontSize 20px -FontWeight bold -Color Green -TextAlign center
                        New-HTMLText -Text "No configuration issues detected in your DHCP infrastructure." -FontSize 14px -TextAlign center

                        New-HTMLText -Text "Validation Checks Performed:" -FontSize 14px -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Lease Duration: ", "All scopes ≤ 48 hours or have approved exceptions" -FontWeight bold, normal -Color Green, Black
                            New-HTMLListItem -Text "DNS Configuration: ", "All scopes use internal DNS servers with proper settings" -FontWeight bold, normal -Color Green, Black
                            New-HTMLListItem -Text "Failover Status: ", "All required scopes have failover configured" -FontWeight bold, normal -Color Green, Black
                        } -FontSize 12px
                    }
                }
            }
        }
    }
}
