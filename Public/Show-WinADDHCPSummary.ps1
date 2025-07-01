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

        New-HTMLSection -HeaderText "DHCP Summary" {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "DHCP Infrastructure Summary" -Color Blue -FontSize 12pt -FontWeight bold

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

                New-HTMLList -FontSize 10pt {
                    New-HTMLListItem -Text "Total DHCP Servers: ", $TotalServers -Color None, DodgerBlue -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers Online: ", $ServersOnline -Color None, LightGreen -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers Offline: ", $ServersOffline -Color None, Salmon -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with Issues: ", $ServersWithIssues -Color None, Orange -FontWeight normal, bold
                }

                New-HTMLText -Text "Scope Statistics" -Color Blue -FontSize 12pt -FontWeight bold

                New-HTMLList -FontSize 10pt {
                    New-HTMLListItem -Text "Total Scopes: ", $TotalScopes -Color None, DodgerBlue -FontWeight normal, bold
                    New-HTMLListItem -Text "Active Scopes: ", $ScopesActive -Color None, LightGreen -FontWeight normal, bold
                    New-HTMLListItem -Text "Inactive Scopes: ", $ScopesInactive -Color None, Orange -FontWeight normal, bold
                    New-HTMLListItem -Text "Scopes with Issues: ", $ScopesWithIssues -Color None, Salmon -FontWeight normal, bold
                }

                New-HTMLText -Text "Address Pool Statistics" -Color Blue -FontSize 12pt -FontWeight bold

                New-HTMLList -FontSize 10pt {
                    New-HTMLListItem -Text "Total IP Addresses: ", $TotalAddresses.ToString("N0") -Color None, DodgerBlue -FontWeight normal, bold
                    New-HTMLListItem -Text "Addresses In Use: ", $AddressesInUse.ToString("N0") -Color None, Orange -FontWeight normal, bold
                    New-HTMLListItem -Text "Addresses Available: ", $AddressesFree.ToString("N0") -Color None, LightGreen -FontWeight normal, bold
                    New-HTMLListItem -Text "Overall Utilization: ", "$OverallPercentageInUse%" -Color None, $(if ($OverallPercentageInUse -gt 80) { 'Salmon' } elseif ($OverallPercentageInUse -gt 60) { 'Orange' } else { 'LightGreen' }) -FontWeight normal, bold
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

    } -ShowHTML:(-not $HideHTML.IsPresent) -Online:$Online.IsPresent -TitleText "DHCP Infrastructure Report" -FilePath $FilePath

    Write-Verbose "Show-WinADDHCPSummary - HTML report generated: $FilePath"

    if ($PassThru) {
        return $DHCPData
    }
}
