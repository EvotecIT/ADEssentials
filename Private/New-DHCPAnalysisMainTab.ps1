function New-DHCPAnalysisMainTab {
    <#
    .SYNOPSIS
    Creates the main Analysis tab with nested subtabs for better organization.
    
    .DESCRIPTION
    This private function generates a main Analysis tab that contains nested tabs
    for Utilization, Performance, Security & Compliance, and other analysis-related items.
    
    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.
    
    .PARAMETER IncludeTabs
    Array of tab names to include in the report.
    
    .PARAMETER ShowTimingStatistics
    Whether to show timing statistics tab.
    
    .OUTPUTS
    New-HTMLTab object containing the Analysis tab with nested content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData,
        
        [Parameter(Mandatory = $false)]
        [string[]] $IncludeTabs,
        
        [Parameter(Mandatory = $false)]
        [switch] $ShowTimingStatistics
    )

    New-HTMLTab -TabName '📊 Analysis' {
        New-HTMLTabPanel {
            # Utilization tab
            if (-not $IncludeTabs -or 'Utilization' -in $IncludeTabs) {
                New-DHCPUtilizationTab -DHCPData $DHCPData
            }
            
            # Performance tab
            if (-not $IncludeTabs -or 'Performance' -in $IncludeTabs) {
                New-DHCPPerformanceTab -DHCPData $DHCPData
            }
            
            # Security & Compliance tab
            if (-not $IncludeTabs -or 'SecurityCompliance' -in $IncludeTabs) {
                New-DHCPSecurityComplianceTab -DHCPData $DHCPData
            }
            
            # Scale Analysis tab (only for large environments)
            if ((-not $IncludeTabs -or 'ScaleAnalysis' -in $IncludeTabs) -and $DHCPData.Statistics.TotalAddresses -gt 500000) {
                New-DHCPScaleAnalysisTab -DHCPData $DHCPData
            }
            
            # Timing Statistics tab (if requested)
            if ($ShowTimingStatistics -and $DHCPData.TimingStatistics.Count -gt 0) {
                New-HTMLTab -TabName '⏱️ Timing Statistics' {
                    New-HTMLSection -HeaderText "Data Collection Performance" {
                        New-HTMLPanel -Invisible {
                            # Summary statistics
                            $TotalTime = ($DHCPData.TimingStatistics | Measure-Object -Property DurationMs -Sum).Sum
                            $ServerCount = ($DHCPData.TimingStatistics | Select-Object -ExpandProperty ServerName -Unique).Count
                            $OperationCount = $DHCPData.TimingStatistics.Count
                            
                            New-HTMLText -Text "Data Collection Summary" -FontSize 16pt -FontWeight bold -Color DarkBlue
                            New-HTMLSection -HeaderText "Performance Overview" -Invisible -Density Compact {
                                New-HTMLInfoCard -Title "Total Time" -Number "$([Math]::Round($TotalTime/1000, 2))s" -Subtitle "Complete Collection" -Icon "⏱️" -TitleColor Blue -NumberColor DarkBlue
                                New-HTMLInfoCard -Title "Servers Processed" -Number $ServerCount -Subtitle "DHCP Servers" -Icon "🖥️" -TitleColor Green -NumberColor DarkGreen
                                New-HTMLInfoCard -Title "Operations" -Number $OperationCount -Subtitle "Total Operations" -Icon "🔄" -TitleColor Orange -NumberColor DarkOrange
                                New-HTMLInfoCard -Title "Avg per Server" -Number "$([Math]::Round($TotalTime/$ServerCount/1000, 2))s" -Subtitle "Processing Time" -Icon "📊" -TitleColor Purple -NumberColor DarkMagenta
                            }
                        }
                        
                        # Detailed timing table
                        New-HTMLTable -DataTable $DHCPData.TimingStatistics -Filtering {
                            New-HTMLTableCondition -Name 'Success' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Salmon
                            New-HTMLTableCondition -Name 'DurationMs' -ComparisonType number -Operator gt -Value 5000 -BackgroundColor Orange -HighlightHeaders 'DurationMs', 'DurationSeconds'
                            New-HTMLTableCondition -Name 'DurationMs' -ComparisonType number -Operator gt -Value 10000 -BackgroundColor Red -Color White -HighlightHeaders 'DurationMs', 'DurationSeconds'
                        } -DataStore JavaScript -ScrollX -Title "Detailed Operation Timing"
                        
                        # Performance by operation type
                        $OperationGroups = $DHCPData.TimingStatistics | Group-Object Operation | ForEach-Object {
                            [PSCustomObject]@{
                                Operation = $_.Name
                                Count = $_.Count
                                TotalMs = [Math]::Round(($_.Group | Measure-Object -Property DurationMs -Sum).Sum, 2)
                                AvgMs = [Math]::Round(($_.Group | Measure-Object -Property DurationMs -Average).Average, 2)
                                MinMs = [Math]::Round(($_.Group | Measure-Object -Property DurationMs -Minimum).Minimum, 2)
                                MaxMs = [Math]::Round(($_.Group | Measure-Object -Property DurationMs -Maximum).Maximum, 2)
                            }
                        }
                        
                        New-HTMLSection -HeaderText "Performance by Operation Type" {
                            New-HTMLTable -DataTable $OperationGroups -HideFooter {
                                New-HTMLTableCondition -Name 'AvgMs' -ComparisonType number -Operator gt -Value 5000 -BackgroundColor Orange
                                New-HTMLTableCondition -Name 'AvgMs' -ComparisonType number -Operator gt -Value 10000 -BackgroundColor Red -Color White
                            }
                        }
                    }
                }
            }
        }
    }
}