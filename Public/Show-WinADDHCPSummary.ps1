function Show-WinADDHCPSummary {
    <#
    .SYNOPSIS
    Generates an HTML report displaying comprehensive DHCP server information from Active Directory forest.

    .DESCRIPTION
    This function creates a detailed HTML report showing DHCP server configurations, scope information,
    and validation results. The report includes server statistics, scope details, configuration issues,
    and interactive charts for visual analysis of DHCP infrastructure health.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve DHCP information from. If not specified, uses current forest.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from DHCP information retrieval.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from DHCP information retrieval.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include in DHCP information retrieval.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in DHCP information retrieval.

    .PARAMETER ComputerName
    Specifies specific DHCP servers to query. If not provided, discovers all DHCP servers in the forest.

    .PARAMETER SkipRODC
    Indicates whether to skip Read-Only Domain Controllers (RODC) when retrieving DHCP information.

    .PARAMETER ExtendedForestInformation
    Specifies additional extended forest information to include in the output.

    .PARAMETER FilePath
    Specifies the file path where the HTML report will be saved. If not provided, uses a temporary file.

    .PARAMETER Online
    Forces use of online CDN for JavaScript/CSS which makes the file smaller. Default uses offline resources.

    .PARAMETER HideHTML
    Prevents the HTML report from being displayed in browser after generation.

    .PARAMETER PassThru
    Returns the DHCP summary data object along with generating the HTML report.

    .EXAMPLE
    Show-WinADDHCPSummary

    Generates an HTML report for all DHCP servers in the current forest and displays it in the default browser.

    .EXAMPLE
    Show-WinADDHCPSummary -FilePath "C:\Reports\DHCP_Report.html" -HideHTML

    Generates an HTML report and saves it to the specified path without opening in browser.

    .EXAMPLE
    Show-WinADDHCPSummary -Forest "example.com" -IncludeDomains "domain1.com" -Online

    Generates an HTML report for specific domains using online resources for smaller file size.

    .EXAMPLE
    Show-WinADDHCPSummary -ComputerName "dhcp01.example.com", "dhcp02.example.com" -PassThru

    Generates a report for specific DHCP servers and returns the data object.

    .NOTES
    This function requires the DHCP PowerShell module and PSWriteHTML module for report generation.
    The generated report includes:
    - DHCP server summary statistics
    - Server status and health information
    - Scope configuration details
    - Configuration validation results
    - Interactive charts and visual analytics
    - Detailed scope tables with filtering capabilities

    .OUTPUTS
    When PassThru is specified, returns the DHCP summary hashtable containing servers, scopes, and statistics.

    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [string[]] $ComputerName,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [string] $FilePath,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $PassThru
    )

    # Initialize reporting version info
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Show-WinADDHCPSummary' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    # Set default file path if not provided
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }

    Write-Verbose "Show-WinADDHCPSummary - Starting DHCP report generation"

    # Gather DHCP data
    $GetWinADDHCPSummarySplat = @{
        Extended = $true
    }

    if ($Forest) { $GetWinADDHCPSummarySplat.Forest = $Forest }
    if ($ExcludeDomains) { $GetWinADDHCPSummarySplat.ExcludeDomains = $ExcludeDomains }
    if ($ExcludeDomainControllers) { $GetWinADDHCPSummarySplat.ExcludeDomainControllers = $ExcludeDomainControllers }
    if ($IncludeDomains) { $GetWinADDHCPSummarySplat.IncludeDomains = $IncludeDomains }
    if ($IncludeDomainControllers) { $GetWinADDHCPSummarySplat.IncludeDomainControllers = $IncludeDomainControllers }
    if ($ComputerName) { $GetWinADDHCPSummarySplat.ComputerName = $ComputerName }
    if ($SkipRODC) { $GetWinADDHCPSummarySplat.SkipRODC = $SkipRODC }
    if ($ExtendedForestInformation) { $GetWinADDHCPSummarySplat.ExtendedForestInformation = $ExtendedForestInformation }

    $DHCPData = Get-WinADDHCPSummary @GetWinADDHCPSummarySplat

    if (-not $DHCPData) {
        Write-Warning "Show-WinADDHCPSummary - No DHCP data available to generate report"
        return
    }

    # Handle case where no DHCP servers are found
    if ($DHCPData.Statistics.TotalServers -eq 0) {
        Write-Warning "Show-WinADDHCPSummary - No DHCP servers found in the environment"

        # Create a simple report for no servers scenario
        New-HTML {
            New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
            New-HTMLHeader {
                New-HTMLSection -Invisible {
                    New-HTMLSection {
                        New-HTMLText -Text "Report generated on $(Get-Date)" -Color Blue
                    } -JustifyContent flex-start -Invisible
                    New-HTMLSection {
                        New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                    } -JustifyContent flex-end -Invisible
                }
            }

            New-HTMLSection -HeaderText "DHCP Summary" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "No DHCP Infrastructure Found" -Color Red -FontSize 16pt -FontWeight bold
                    New-HTMLText -Text "No DHCP servers were discovered in the Active Directory environment." -FontSize 12pt
                    New-HTMLText -Text "Recommendations:" -Color Blue -FontSize 12pt -FontWeight bold
                    New-HTMLList {
                        New-HTMLListItem -Text "Install and configure DHCP server roles"
                        New-HTMLListItem -Text "Register DHCP servers in Active Directory"
                        New-HTMLListItem -Text "Verify network connectivity to potential DHCP servers"
                    }
                }
            }
        } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)

        if ($PassThru) {
            return $DHCPData
        }
        return
    }

    Write-Verbose "Show-WinADDHCPSummary - Generating HTML report"

    # Generate HTML report
    New-HTML {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString "," -BoolAsString
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        New-HTMLHeader {
            New-HTMLSection -Invisible {
                New-HTMLSection {
                    New-HTMLText -Text "Report generated on $(Get-Date)" -Color Blue
                } -JustifyContent flex-start -Invisible
                New-HTMLSection {
                    New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                } -JustifyContent flex-end -Invisible
            }
        }

        New-HTMLTabPanel {
            New-HTMLTab -TabName 'Overview' {
                New-HTMLSection -HeaderText "DHCP Infrastructure Overview" {
                    New-HTMLPanel {
                        New-HTMLText -Text "About this Report" -FontSize 16px -FontWeight bold
                        New-HTMLText -Text "This report provides a comprehensive overview of DHCP infrastructure across your Active Directory forest. DHCP (Dynamic Host Configuration Protocol) is critical for automatic IP address assignment and network configuration. Monitoring DHCP health ensures reliable network connectivity for all clients." -FontSize 12px

                        New-HTMLText -Text "What to Look For" -FontSize 16px -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Server Health: ", "Ensure all DHCP servers are online and operational" -FontWeight bold, normal
                            New-HTMLListItem -Text "Scope Utilization: ", "Monitor IP address pool usage to prevent exhaustion" -FontWeight bold, normal
                            New-HTMLListItem -Text "Configuration Issues: ", "Address DNS settings, lease durations, and failover configuration" -FontWeight bold, normal
                            New-HTMLListItem -Text "High Utilization: ", "Identify scopes approaching capacity limits" -FontWeight bold, normal
                        } -FontSize 12px

                        New-HTMLText -Text "Report Sections" -FontSize 16px -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Overview: ", "Health summary, statistics, and key metrics at a glance" -FontWeight bold, normal
                            New-HTMLListItem -Text "Infrastructure: ", "Detailed server and scope information" -FontWeight bold, normal
                            New-HTMLListItem -Text "Validation Issues: ", "All configuration problems and capacity concerns" -FontWeight bold, normal
                            New-HTMLListItem -Text "Configuration: ", "Audit logs and database settings" -FontWeight bold, normal
                        } -FontSize 12px
                    }
                    New-HTMLPanel {
                        New-HTMLText -Text "Environment Summary" -FontSize 16px -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Total DHCP Servers: ", $TotalServers -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                            New-HTMLListItem -Text "Total DHCP Scopes: ", $TotalScopes -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                            New-HTMLListItem -Text "Total IP Addresses: ", $TotalAddresses.ToString("N0") -Color Black, Blue -FontWeight normal, bold -FontSize 12px
                            New-HTMLListItem -Text "Overall Utilization: ", "$OverallPercentageInUse%" -Color Black, $(if ($OverallPercentageInUse -gt 80) { 'Red' } elseif ($OverallPercentageInUse -gt 60) { 'Orange' } else { 'Green' }) -FontWeight normal, bold -FontSize 12px
                        }

                        # Create environment health chart
                        if ($TotalServers -gt 0) {
                            New-HTMLChart {
                                New-ChartPie -Name 'Servers Online' -Value $ServersOnline -Color LightGreen
                                if ($ServersOffline -gt 0) {
                                    New-ChartPie -Name 'Servers Offline' -Value $ServersOffline -Color Salmon
                                }
                                if ($ServersWithIssues -gt 0) {
                                    New-ChartPie -Name 'Servers with Issues' -Value $ServersWithIssues -Color Orange
                                }
                            } -Title "DHCP Server Health Distribution"
                        }
                    }
                }

                # Safe access to statistics with null protection
                $TotalServers = if ($DHCPData.Statistics.TotalServers) { $DHCPData.Statistics.TotalServers } else { 0 }
                $ServersOnline = if ($DHCPData.Statistics.ServersOnline) { $DHCPData.Statistics.ServersOnline } else { 0 }
                $ServersOffline = if ($DHCPData.Statistics.ServersOffline) { $DHCPData.Statistics.ServersOffline } else { 0 }
                $ServersWithIssues = if ($DHCPData.Statistics.ServersWithIssues) { $DHCPData.Statistics.ServersWithIssues } else { 0 }
                $TotalScopes = if ($DHCPData.Statistics.TotalScopes) { $DHCPData.Statistics.TotalScopes } else { 0 }
                $ScopesActive = if ($DHCPData.Statistics.ScopesActive) { $DHCPData.Statistics.ScopesActive } else { 0 }
                $ScopesInactive = if ($DHCPData.Statistics.ScopesInactive) { $DHCPData.Statistics.ScopesInactive } else { 0 }
                $ScopesWithIssues = if ($DHCPData.Statistics.ScopesWithIssues) { $DHCPData.Statistics.ScopesWithIssues } else { 0 }
                $TotalAddresses = if ($DHCPData.Statistics.TotalAddresses) { $DHCPData.Statistics.TotalAddresses } else { 0 }
                $AddressesInUse = if ($DHCPData.Statistics.AddressesInUse) { $DHCPData.Statistics.AddressesInUse } else { 0 }
                $AddressesFree = if ($DHCPData.Statistics.AddressesFree) { $DHCPData.Statistics.AddressesFree } else { 0 }
                $OverallPercentageInUse = if ($DHCPData.Statistics.OverallPercentageInUse) { $DHCPData.Statistics.OverallPercentageInUse } else { 0 }

                New-HTMLSection -HeaderText "DHCP Infrastructure Statistics" {
                    New-HTMLPanel {
                        # DHCP Infrastructure Overview using Info Cards
                        New-HTMLSection -HeaderText "Infrastructure Overview" -Invisible {
                            New-HTMLSection -Invisible -Density Comfortable {
                                # Server Status Cards
                                New-HTMLInfoCard -Title "Total Servers" -Number $TotalServers -Subtitle "DHCP Infrastructure" -Icon "🖥️" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'

                                New-HTMLInfoCard -Title "Online Servers" -Number $ServersOnline -Subtitle "Operational" -Icon "✅" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'

                                if ($ServersOffline -gt 0) {
                                    New-HTMLInfoCard -Title "Offline Servers" -Number $ServersOffline -Subtitle "Need Attention" -Icon "❌" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                                } else {
                                    New-HTMLInfoCard -Title "Offline Servers" -Number $ServersOffline -Subtitle "All Online" -Icon "🎯" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }

                                if ($ServersWithIssues -gt 0) {
                                    New-HTMLInfoCard -Title "Servers with Issues" -Number $ServersWithIssues -Subtitle "Configuration Issues" -Icon "⚠️" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.2)'
                                } else {
                                    New-HTMLInfoCard -Title "Servers with Issues" -Number $ServersWithIssues -Subtitle "All Clean" -Icon "✨" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }
                            }
                        }

                        New-HTMLSection -HeaderText "Scope Statistics" -Invisible {
                            New-HTMLSection -Invisible -Density Comfortable {
                                # Scope Status Cards
                                New-HTMLInfoCard -Title "Total Scopes" -Number $TotalScopes -Subtitle "All Configured Scopes" -Icon "📋" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'

                                New-HTMLInfoCard -Title "Active Scopes" -Number $ScopesActive -Subtitle "Currently Serving" -Icon "🟢" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'

                                if ($ScopesInactive -gt 0) {
                                    New-HTMLInfoCard -Title "Inactive Scopes" -Number $ScopesInactive -Subtitle "Disabled" -Icon "🔴" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.15)'
                                } else {
                                    New-HTMLInfoCard -Title "Inactive Scopes" -Number $ScopesInactive -Subtitle "All Active" -Icon "✅" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }

                                if ($ScopesWithIssues -gt 0) {
                                    New-HTMLInfoCard -Title "Scopes with Issues" -Number $ScopesWithIssues -Subtitle "Need Review" -Icon "🔧" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.2)' -ShadowIntensity Bold
                                } else {
                                    New-HTMLInfoCard -Title "Scopes with Issues" -Number $ScopesWithIssues -Subtitle "All Configured" -Icon "💯" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }
                            }
                        }

                        New-HTMLSection -HeaderText "Address Pool Utilization" -Invisible {
                            New-HTMLSection -Invisible -Density Comfortable {
                                # Address Pool Cards
                                New-HTMLInfoCard -Title "Total IP Addresses" -Number $TotalAddresses.ToString("N0") -Subtitle "Pool Capacity" -Icon "🏊‍♂️" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'

                                if ($OverallPercentageInUse -gt 80) {
                                    New-HTMLInfoCard -Title "Addresses In Use" -Number $AddressesInUse.ToString("N0") -Subtitle "High Utilization" -Icon "🚨" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.25)' -ShadowIntensity ExtraBold
                                } elseif ($OverallPercentageInUse -gt 60) {
                                    New-HTMLInfoCard -Title "Addresses In Use" -Number $AddressesInUse.ToString("N0") -Subtitle "Moderate Usage" -Icon "⚠️" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.2)'
                                } else {
                                    New-HTMLInfoCard -Title "Addresses In Use" -Number $AddressesInUse.ToString("N0") -Subtitle "Healthy Usage" -Icon "📊" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }

                                New-HTMLInfoCard -Title "Addresses Available" -Number $AddressesFree.ToString("N0") -Subtitle "Ready for Assignment" -Icon "🆓" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'

                                if ($OverallPercentageInUse -gt 90) {
                                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "Critical Level" -Icon "🔥" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.3)' -ShadowIntensity ExtraBold -ShadowDirection 'All'
                                } elseif ($OverallPercentageInUse -gt 75) {
                                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "High Usage" -Icon "📈" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.25)' -ShadowIntensity Bold
                                } elseif ($OverallPercentageInUse -gt 50) {
                                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "Moderate Usage" -Icon "📊" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                                } else {
                                    New-HTMLInfoCard -Title "Overall Utilization" -Number "$OverallPercentageInUse%" -Subtitle "Low Usage" -Icon "🌱" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }
                            }
                        }
                    }

                    New-HTMLPanel {
                        New-HTMLChart {
                            New-ChartPie -Name 'Servers Online' -Value $DHCPData.Statistics.ServersOnline -Color LightGreen
                            New-ChartPie -Name 'Servers Offline' -Value $DHCPData.Statistics.ServersOffline -Color Salmon
                            New-ChartPie -Name 'Servers with Issues' -Value $DHCPData.Statistics.ServersWithIssues -Color Orange
                        } -Title 'DHCP Server Status' -TitleColor DodgerBlue
                    }

                    New-HTMLPanel {
                        New-HTMLChart {
                            New-ChartPie -Name 'Addresses In Use' -Value $DHCPData.Statistics.AddressesInUse -Color Orange
                            New-ChartPie -Name 'Addresses Available' -Value $DHCPData.Statistics.AddressesFree -Color LightGreen
                        } -Title 'Address Pool Utilization' -TitleColor DodgerBlue
                    }
                }

                # Calculate validation summary statistics
                $ScopesWithIssuesCount = ($DHCPData.ScopesWithIssues | Measure-Object).Count
                $HighUtilizationScopesCount = ($DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 75 -and $_.State -eq 'Active' } | Measure-Object).Count
                $LongLeaseScopesCount = ($DHCPData.Scopes | Where-Object { $_.LeaseDurationHours -gt 48 } | Measure-Object).Count
                $OfflineServersCount = ($DHCPData.Servers | Where-Object { $_.Status -ne 'Online' } | Measure-Object).Count
                $CriticalIssuesCount = $OfflineServersCount + ($DHCPData.Scopes | Where-Object { $_.PercentageInUse -gt 90 -and $_.State -eq 'Active' } | Measure-Object).Count
                $WarningIssuesCount = $HighUtilizationScopesCount + $LongLeaseScopesCount + $ScopesWithIssuesCount
                $TotalIssuesCount = $CriticalIssuesCount + $WarningIssuesCount

                # Validation Summary with Info Cards
                New-HTMLSection -HeaderText "Health & Validation Summary" -Invisible {
                    New-HTMLPanel {
                        New-HTMLSection -HeaderText "Issue Summary" -Invisible {
                            New-HTMLSection -Invisible -Density Comfortable {
                                if ($TotalIssuesCount -eq 0) {
                                    New-HTMLInfoCard -Title "Health Status" -Number "HEALTHY" -Subtitle "No Issues Found" -Icon "✅" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.2)' -ShadowIntensity Bold
                                } else {
                                    New-HTMLInfoCard -Title "Total Issues" -Number $TotalIssuesCount -Subtitle "Need Attention" -Icon "🔍" -TitleColor 'DodgerBlue' -NumberColor 'Navy' -ShadowColor 'rgba(30, 144, 255, 0.15)'
                                }

                                if ($CriticalIssuesCount -gt 0) {
                                    New-HTMLInfoCard -Title "Critical Issues" -Number $CriticalIssuesCount -Subtitle "Immediate Action Required" -Icon "🚨" -TitleColor 'Crimson' -NumberColor 'DarkRed' -ShadowColor 'rgba(220, 20, 60, 0.3)' -ShadowIntensity ExtraBold -ShadowDirection 'All'
                                } else {
                                    New-HTMLInfoCard -Title "Critical Issues" -Number $CriticalIssuesCount -Subtitle "None Found" -Icon "🛡️" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }

                                if ($WarningIssuesCount -gt 0) {
                                    New-HTMLInfoCard -Title "Warning Issues" -Number $WarningIssuesCount -Subtitle "Should Be Reviewed" -Icon "⚠️" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.2)' -ShadowIntensity Bold
                                } else {
                                    New-HTMLInfoCard -Title "Warning Issues" -Number $WarningIssuesCount -Subtitle "None Found" -Icon "🌟" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }

                                if ($ScopesWithIssuesCount -gt 0) {
                                    New-HTMLInfoCard -Title "Config Issues" -Number $ScopesWithIssuesCount -Subtitle "Scope Configuration" -Icon "🔧" -TitleColor 'Orange' -NumberColor 'DarkOrange' -ShadowColor 'rgba(255, 165, 0, 0.15)'
                                } else {
                                    New-HTMLInfoCard -Title "Config Issues" -Number $ScopesWithIssuesCount -Subtitle "All Configured" -Icon "⚙️" -TitleColor 'LimeGreen' -NumberColor 'DarkGreen' -ShadowColor 'rgba(50, 205, 50, 0.15)'
                                }
                            }
                        }
                    }

                    New-HTMLPanel {
                        New-HTMLChart {
                            if ($TotalIssuesCount -gt 0) {
                                if ($CriticalIssuesCount -gt 0) {
                                    New-ChartPie -Name 'Critical Issues' -Value $CriticalIssuesCount -Color Crimson
                                }
                                if ($WarningIssuesCount -gt 0) {
                                    New-ChartPie -Name 'Warning Issues' -Value $WarningIssuesCount -Color Orange
                                }
                                $HealthyItems = [Math]::Max(0, $TotalServers + $TotalScopes - $TotalIssuesCount)
                                if ($HealthyItems -gt 0) {
                                    New-ChartPie -Name 'Healthy Items' -Value $HealthyItems -Color LimeGreen
                                }
                            } else {
                                New-ChartPie -Name 'All Healthy' -Value ($TotalServers + $TotalScopes) -Color LimeGreen
                            }
                        } -Title 'Health Overview' -TitleColor DodgerBlue
                    }
                }

                # Recommendations section
                if ($TotalIssuesCount -gt 0) {
                    New-HTMLSection -HeaderText "Recommended Actions" -CanCollapse {
                        New-HTMLPanel {
                            New-HTMLList {
                                if ($OfflineServersCount -gt 0) {
                                    New-HTMLListItem -Text "Check network connectivity and service status for offline DHCP servers"
                                }
                                if ($HighUtilizationScopesCount -gt 0) {
                                    New-HTMLListItem -Text "Monitor high utilization scopes and consider expanding IP address ranges"
                                }
                                if ($ScopesWithIssuesCount -gt 0) {
                                    New-HTMLListItem -Text "Review scope configuration issues, particularly DNS settings and failover configuration"
                                }
                                if ($LongLeaseScopesCount -gt 0) {
                                    New-HTMLListItem -Text "Consider reducing lease durations for scopes with extended lease times (>48 hours)"
                                }
                                New-HTMLListItem -Text "Review the Validation Issues tab for detailed analysis of specific problems"
                                New-HTMLListItem -Text "Check the Configuration tab for audit log and database settings"
                            } -FontSize 12px
                        } -Invisible
                    }
                } else {
                    New-HTMLSection -HeaderText "Environment Status" -CanCollapse {
                        New-HTMLPanel {
                            New-HTMLText -Text "✅ No DHCP issues detected in this environment." -Color Green -FontWeight bold -FontSize 14px
                            New-HTMLText -Text "Your DHCP infrastructure appears to be healthy and well-configured." -FontSize 12px
                        } -Invisible
                    }
                }
            }

            New-HTMLTab -TabName 'Infrastructure' {
                New-HTMLSection -HeaderText "DHCP Servers" {
                    New-HTMLTable -DataTable $DHCPData.Servers -Filtering {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Orange -HighlightHeaders 'ScopesWithIssues'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'IsADDomainController' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightBlue -HighlightHeaders 'IsADDomainController'
                    } -DataStore JavaScript
                }

                New-HTMLSection -HeaderText "DHCP Scopes" {
                    New-HTMLTable -DataTable $DHCPData.Scopes -Filtering {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'HasIssues', 'Issues'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                        New-HTMLTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackgroundColor LightYellow -HighlightHeaders 'FailoverPartner'
                    } -DataStore JavaScript -ScrollX
                } }

            New-HTMLTab -TabName 'Validation Issues' {
                # If no validation issues found
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

            New-HTMLTab -TabName 'Configuration' {
                # Configuration recommendations
                New-HTMLSection -HeaderText "Configuration Recommendations" -CanCollapse {
                    New-HTMLPanel {
                        New-HTMLText -Text "Best Practices for DHCP Configuration:" -FontSize 14px -FontWeight bold
                        New-HTMLList {
                            New-HTMLListItem -Text "Enable DHCP audit logging on all servers for troubleshooting and compliance"
                            New-HTMLListItem -Text "Configure appropriate lease durations (typically 8-24 hours for most environments)"
                            New-HTMLListItem -Text "Implement DHCP failover for high availability in critical environments"
                            New-HTMLListItem -Text "Monitor scope utilization to prevent IP address exhaustion"
                            New-HTMLListItem -Text "Use consistent DNS server assignments across all scopes"
                            New-HTMLListItem -Text "Regularly backup DHCP database configuration"
                            New-HTMLListItem -Text "Document IP address assignments and reservations"
                            New-HTMLListItem -Text "Review and update scope options as network requirements change"
                        } -FontSize 12px
                    } -Invisible
                }

                if ($DHCPData.AuditLogs.Count -gt 0) {
                    New-HTMLSection -HeaderText "DHCP Audit Log Configuration" {
                        New-HTMLTable -DataTable $DHCPData.AuditLogs -Filtering {
                            New-HTMLTableCondition -Name 'Enable' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'MaxMBFileSize' -ComparisonType number -Operator lt -Value 10 -BackgroundColor Orange -HighlightHeaders 'MaxMBFileSize'
                        } -DataStore JavaScript
                    }
                }

                if ($DHCPData.Databases.Count -gt 0) {
                    New-HTMLSection -HeaderText "DHCP Database Configuration" {
                        New-HTMLTable -DataTable $DHCPData.Databases -Filtering {
                            New-HTMLTableCondition -Name 'LoggingEnabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'BackupIntervalMinutes' -ComparisonType number -Operator gt -Value 1440 -BackgroundColor Orange -HighlightHeaders 'BackupIntervalMinutes'
                            New-HTMLTableCondition -Name 'CleanupIntervalMinutes' -ComparisonType number -Operator gt -Value 10080 -BackgroundColor Orange -HighlightHeaders 'CleanupIntervalMinutes'
                        } -DataStore JavaScript
                    }
                }

                # Server-level configuration summary
                if ($DHCPData.Servers.Count -gt 0) {
                    New-HTMLSection -HeaderText "Server Configuration Summary" {
                        $ServerConfigSummary = $DHCPData.Servers | Select-Object ComputerName, DomainName, IsADDomainController, IPAddress, Status, TotalScopes, ScopesActive, ScopesInactive, ScopesWithIssues | Sort-Object ComputerName
                        New-HTMLTable -DataTable $ServerConfigSummary -Filtering {
                            New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                            New-HTMLTableCondition -Name 'IsADDomainController' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightBlue -HighlightHeaders 'IsADDomainController'
                            New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Orange -HighlightHeaders 'ScopesWithIssues'
                        } -DataStore JavaScript -ScrollX
                    }
                }

                # If no configuration data available
                if ($DHCPData.AuditLogs.Count -eq 0 -and $DHCPData.Databases.Count -eq 0) {
                    New-HTMLSection -HeaderText "Configuration Status" {
                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "⚠️ No detailed configuration data available" -Color Orange -FontSize 14pt -FontWeight bold
                            New-HTMLText -Text "This may indicate limited access to DHCP server configuration or that detailed configuration collection was not performed." -FontSize 12pt
                        }
                    }
                }
            }
        }

    } -ShowHTML:(-not $HideHTML.IsPresent) -Online:$Online.IsPresent -TitleText "DHCP Infrastructure Report" -FilePath $FilePath

    Write-Verbose "Show-WinADDHCPSummary - HTML report generated: $FilePath"

    if ($PassThru) {
        return $DHCPData
    }
}
