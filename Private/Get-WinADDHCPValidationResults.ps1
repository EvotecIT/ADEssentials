function Get-WinADDHCPValidationResults {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary,
        [switch] $SkipScopeDetails
    )

    Write-Verbose "Get-WinADDHCPValidationResults - Categorizing validation results"

    # Initialize validation collections
    $PublicDNSWithUpdates = [System.Collections.Generic.List[Object]]::new()
    $HighUtilization = [System.Collections.Generic.List[Object]]::new()
    $ServersOffline = [System.Collections.Generic.List[Object]]::new()
    $MissingFailover = [System.Collections.Generic.List[Object]]::new()
    $ExtendedLeaseDuration = [System.Collections.Generic.List[Object]]::new()
    $ModerateUtilization = [System.Collections.Generic.List[Object]]::new()
    $DNSRecordManagement = [System.Collections.Generic.List[Object]]::new()
    $MissingDomainName = [System.Collections.Generic.List[Object]]::new()
    $InactiveScopes = [System.Collections.Generic.List[Object]]::new()

    # Single pass through servers for offline check (always available)
    foreach ($Server in $DHCPSummary.Servers) {
        if ($Server.Status -eq 'Unreachable') {
            $ServersOffline.Add($Server)
        }
    }

    # Single pass through scopes with issues for detailed validations (always available)
    foreach ($Scope in $DHCPSummary.ScopesWithIssues) {
        foreach ($Issue in $Scope.Issues) {
            if ($Issue -like "*public DNS servers*" -or $Issue -like "*non-private DNS servers*") {
                if ($PublicDNSWithUpdates -notcontains $Scope) {
                    $PublicDNSWithUpdates.Add($Scope)
                }
            } 
            if ($Issue -like "*Failover not configured*") {
                if ($MissingFailover -notcontains $Scope) {
                    $MissingFailover.Add($Scope)
                }
            }
            if ($Issue -like "*exceeds 48 hours*") {
                if ($ExtendedLeaseDuration -notcontains $Scope) {
                    $ExtendedLeaseDuration.Add($Scope)
                }
            }
            if ($Issue -like "*UpdateDnsRRForOlderClients*" -or $Issue -like "*DeleteDnsRROnLeaseExpiry*") {
                if ($DNSRecordManagement -notcontains $Scope) {
                    $DNSRecordManagement.Add($Scope)
                }
            }
            if ($Issue -like "*Domain name option*") {
                if ($MissingDomainName -notcontains $Scope) {
                    $MissingDomainName.Add($Scope)
                }
            }
        }
    }

    # Scope state validations - only check inactive scopes (doesn't need statistics)
    foreach ($Scope in $DHCPSummary.Scopes) {
        if ($Scope.State -eq 'Inactive') {
            $InactiveScopes.Add($Scope)
        }
    }

    # Utilization validations only available when scope details were collected
    if (-not $SkipScopeDetails) {
        # Single pass through scopes for utilization validations
        foreach ($Scope in $DHCPSummary.Scopes) {
            # Check utilization levels
            if ($Scope.State -eq 'Active') {
                if ($Scope.PercentageInUse -gt 90) {
                    $HighUtilization.Add($Scope)
                } elseif ($Scope.PercentageInUse -gt 75) {
                    $ModerateUtilization.Add($Scope)
                }
            }
        }
    } else {
        # When SkipScopeDetails is used, inform about limitations
        Write-Verbose "Get-WinADDHCPValidationResults - Utilization validations skipped due to SkipScopeDetails parameter"
    }

    $ValidationResults = [ordered] @{
        # Critical issues that require immediate attention
        CriticalIssues    = [ordered] @{
            PublicDNSWithUpdates = $PublicDNSWithUpdates
            ServersOffline       = $ServersOffline
        }
        # Utilization issues that may need capacity planning
        UtilizationIssues = [ordered] @{
            HighUtilization     = $HighUtilization
            ModerateUtilization = $ModerateUtilization
        }
        # Warning issues that should be addressed soon
        WarningIssues     = [ordered] @{
            MissingFailover       = $MissingFailover
            ExtendedLeaseDuration = $ExtendedLeaseDuration
            DNSRecordManagement   = $DNSRecordManagement
        }
        # Information issues that are good to know but not urgent
        InfoIssues        = [ordered] @{
            MissingDomainName = $MissingDomainName
            InactiveScopes    = $InactiveScopes
        }
        # Summary counters for quick overview
        Summary           = [ordered] @{
            TotalCriticalIssues    = 0
            TotalUtilizationIssues = 0
            TotalWarningIssues     = 0
            TotalInfoIssues        = 0
            ScopesWithCritical     = 0
            ScopesWithUtilization  = 0
            ScopesWithWarnings     = 0
            ScopesWithInfo         = 0
        }
    }

    # Calculate validation summary counters efficiently
    $ValidationResults.Summary.TotalCriticalIssues = (
        $PublicDNSWithUpdates.Count +
        $ServersOffline.Count
    )

    $ValidationResults.Summary.TotalUtilizationIssues = (
        $HighUtilization.Count +
        $ModerateUtilization.Count
    )

    $ValidationResults.Summary.TotalWarningIssues = (
        $MissingFailover.Count +
        $ExtendedLeaseDuration.Count +
        $DNSRecordManagement.Count
    )

    $ValidationResults.Summary.TotalInfoIssues = (
        $MissingDomainName.Count +
        $InactiveScopes.Count
    )

    # Calculate unique scope counts for each severity level using efficient single-pass array comprehension
    $CriticalScopes = @(
        $PublicDNSWithUpdates
    )
    $ValidationResults.Summary.ScopesWithCritical = ($CriticalScopes | Sort-Object -Property ScopeId -Unique).Count

    $UtilizationScopes = @(
        $HighUtilization
        $ModerateUtilization
    )
    $ValidationResults.Summary.ScopesWithUtilization = ($UtilizationScopes | Sort-Object -Property ScopeId -Unique).Count

    $WarningScopes = @(
        $MissingFailover
        $ExtendedLeaseDuration
        $DNSRecordManagement
    )
    $ValidationResults.Summary.ScopesWithWarnings = ($WarningScopes | Sort-Object -Property ScopeId -Unique).Count

    $InfoScopes = @(
        $MissingDomainName
        $InactiveScopes
    )
    $ValidationResults.Summary.ScopesWithInfo = ($InfoScopes | Sort-Object -Property ScopeId -Unique).Count

    return $ValidationResults
}