function New-DHCPMinimalAllScopesTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPData
    )

    New-HTMLTab -TabName 'All Scopes' {
        New-HTMLSection -HeaderText "Complete Scope Inventory" {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "All DHCP Scopes" -FontSize 18px -FontWeight bold
                New-HTMLText -Text "This view shows all scopes including both properly configured and problematic ones." -FontSize 12px

                # Summary counts
                $GoodScopes = $DHCPData.Scopes | Where-Object { -not $_.HasIssues }
                $BadScopes = $DHCPData.Scopes | Where-Object { $_.HasIssues }

                New-HTMLList {
                    New-HTMLListItem -Text "Total Scopes: ", "$($DHCPData.Scopes.Count)" -FontWeight bold, normal -Color Black, Blue
                    New-HTMLListItem -Text "Properly Configured: ", "$($GoodScopes.Count)" -FontWeight bold, normal -Color Black, Green
                    New-HTMLListItem -Text "With Issues: ", "$($BadScopes.Count)" -FontWeight bold, normal -Color Black, Red
                } -FontSize 12px
            }
        }

        # Good Scopes Section
        if ($GoodScopes.Count -gt 0) {
            New-HTMLSection -HeaderText "✅ Properly Configured Scopes ($($GoodScopes.Count))" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLTable -DataTable $GoodScopes {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Inactive' -BackgroundColor LightGray
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Yellow -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator le -Value 48 -BackgroundColor LightGreen -HighlightHeaders 'LeaseDurationHours'
                    } -ScrollX -IncludeProperty @(
                        'ServerName', 'ScopeId', 'Name', 'State', 'LeaseDurationHours',
                        'DNSServers', 'DomainNameOption', 'DynamicUpdates',
                        'UpdateDnsRRForOlderClients', 'DeleteDnsRROnLeaseExpiry',
                        'FailoverPartner', 'HasFailover', 'FailoverConfiguration'
                    )
                }
            }
        }

        # Bad Scopes Section
        if ($BadScopes.Count -gt 0) {
            New-HTMLSection -HeaderText "⚠️ Scopes with Issues ($($BadScopes.Count))" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLTable -DataTable $BadScopes {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Inactive' -BackgroundColor LightGray
                        New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'Issues'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Red -Color White -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                        New-HTMLTableCondition -Name 'DNSServers' -ComparisonType string -Operator contains -Value '8.8' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'DNSServers' -ComparisonType string -Operator contains -Value '1.1' -BackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'UpdateDnsRRForOlderClients' -ComparisonType bool -Operator eq -Value $false -BackgroundColor Yellow
                        New-HTMLTableCondition -Name 'DeleteDnsRROnLeaseExpiry' -ComparisonType bool -Operator eq -Value $false -BackgroundColor Yellow
                    } -ScrollX -IncludeProperty @(
                        'ServerName', 'ScopeId', 'Name', 'State', 'LeaseDurationHours',
                        'DNSServers', 'DomainNameOption', 'DynamicUpdates',
                        'UpdateDnsRRForOlderClients', 'DeleteDnsRROnLeaseExpiry',
                        'FailoverPartner', 'HasFailover', 'FailoverConfiguration', 'Issues'
                    )
                }
            }
        }

        # Complete raw data (collapsed by default)
        New-HTMLSection -HeaderText '📊 Complete Scope Data' -CanCollapse {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text 'Raw scope data for detailed analysis' -FontSize 12px
                New-HTMLTable -DataTable $DHCPData.Scopes {
                    New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon
                    New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $false -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightBlue -HighlightHeaders 'State'
                } -ScrollX -Filtering -PagingLength 25 -ExcludeProperty 'AddressesInUse', 'AddressesFree', 'PercentageInUse', 'Reserved', 'HasUtilizationIssues', 'UtilizationIssues', 'TotalAddresses', 'DefinedRange', 'UtilizationEfficiency', 'DNSSettings'
            }
        }
    }
}
