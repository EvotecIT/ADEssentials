function New-DHCPValidationIssuesTab {
    <#
    .SYNOPSIS
    Creates the Validation Issues tab content for DHCP HTML report.

    .DESCRIPTION
    This private function generates the Validation Issues tab which includes scopes with issues,
    high utilization scopes, critical utilization, scopes without failover, and inactive scopes.

    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.

    .OUTPUTS
    New-HTMLTab object containing the Validation Issues tab content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData
    )

    New-HTMLTab -TabName 'Validation Issues' {
        # If no validation issues found - calculate total issues
        $TotalIssuesCount = $DHCPData.Statistics.ServersWithIssues + $DHCPData.Statistics.ScopesWithIssues + $DHCPData.Statistics.ServersOffline
        if ($TotalIssuesCount -eq 0) {
            New-HTMLSection -HeaderText "Validation Status" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "✅ No validation issues found" -Color Green -FontSize 16pt -FontWeight bold
                    New-HTMLText -Text "All DHCP servers and scopes appear to be properly configured and operating within normal parameters." -FontSize 12pt
                }
            }
        }

        if ($DHCPData.ScopesWithIssues.Count -gt 0) {
            New-HTMLSection -HeaderText "Scopes with Configuration Issues" {
                New-HTMLTable -DataTable $DHCPData.ScopesWithIssues -Filtering {
                    New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                    New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'HasIssues', 'Issues'
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                } -DataStore JavaScript -ScrollX
            }
        }

        # High utilization scopes section
        $HighUtilizationScopes = $DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 75 -and $_.State -eq 'Active' }
        if ($HighUtilizationScopes.Count -gt 0) {
            New-HTMLSection -HeaderText "High Utilization Scopes (>75%)" {
                New-HTMLTable -DataTable $HighUtilizationScopes -Filtering {
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                } -DataStore JavaScript
            }
        }

        # Large lease duration scopes
        $LongLeaseScopes = $DHCPData.Scopes | Where-Object { $_.LeaseDurationHours -gt 48 }
        if ($LongLeaseScopes.Count -gt 0) {
            New-HTMLSection -HeaderText "Scopes with Extended Lease Duration (>48 hours)" {
                New-HTMLTable -DataTable $LongLeaseScopes -Filtering {
                    New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 168 -BackgroundColor Salmon -HighlightHeaders 'LeaseDurationHours'
                    New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                } -DataStore JavaScript
            }
        }

        # Critical utilization scopes (>90%)
        $CriticalUtilizationScopes = $DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 90 -and $_.State -eq 'Active' }
        if ($CriticalUtilizationScopes.Count -gt 0) {
            New-HTMLSection -HeaderText "Critical Utilization Scopes (>90%)" {
                New-HTMLTable -DataTable $CriticalUtilizationScopes -Filtering {
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 95 -BackgroundColor Red -HighlightHeaders 'PercentageInUse'
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                } -DataStore JavaScript
            }
        }

        # Scopes without failover partners
        $ScopesWithoutFailover = $DHCPData.Scopes | Where-Object { $_.State -eq 'Active' -and ([string]::IsNullOrEmpty($_.FailoverPartner) -or $_.FailoverPartner -eq '') }
        if ($ScopesWithoutFailover.Count -gt 0) {
            New-HTMLSection -HeaderText "Active Scopes without Failover Configuration" {
                New-HTMLTable -DataTable $ScopesWithoutFailover -Filtering {
                    New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen
                    New-HTMLTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackgroundColor LightYellow -HighlightHeaders 'FailoverPartner'
                    New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                } -DataStore JavaScript -ScrollX
            }
        }

        # Inactive scopes
        $InactiveScopes = $DHCPData.Scopes | Where-Object { $_.State -ne 'Active' }
        if ($InactiveScopes.Count -gt 0) {
            New-HTMLSection -HeaderText "Inactive DHCP Scopes" {
                New-HTMLTable -DataTable $InactiveScopes -Filtering {
                    New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator ne -Value 'Active' -BackgroundColor LightYellow -HighlightHeaders 'State'
                } -DataStore JavaScript -ScrollX
            }
        }
    }
}