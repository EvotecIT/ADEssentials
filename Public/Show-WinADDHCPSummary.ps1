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

    .PARAMETER TestMode
    Generates the HTML report using sample test data instead of querying real DHCP servers.
    Useful for quickly testing HTML layout and structure without running through all servers.

    .EXAMPLE
    Show-WinADDHCPSummary

    Generates an HTML report for all DHCP servers in the current forest and displays it in the default browser.

    .EXAMPLE
    Show-WinADDHCPSummary -FilePath "C:\Reports\DHCP_Report.html" -HideHTML

    Generates an HTML report and saves it to the specified path without opening in browser.

    .EXAMPLE
    Show-WinADDHCPSummary -TestMode -Online

    Generates a test HTML report using sample data for quick layout testing and validation.

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
        [switch] $PassThru,
        [switch] $TestMode
    )

    # Initialize reporting version info
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Show-WinADDHCPSummary' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    # Set default file path if not provided
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }

    Write-Verbose "Show-WinADDHCPSummary - Starting DHCP report generation"

    # Test Mode: Generate sample data for quick HTML testing
    if ($TestMode) {
        Write-Verbose "Show-WinADDHCPSummary - Running in test mode with sample data"
        $DHCPData = @{
            Servers = @(
                [PSCustomObject]@{ ComputerName = 'dhcp01.domain.com'; Status = 'Online'; Version = '10.0'; PingSuccessful = $true; DNSResolvable = $true; DHCPResponding = $true; TotalScopes = 15; ScopesWithIssues = 2; PercentageInUse = 45; IsADDomainController = $false }
                [PSCustomObject]@{ ComputerName = 'dhcp02.domain.com'; Status = 'Unreachable'; Version = $null; PingSuccessful = $false; DNSResolvable = $true; DHCPResponding = $false; TotalScopes = 0; ScopesWithIssues = 0; PercentageInUse = 0; IsADDomainController = $false }
                [PSCustomObject]@{ ComputerName = 'dc01.domain.com'; Status = 'Online'; Version = '10.0'; PingSuccessful = $true; DNSResolvable = $true; DHCPResponding = $true; TotalScopes = 8; ScopesWithIssues = 1; PercentageInUse = 78; IsADDomainController = $true }
            )
            Scopes = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; AddressesInUse = 170; AddressesFree = 30; HasIssues = $true; Issues = @('High utilization') }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.1.0.0'; Name = 'Guest Network'; State = 'Active'; PercentageInUse = 25; AddressesInUse = 50; AddressesFree = 150; HasIssues = $false; Issues = @() }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; AddressesInUse = 92; AddressesFree = 8; HasIssues = $true; Issues = @('Critical utilization', 'No failover configured') }
            )
            ScopesWithIssues = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; HasIssues = $true; Issues = @('High utilization') }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('Critical utilization', 'No failover configured') }
            )
            IPv6Scopes = @()
            MulticastScopes = @()
            SecurityFilters = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; FilteringMode = 'Deny'; Allow = $false; Deny = $true }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; FilteringMode = 'None'; Allow = $false; Deny = $false }
            )
            Policies = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Name = 'Corporate Devices'; Enabled = $true; ProcessingOrder = 1; Condition = 'Vendor Class matches Corporate' }
            )
            ServerSettings = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; IsAuthorized = $true; IsDomainJoined = $true; ActivatePolicies = $true; ConflictDetectionAttempts = 2 }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; IsAuthorized = $true; IsDomainJoined = $true; ActivatePolicies = $false; ConflictDetectionAttempts = 0 }
            )
            NetworkBindings = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; InterfaceAlias = 'Ethernet'; IPAddress = '192.168.1.10'; State = $true }
            )
            Reservations = @()
            AuditLogs = @()
            Databases = @()
            Statistics = @{
                TotalServers = 3; ServersOnline = 2; ServersOffline = 1; ServersWithIssues = 1
                TotalScopes = 3; ScopesActive = 3; ScopesInactive = 0; ScopesWithIssues = 2
                TotalAddresses = 450; AddressesInUse = 312; AddressesFree = 138; OverallPercentageInUse = 69
            }
        }
    } else {
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
    }

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
                    # Infrastructure Overview using Info Cards - organized in logical rows
                    New-HTMLSection -HeaderText "Server Status Overview" -Invisible {
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

                    New-HTMLSection -HeaderText "Scope Status Overview" -Invisible {
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

                    New-HTMLSection -HeaderText "Address Pool Utilization" -Invisible {
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

                # Charts Section - separate and organized
                New-HTMLSection -HeaderText "Visual Analytics" {
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
                # Enhanced Server Health Status
                New-HTMLSection -HeaderText "Server Health & Connectivity Analysis" {
                    New-HTMLTable -DataTable $DHCPData.Servers -Filtering {
                        New-HTMLTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        New-HTMLTableCondition -Name 'DHCPResponding' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        New-HTMLTableCondition -Name 'PingSuccessful' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'DNSResolvable' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red -Color White
                        New-HTMLTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Orange -HighlightHeaders 'ScopesWithIssues'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'IsADDomainController' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightBlue -HighlightHeaders 'IsADDomainController'
                    } -DataStore JavaScript -Title "DHCP Server Connectivity & Health Analysis" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5') -SearchBuilder
                }

                New-HTMLSection -HeaderText "DHCP Scopes Overview" {
                    New-HTMLTable -DataTable $DHCPData.Scopes -Filtering {
                        New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'HasIssues', 'Issues'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Salmon -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        New-HTMLTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackgroundColor Orange -HighlightHeaders 'LeaseDurationHours'
                        New-HTMLTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackgroundColor LightYellow -HighlightHeaders 'FailoverPartner'
                    } -DataStore JavaScript -ScrollX -Title "All DHCP Scopes Configuration" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5') -SearchBuilder
                }

                # Enhanced Infrastructure sections (when Extended data is available)

                # IPv6 Readiness & Status
                New-HTMLSection -HeaderText "IPv6 DHCP Status" -CanCollapse {
                    if ($DHCPData.IPv6Scopes.Count -gt 0) {
                        # IPv6 scopes are configured and available
                        New-HTMLText -Text "✅ IPv6 DHCP is configured and active in this environment." -Color Green -FontWeight bold
                        New-HTMLTable -DataTable $DHCPData.IPv6Scopes -ScrollX -HideFooter -PagingLength 10 {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -HighlightHeaders 'HasIssues', 'Issues'
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        } -Title "IPv6 DHCP Scopes Configuration" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    } else {
                        # No IPv6 scopes found - could be not configured or not supported
                        $IPv6StatusText = "ℹ️ No IPv6 DHCP scopes found in this environment."
                        $IPv6DetailText = "This is normal in most environments as IPv6 DHCP is rarely deployed. Most networks use IPv6 stateless autoconfiguration (SLAAC) instead of DHCP for IPv6 address assignment."

                        New-HTMLText -Text $IPv6StatusText -Color Blue -FontWeight bold
                        New-HTMLText -Text $IPv6DetailText -Color Gray -FontSize 12px

                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "IPv6 DHCP Deployment Considerations:" -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Most environments use SLAAC (Stateless Address Autoconfiguration) for IPv6"
                                New-HTMLListItem -Text "IPv6 DHCP is typically only needed for stateful configuration requirements"
                                New-HTMLListItem -Text "Windows DHCP Server supports IPv6 starting with Windows Server 2008"
                                New-HTMLListItem -Text "IPv6 DHCP requires separate scope configuration from IPv4"
                            } -FontSize 11px
                        }
                    }
                }

                # Multicast DHCP Status
                New-HTMLSection -HeaderText "Multicast DHCP Status" -CanCollapse {
                    if ($DHCPData.MulticastScopes.Count -gt 0) {
                        # Multicast scopes are configured
                        New-HTMLText -Text "✅ Multicast DHCP scopes are configured in this environment." -Color Green -FontWeight bold
                        New-HTMLTable -DataTable $DHCPData.MulticastScopes -ScrollX -HideFooter -PagingLength 10 {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Orange -HighlightHeaders 'PercentageInUse'
                        } -Title "Multicast DHCP Scopes" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    } else {
                        # No multicast scopes found
                        $MulticastStatusText = "ℹ️ No Multicast DHCP scopes found in this environment."
                        $MulticastDetailText = "This is typical for most environments. Multicast DHCP is specialized for applications requiring automatic multicast address assignment, such as video streaming or specialized network applications."

                        New-HTMLText -Text $MulticastStatusText -Color Blue -FontWeight bold
                        New-HTMLText -Text $MulticastDetailText -Color Gray -FontSize 12px

                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "Multicast DHCP Use Cases:" -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Automatic assignment of multicast IP addresses"
                                New-HTMLListItem -Text "Video streaming and multimedia applications"
                                New-HTMLListItem -Text "Network-based applications requiring group communication"
                                New-HTMLListItem -Text "Reduces manual multicast address management"
                            } -FontSize 11px
                        }
                    }
                }

                # Security Filters Status
                New-HTMLSection -HeaderText "Security Filters Status" -CanCollapse {
                    if ($DHCPData.SecurityFilters.Count -gt 0) {
                        # Security filters are configured
                        New-HTMLText -Text "✅ DHCP Security filters are configured in this environment." -Color Green -FontWeight bold
                        New-HTMLTable -DataTable $DHCPData.SecurityFilters -ScrollX -HideFooter {
                            New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'None' -BackgroundColor LightYellow -HighlightHeaders 'FilteringMode'
                            New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'Allow' -BackgroundColor LightGreen -HighlightHeaders 'FilteringMode'
                            New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'Deny' -BackgroundColor Orange -HighlightHeaders 'FilteringMode'
                            New-HTMLTableCondition -Name 'FilteringMode' -ComparisonType string -Operator eq -Value 'Both' -BackgroundColor LightBlue -HighlightHeaders 'FilteringMode'
                        } -Title "MAC Address Filtering Configuration" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    } else {
                        # No security filters configured
                        $SecurityStatusText = "ℹ️ No DHCP security filters configured in this environment."
                        $SecurityDetailText = "Security filters are optional and provide MAC address-based filtering. This feature may not be available on older DHCP servers or may not be configured for security policy reasons."

                        New-HTMLText -Text $SecurityStatusText -Color Blue -FontWeight bold
                        New-HTMLText -Text $SecurityDetailText -Color Gray -FontSize 12px

                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "DHCP Security Filter Options:" -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Allow List: Only specified MAC addresses can receive DHCP leases"
                                New-HTMLListItem -Text "Deny List: Specified MAC addresses are blocked from DHCP"
                                New-HTMLListItem -Text "Vendor/User Class Filtering: Filter based on DHCP client classes"
                                New-HTMLListItem -Text "Requires Windows Server 2008 R2 or later for full functionality"
                            } -FontSize 11px
                        }
                    }
                }

                # DHCP Policies Status
                New-HTMLSection -HeaderText "DHCP Policies Status" -CanCollapse {
                    if ($DHCPData.Policies.Count -gt 0) {
                        # DHCP policies are configured
                        New-HTMLText -Text "✅ DHCP Policies are configured in this environment." -Color Green -FontWeight bold
                        New-HTMLTable -DataTable $DHCPData.Policies -ScrollX -HideFooter -PagingLength 15 {
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'ProcessingOrder' -ComparisonType number -Operator lt -Value 5 -BackgroundColor LightBlue -HighlightHeaders 'ProcessingOrder'
                        } -Title "DHCP Policy Configuration" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    } else {
                        # No DHCP policies configured
                        $PoliciesStatusText = "ℹ️ No DHCP Policies configured in this environment."
                        $PoliciesDetailText = "DHCP Policies provide advanced configuration options and require Windows Server 2012 or later. Many environments operate effectively without policies using standard scope configuration."

                        New-HTMLText -Text $PoliciesStatusText -Color Blue -FontWeight bold
                        New-HTMLText -Text $PoliciesDetailText -Color Gray -FontSize 12px

                        New-HTMLPanel -Invisible {
                            New-HTMLText -Text "DHCP Policy Capabilities (Windows Server 2012+):" -FontWeight bold
                            New-HTMLList {
                                New-HTMLListItem -Text "Conditional IP address assignment based on client attributes"
                                New-HTMLListItem -Text "Different lease durations for different device types"
                                New-HTMLListItem -Text "Custom DHCP options based on vendor class or user class"
                                New-HTMLListItem -Text "Advanced filtering based on MAC address patterns or client identifiers"
                            } -FontSize 11px
                        }
                    }
                }

                if ($DHCPData.Reservations.Count -gt 0) {
                    New-HTMLSection -HeaderText "Static Reservations" -CanCollapse {
                        New-HTMLTable -DataTable $DHCPData.Reservations -ScrollX -HideFooter -PagingLength 20 {
                            New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Dhcp' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Both' -BackgroundColor LightBlue
                        } -Title "Static IP Reservations" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    }
                }

                if ($DHCPData.NetworkBindings.Count -gt 0) {
                    New-HTMLSection -HeaderText "Network Bindings" -CanCollapse {
                        New-HTMLTable -DataTable $DHCPData.NetworkBindings -ScrollX -HideFooter {
                            New-HTMLTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'True' -BackgroundColor LightGreen -FailBackgroundColor Orange
                        } -Title "DHCP Server Network Interface Bindings" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    }
                }

                # Comprehensive Security and Best Practices Summary
                if ($DHCPData.ServerSettings.Count -gt 0) {
                    New-HTMLSection -HeaderText "Security & Best Practices Summary" -CanCollapse {
                        $SecuritySummary = $DHCPData.ServerSettings | ForEach-Object {
                            [PSCustomObject]@{
                                'Server'                 = $_.ServerName
                                'Authorization Status'   = if ($null -ne $_.IsAuthorized) {
                                    if ($_.IsAuthorized) { 'Authorized' } else { 'Not Authorized' }
                                } else { 'Unknown' }
                                'Domain Membership'      = if ($null -ne $_.IsDomainJoined) {
                                    if ($_.IsDomainJoined) { 'Domain Joined' } else { 'Workgroup' }
                                } else { 'Unknown' }
                                'Policy Activation'      = if ($null -ne $_.ActivatePolicies) { $_.ActivatePolicies } else { 'Unknown' }
                                'Conflict Detection'     = if ($_.ConflictDetectionAttempts -gt 0) { "$($_.ConflictDetectionAttempts) attempts" } else { 'Disabled' }
                                'Dynamic Bootp'          = if ($null -ne $_.DynamicBootp) { $_.DynamicBootp } else { 'Unknown' }
                                'NAP Integration'        = if ($null -ne $_.NapEnabled) { $_.NapEnabled } else { 'Unknown' }
                                'Restore Status'         = if ($_.RestoreStatus) { $_.RestoreStatus } else { 'N/A' }
                                'NPS Unreachable Action' = if ($_.NpsUnreachableAction) { $_.NpsUnreachableAction } else { 'N/A' }
                            }
                        }

                        New-HTMLTable -DataTable $SecuritySummary -HideFooter {
                            New-HTMLTableCondition -Name 'Authorization Status' -ComparisonType string -Operator eq -Value 'Authorized' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'Authorization Status' -ComparisonType string -Operator eq -Value 'Not Authorized' -BackgroundColor Red -Color White
                            New-HTMLTableCondition -Name 'Authorization Status' -ComparisonType string -Operator eq -Value 'Unknown' -BackgroundColor LightGray
                            New-HTMLTableCondition -Name 'Policy Activation' -ComparisonType string -Operator eq -Value $true -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'Conflict Detection' -ComparisonType string -Operator eq -Value 'Disabled' -BackgroundColor Orange
                            New-HTMLTableCondition -Name 'Domain Membership' -ComparisonType string -Operator eq -Value 'Domain Joined' -BackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'Domain Membership' -ComparisonType string -Operator eq -Value 'Workgroup' -BackgroundColor Orange
                        } -Title "DHCP Server Security Configuration" -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5')
                    }
                }
            }

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
