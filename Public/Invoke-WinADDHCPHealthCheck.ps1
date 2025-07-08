function Invoke-WinADDHCPHealthCheck {
    <#
    .SYNOPSIS
    Performs a quick health check of DHCP infrastructure and provides a health score.

    .DESCRIPTION
    This function analyzes DHCP infrastructure health by checking server availability, configuration issues,
    utilization levels, and other critical factors. It provides a numerical health score and detailed
    issue analysis to help quickly assess the overall state of your DHCP environment.

    The health score is calculated based on:
    - Server availability (20 points deducted per offline server category)
    - Configuration issues (15 points for servers, 10 points for scopes)
    - Utilization levels (15 points for high, 10 points for moderate)
    - Critical utilization scopes (20 points deducted)

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

    .PARAMETER Quiet
    When specified, suppresses console output and only returns the health check object.

    .EXAMPLE
    Invoke-WinADDHCPHealthCheck

    Performs a basic DHCP health check and displays results to console.

    .EXAMPLE
    $HealthCheck = Invoke-WinADDHCPHealthCheck -Quiet
    if ($HealthCheck.HealthScore -lt 80) {
        Write-Warning "DHCP infrastructure needs attention!"
    }

    Performs a quiet health check and takes action based on the score.

    .EXAMPLE
    Invoke-WinADDHCPHealthCheck -ComputerName "dhcp01.domain.com", "dhcp02.domain.com"

    Performs health check on specific DHCP servers only.

    .EXAMPLE
    Invoke-WinADDHCPHealthCheck -Forest "contoso.com" -IncludeDomains "contoso.com", "subsidiary.com"

    Performs health check on DHCP servers in specific domains within a forest.

    .OUTPUTS
    Returns a hashtable containing:
    - HealthScore: Numerical score from 0-100 indicating infrastructure health
    - Issues: Array of issue descriptions found during the check
    - Summary: The complete DHCP summary data used for analysis
    - Recommendations: Suggested actions based on findings

    .NOTES
    This function requires the DHCP PowerShell module and appropriate permissions to query DHCP servers.
    Health scores are interpreted as:
    - 90-100: Excellent health
    - 70-89: Good health with minor issues
    - 50-69: Fair health, attention needed
    - 0-49: Poor health, immediate action required

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
        [switch] $Quiet
    )

    if (-not $Quiet) {
        Write-Color -Text '[i] ', '[DHCP] ', 'Performing DHCP Health Check...' -Color Yellow, DarkGray, Green
    }

    # Get DHCP summary data
    $GetSummaryParams = @{}
    if ($Forest) { $GetSummaryParams.Forest = $Forest }
    if ($ExcludeDomains) { $GetSummaryParams.ExcludeDomains = $ExcludeDomains }
    if ($ExcludeDomainControllers) { $GetSummaryParams.ExcludeDomainControllers = $ExcludeDomainControllers }
    if ($IncludeDomains) { $GetSummaryParams.IncludeDomains = $IncludeDomains }
    if ($IncludeDomainControllers) { $GetSummaryParams.IncludeDomainControllers = $IncludeDomainControllers }
    if ($ComputerName) { $GetSummaryParams.ComputerName = $ComputerName }
    if ($SkipRODC) { $GetSummaryParams.SkipRODC = $SkipRODC }
    if ($ExtendedForestInformation) { $GetSummaryParams.ExtendedForestInformation = $ExtendedForestInformation }

    try {
        $Summary = Get-WinADDHCPSummary @GetSummaryParams
    } catch {
        Write-Error "Failed to retrieve DHCP summary: $($_.Exception.Message)"
        return @{
            HealthScore     = 0
            Issues          = @("Failed to retrieve DHCP data: $($_.Exception.Message)")
            Summary         = $null
            Recommendations = @("Check DHCP server connectivity and permissions")
        }
    }

    # Check if no DHCP servers were found
    if (-not $Summary -or $Summary.Statistics.TotalServers -eq 0) {
        if (-not $Quiet) {
            Write-Color -Text '[!] ', '[DHCP] ', 'No DHCP servers found in the environment' -Color Yellow, DarkGray, Yellow
        }
        return @{
            HealthScore     = 0
            HealthStatus    = 'No Infrastructure'
            Issues          = @("No DHCP servers found in the environment")
            Recommendations = @("Install and configure DHCP servers", "Check DHCP server registration in Active Directory")
            Summary         = $Summary
            Timestamp       = Get-Date
        }
    }

    # Initialize health scoring
    $HealthScore = 100
    $Issues = @()
    $Recommendations = @()

    # Safely get statistics with null checking
    $ServersOffline = if ($Summary.Statistics.ServersOffline) { $Summary.Statistics.ServersOffline } else { 0 }
    $ServersWithIssues = if ($Summary.Statistics.ServersWithIssues) { $Summary.Statistics.ServersWithIssues } else { 0 }
    $ScopesWithIssues = if ($Summary.Statistics.ScopesWithIssues) { $Summary.Statistics.ScopesWithIssues } else { 0 }
    $OverallPercentageInUse = if ($Summary.Statistics.OverallPercentageInUse) { $Summary.Statistics.OverallPercentageInUse } else { 0 }

    # Check for offline servers (Critical: -20 points)
    if ($ServersOffline -gt 0) {
        $HealthScore -= 20
        $Issues += "❌ $ServersOffline server(s) offline"
        $Recommendations += "🔴 Investigate and restore offline DHCP servers immediately"
    }

    # Check for servers with configuration issues (Major: -15 points)
    if ($ServersWithIssues -gt 0) {
        $HealthScore -= 15
        $Issues += "⚠️ $ServersWithIssues server(s) have configuration issues"
        $Recommendations += "⚠️ Review server configuration issues and resolve them"
    }

    # Check for scopes with configuration issues (Moderate: -10 points)
    if ($ScopesWithIssues -gt 0) {
        $HealthScore -= 10
        $Issues += "⚠️ $ScopesWithIssues scope(s) have configuration issues"
        $Recommendations += "⚠️ Review scope configuration issues for optimal DHCP operation"
    }

    # Check overall utilization levels
    if ($OverallPercentageInUse -gt 85) {
        $HealthScore -= 15
        $Issues += "⚠️ High overall utilization: $OverallPercentageInUse%"
        $Recommendations += "🔶 Plan for DHCP scope expansion due to high utilization"
    } elseif ($OverallPercentageInUse -gt 75) {
        $HealthScore -= 10
        $Issues += "⚠️ Moderate utilization: $OverallPercentageInUse%"
        $Recommendations += "ℹ️ Monitor utilization trends for capacity planning"
    }

    # Check for critical utilization scopes (Critical: -20 points)
    $CriticalScopes = @()
    if ($Summary.Scopes) {
        $CriticalScopes = @($Summary.Scopes | Where-Object { $_.PercentageInUse -gt 90 -and $_.State -eq 'Active' })
    }
    if ($CriticalScopes.Count -gt 0) {
        $HealthScore -= 20
        $Issues += "❌ $($CriticalScopes.Count) scope(s) have critical utilization (>90%)"
        $Recommendations += "🚨 Immediately expand address pools for scopes with >90% utilization"
    }

    # Check for validation results and add specific recommendations (with null checking)
    if ($Summary.ValidationResults -and $Summary.ValidationResults.Summary.TotalCriticalIssues -gt 0) {
        if ($Summary.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count -gt 0) {
            $Recommendations += "🔴 Review scopes with public DNS servers and disable dynamic updates or use internal DNS"
        }
        if ($Summary.ValidationResults.CriticalIssues.HighUtilization.Count -gt 0) {
            $Recommendations += "🔴 Expand address pools for scopes with >90% utilization"
        }
    }

    if ($Summary.ValidationResults -and $Summary.ValidationResults.Summary.TotalWarningIssues -gt 0) {
        if ($Summary.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
            $Recommendations += "⚠️ Configure DHCP failover for high-availability scopes"
        }
        if ($Summary.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count -gt 0) {
            $Recommendations += "⚠️ Review extended lease durations for potential optimization"
        }
        if ($Summary.ValidationResults.WarningIssues.DNSRecordManagement.Count -gt 0) {
            $Recommendations += "⚠️ Review DNS record management settings for proper cleanup"
        }
    }

    # Ensure health score doesn't go below 0
    if ($HealthScore -lt 0) {
        $HealthScore = 0
    }

    # Determine health status and color for display
    $HealthStatus = switch ($HealthScore) {
        { $_ -ge 90 } { @{ Status = 'Excellent'; Color = 'Green' } }
        { $_ -ge 70 } { @{ Status = 'Good'; Color = 'Yellow' } }
        { $_ -ge 50 } { @{ Status = 'Fair'; Color = 'DarkYellow' } }
        default { @{ Status = 'Poor'; Color = 'Red' } }
    }

    # Display results if not in quiet mode
    if (-not $Quiet) {
        Write-Color -Text '[i] ', '[DHCP] ', 'Health Score: ', "$HealthScore/100", ' (', $($HealthStatus.Status), ')' -Color Yellow, DarkGray, White, $HealthStatus.Color, White, $HealthStatus.Color, White

        if ($Issues.Count -eq 0) {
            Write-Color -Text '[v] ', '[DHCP] ', 'No major issues detected - DHCP infrastructure is healthy!' -Color Green, DarkGray, Green
        } else {
            Write-Color -Text '[!] ', '[DHCP] ', 'Issues found:' -Color Red, DarkGray, Red
            foreach ($Issue in $Issues) {
                Write-Color -Text '    ', $Issue -Color DarkGray, White
            }
        }

        if ($Recommendations.Count -gt 0) {
            Write-Color -Text '[→] ', '[DHCP] ', 'Recommended Actions:' -Color Cyan, DarkGray, Cyan
            foreach ($Recommendation in $Recommendations) {
                Write-Color -Text '    ', $Recommendation -Color DarkGray, White
            }
        }

        # Display key statistics (with safe handling of null/empty values)
        Write-Color -Text '[i] ', '[DHCP] ', 'Infrastructure Summary:' -Color Yellow, DarkGray, Blue

        $TotalServers = if ($Summary.Statistics.TotalServers) { $Summary.Statistics.TotalServers } else { 0 }
        $ServersOnline = if ($Summary.Statistics.ServersOnline) { $Summary.Statistics.ServersOnline } else { 0 }
        $ServersOffline = if ($Summary.Statistics.ServersOffline) { $Summary.Statistics.ServersOffline } else { 0 }
        $TotalScopes = if ($Summary.Statistics.TotalScopes) { $Summary.Statistics.TotalScopes } else { 0 }
        $ScopesActive = if ($Summary.Statistics.ScopesActive) { $Summary.Statistics.ScopesActive } else { 0 }
        $ScopesWithIssues = if ($Summary.Statistics.ScopesWithIssues) { $Summary.Statistics.ScopesWithIssues } else { 0 }
        $OverallUtilization = if ($Summary.Statistics.OverallPercentageInUse) { $Summary.Statistics.OverallPercentageInUse } else { 0 }
        $CriticalIssues = if ($Summary.ValidationResults.Summary.TotalCriticalIssues) { $Summary.ValidationResults.Summary.TotalCriticalIssues } else { 0 }
        $WarningIssues = if ($Summary.ValidationResults.Summary.TotalWarningIssues) { $Summary.ValidationResults.Summary.TotalWarningIssues } else { 0 }

        Write-Color -Text '    Total Servers: ', $TotalServers, ' (Online: ', $ServersOnline, ', Offline: ', $ServersOffline, ')' -Color DarkGray, White, DarkGray, $(if ($ServersOffline -eq 0) { 'Green' } else { 'Red' }), DarkGray, $(if ($ServersOffline -eq 0) { 'Green' } else { 'Red' }), DarkGray
        Write-Color -Text '    Total Scopes: ', $TotalScopes, ' (Active: ', $ScopesActive, ', With Issues: ', $ScopesWithIssues, ')' -Color DarkGray, White, DarkGray, Green, DarkGray, $(if ($ScopesWithIssues -eq 0) { 'Green' } else { 'Red' }), DarkGray
        Write-Color -Text '    Overall Utilization: ', "$OverallUtilization%" -Color DarkGray, $(if ($OverallUtilization -gt 80) { 'Red' } elseif ($OverallUtilization -gt 60) { 'Yellow' } else { 'Green' })
        Write-Color -Text '    Critical Issues: ', $CriticalIssues -Color DarkGray, $(if ($CriticalIssues -gt 0) { 'Red' } else { 'Green' })
        Write-Color -Text '    Warning Issues: ', $WarningIssues -Color DarkGray, $(if ($WarningIssues -gt 0) { 'Yellow' } else { 'Green' })
    }

    # Return health check results
    return @{
        HealthScore     = $HealthScore
        HealthStatus    = $HealthStatus.Status
        Issues          = $Issues
        Recommendations = $Recommendations
        Summary         = $Summary
        Timestamp       = Get-Date
    }
}
