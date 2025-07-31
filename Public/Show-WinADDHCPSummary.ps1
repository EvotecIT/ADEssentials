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
        [switch] $TestMode,
        [string[]] $IncludeTabs = @('Overview', 'IPv4/IPv6', 'Utilization', 'ValidationIssues', 'Infrastructure', 'Options&Classes', 'Failover', 'NetworkSegmentation', 'Performance', 'SecurityCompliance'),
        [string[]] $ExcludeTabs = @(),
        [switch] $ShowTimingStatistics
    )

    # Initialize reporting version info
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Show-WinADDHCPSummary' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    # Set default file path if not provided
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }

    Write-Verbose "Show-WinADDHCPSummary - Starting DHCP report generation"

    # Gather DHCP data using Get-WinADDHCPSummary (with TestMode if specified)
    $GetWinADDHCPSummarySplat = @{
        Forest                    = $Forest
        ExcludeDomains            = $ExcludeDomains
        ExcludeDomainControllers  = $ExcludeDomainControllers
        IncludeDomains            = $IncludeDomains
        IncludeDomainControllers  = $IncludeDomainControllers
        ComputerName              = $ComputerName
        SkipRODC                  = $SkipRODC
        ExtendedForestInformation = $ExtendedForestInformation
    }

    if ($TestMode) { $GetWinADDHCPSummarySplat.TestMode = $TestMode }
    # Include optional parameters based on user input
    # if ($IncludeDomainControllers) { $GetWinADDHCPSummarySplat.IncludeDomainControllers = $IncludeDomainControllers }
    # if ($ComputerName) { $GetWinADDHCPSummarySplat.ComputerName = $ComputerName }
    # if ($SkipRODC) { $GetWinADDHCPSummarySplat.SkipRODC = $SkipRODC }
    # if ($ExtendedForestInformation) { $GetWinADDHCPSummarySplat.ExtendedForestInformation = $ExtendedForestInformation }
    if ($TestMode) { $GetWinADDHCPSummarySplat.TestMode = $TestMode }

    Write-Verbose "Show-WinADDHCPSummary - Gathering DHCP data from Get-WinADDHCPSummary"
    $DHCPData = Get-WinADDHCPSummary @GetWinADDHCPSummarySplat

    if (-not $DHCPData) {
        Write-Warning "Show-WinADDHCPSummary - No DHCP data available to generate report"
        return
    }

    # Use statistics directly from Get function - no need for null protection as Get function handles this
    $TotalServers = $DHCPData.Statistics.TotalServers
    $ServersOnline = $DHCPData.Statistics.ServersOnline
    $ServersOffline = $DHCPData.Statistics.ServersOffline
    $ServersWithIssues = $DHCPData.Statistics.ServersWithIssues
    $TotalScopes = $DHCPData.Statistics.TotalScopes
    $ScopesActive = $DHCPData.Statistics.ScopesActive
    $ScopesInactive = $DHCPData.Statistics.ScopesInactive
    $ScopesWithIssues = $DHCPData.Statistics.ScopesWithIssues
    $TotalAddresses = $DHCPData.Statistics.TotalAddresses
    $AddressesInUse = $DHCPData.Statistics.AddressesInUse
    $AddressesFree = $DHCPData.Statistics.AddressesFree
    $OverallPercentageInUse = $DHCPData.Statistics.OverallPercentageInUse

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
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString ", " -BoolAsString
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

        # Determine which tabs to show
        $TabsToShow = if ($ExcludeTabs.Count -gt 0) {
            $IncludeTabs | Where-Object { $_ -notin $ExcludeTabs }
        } else {
            $IncludeTabs
        }
        
        New-HTMLTabPanel {
            # Overview tab (always show)
            if ('Overview' -in $TabsToShow) {
                New-DHCPOverviewTab -DHCPData $DHCPData
            }
            
            # Validation Issues tab
            if ('ValidationIssues' -in $TabsToShow) {
                New-DHCPValidationIssuesTab -DHCPData $DHCPData
            }
            
            # Infrastructure main tab with nested tabs
            if (@('Infrastructure', 'IPv4/IPv6', 'Failover', 'NetworkSegmentation') | Where-Object { $_ -in $TabsToShow }) {
                New-DHCPInfrastructureMainTab -DHCPData $DHCPData -IncludeTabs $TabsToShow
            }
            
            # Configuration main tab with nested tabs
            if (@('Configuration', 'Options&Classes', 'Policies', 'ServerSettings') | Where-Object { $_ -in $TabsToShow }) {
                New-DHCPConfigurationMainTab -DHCPData $DHCPData -IncludeTabs $TabsToShow
            }
            
            # Analysis main tab with nested tabs
            if (@('Analysis', 'Utilization', 'Performance', 'SecurityCompliance', 'ScaleAnalysis') | Where-Object { $_ -in $TabsToShow }) {
                New-DHCPAnalysisMainTab -DHCPData $DHCPData -IncludeTabs $TabsToShow -ShowTimingStatistics:$ShowTimingStatistics
            }
            
            # Monitoring tab (optional)
            if ('Monitoring' -in $TabsToShow -and $DHCPData.Statistics.TotalAddresses -gt 50000) {
                New-DHCPMonitoringTab -DHCPData $DHCPData
            }
        }

    } -ShowHTML:(-not $HideHTML.IsPresent) -Online:$Online.IsPresent -TitleText "DHCP Infrastructure Report" -FilePath $FilePath

    Write-Verbose "Show-WinADDHCPSummary - HTML report generated: $FilePath"

    if ($PassThru) {
        return $DHCPData
    }
}

