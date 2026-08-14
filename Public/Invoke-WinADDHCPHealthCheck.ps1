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

    .PARAMETER SkipScopeDetails
    When specified, skips collection of detailed scope information for faster health checking.
    This improves performance but reduces the granularity of scope-level health assessments.
    Server-level health checks will still be performed.

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
        [switch] $SkipScopeDetails,
        [switch] $Quiet
    )

    Get-WinADDHCPHealthCheck @PSBoundParameters
}
