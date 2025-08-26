function Get-WinADDHCPStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $DHCPSummary,
        [int] $TotalServers,
        [int] $ServersWithIssues,
        [int] $TotalScopes,
        [int] $ScopesWithIssues,
        [switch] $SkipScopeDetails
    )

    Write-Verbose "Get-WinADDHCPStatistics - Calculating overall statistics"

    # Calculate overall statistics efficiently using single-pass operations
    $ServersOnlineCount = 0
    $ServersOfflineCount = 0
    $ScopesActiveCount = 0
    $ScopesInactiveCount = 0

    foreach ($Server in $DHCPSummary.Servers) {
        if ($Server.Status -eq 'Online' -or ($Server.DHCPResponding -eq $true)) {
            $ServersOnlineCount++
        } elseif ($Server.Status -eq 'Unreachable' -or ($Server.DHCPResponding -eq $false)) {
            $ServersOfflineCount++
        }
    }

    # When SkipScopeDetails is used, scope-level statistics are not available
    if (-not $SkipScopeDetails) {
        foreach ($Scope in $DHCPSummary.Scopes) {
            if ($Scope.State -eq 'Active') { $ScopesActiveCount++ }
            elseif ($Scope.State -eq 'Inactive') { $ScopesInactiveCount++ }
        }
    }

    $Statistics = [ordered] @{
        TotalServers           = $TotalServers
        ServersOnline          = $ServersOnlineCount
        ServersOffline         = $ServersOfflineCount
        ServersWithIssues      = $ServersWithIssues
        ServersWithoutIssues   = $TotalServers - $ServersWithIssues
        TotalScopes            = $TotalScopes
        ScopesActive           = $ScopesActiveCount
        ScopesInactive         = $ScopesInactiveCount
        ScopesWithIssues       = $ScopesWithIssues
        ScopesWithoutIssues    = $TotalScopes - $ScopesWithIssues
        TotalAddresses         = ($DHCPSummary.Servers | Measure-Object -Property TotalAddresses -Sum).Sum
        AddressesInUse         = ($DHCPSummary.Servers | Measure-Object -Property AddressesInUse -Sum).Sum
        AddressesFree          = ($DHCPSummary.Servers | Measure-Object -Property AddressesFree -Sum).Sum
        OverallPercentageInUse = 0
        # Enhanced statistics for new data types
        TotalIPv6Scopes        = $DHCPSummary.IPv6Scopes.Count
        IPv6ScopesWithIssues   = $DHCPSummary.IPv6ScopesWithIssues.Count
        TotalMulticastScopes   = $DHCPSummary.MulticastScopes.Count
        TotalReservations      = $DHCPSummary.Reservations.Count
        TotalPolicies          = $DHCPSummary.Policies.Count
        TotalSecurityFilters   = $DHCPSummary.SecurityFilters.Count
        TotalNetworkBindings   = $DHCPSummary.NetworkBindings.Count
        TotalOptions           = $DHCPSummary.Options.Count
        ServersWithFiltering   = ($DHCPSummary.SecurityFilters | Where-Object { $_.FilteringMode -ne 'None' }).Count
        ServersWithPolicies    = ($DHCPSummary.Policies | Select-Object -Property ServerName -Unique).Count
        # Error and Warning statistics
        TotalErrors            = $DHCPSummary.Errors.Count
        TotalWarnings          = $DHCPSummary.Warnings.Count
        ServersWithErrors      = ($DHCPSummary.Errors | Select-Object -Property ServerName -Unique).Count
        ServersWithWarnings    = ($DHCPSummary.Warnings | Select-Object -Property ServerName -Unique).Count
        MostCommonErrorType    = if ($DHCPSummary.Errors.Count -gt 0) { ($DHCPSummary.Errors | Group-Object Component | Sort-Object Count -Descending | Select-Object -First 1).Name } else { 'None' }
        MostCommonWarningType  = if ($DHCPSummary.Warnings.Count -gt 0) { ($DHCPSummary.Warnings | Group-Object Component | Sort-Object Count -Descending | Select-Object -First 1).Name } else { 'None' }
    }

    # Calculate overall percentage in use
    if ($Statistics.TotalAddresses -gt 0) {
        $Statistics.OverallPercentageInUse = [Math]::Round(($Statistics.AddressesInUse / $Statistics.TotalAddresses) * 100, 2)
    }

    Write-Verbose "Get-WinADDHCPStatistics - Statistics calculation completed"

    return $Statistics
}