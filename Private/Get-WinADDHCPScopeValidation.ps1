function Get-WinADDHCPScopeValidation {
    [CmdletBinding()]
    param(
        [Object] $Scope,
        [PSCustomObject] $ScopeObject
    )

    # Validate scope configuration
    # Check lease duration (should not exceed 48 hours unless explicitly documented)
    if ($Scope.LeaseDuration.TotalHours -gt 48) {
        # Check for documented exceptions (like V2 validator's "DHCP lease time" check)
        if ($Scope.Description -notlike "*DHCP lease time*") {
            # Use consistent string for both reports
            $ScopeObject.Issues.Add("Lease duration exceeds 48 hours ($([Math]::Round($Scope.LeaseDuration.TotalHours, 1)) hours)")
            $ScopeObject.Issues.Add("Lease duration greater than 48 hours")  # For minimal report matching
            $ScopeObject.HasIssues = $true
        }
    }

    # Check for dynamic DNS updates with public DNS servers
    if ($ScopeObject.DNSSettings -and $ScopeObject.DNSSettings.DynamicUpdates -ne 'Never') {
        if ($ScopeObject.DNSServers) {
            # Check for non-private DNS servers (V2 validator's ^10. check)
            $DNSServerArray = $ScopeObject.DNSServers -split ',' | ForEach-Object { $_.Trim() }
            $NonPrivateDNS = $DNSServerArray | Where-Object { 
                $_ -notmatch "^10\." -and 
                $_ -notmatch "^192\.168\." -and 
                $_ -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\." 
            }
            if ($NonPrivateDNS) {
                $ScopeObject.Issues.Add("DNS updates enabled with non-private DNS servers: $($NonPrivateDNS -join ', ')")
                $ScopeObject.Issues.Add("DNS updates enabled with public DNS servers")  # For minimal report matching
                $ScopeObject.HasIssues = $true
            }
        }

        # Enhanced DNS update validation (from V2 validator)
        if (-not $ScopeObject.UpdateDnsRRForOlderClients -and -not $ScopeObject.DeleteDnsRROnLeaseExpiry) {
            $ScopeObject.Issues.Add("Both UpdateDnsRRForOlderClients and DeleteDnsRROnLeaseExpiry are disabled")
            $ScopeObject.Issues.Add("DNS update settings misconfigured")  # For minimal report matching
            $ScopeObject.HasIssues = $true
        } elseif (-not $ScopeObject.UpdateDnsRRForOlderClients) {
            $ScopeObject.Issues.Add("UpdateDnsRRForOlderClients is disabled")
            $ScopeObject.Issues.Add("DNS update settings misconfigured")  # For minimal report matching
            $ScopeObject.HasIssues = $true
        } elseif (-not $ScopeObject.DeleteDnsRROnLeaseExpiry) {
            $ScopeObject.Issues.Add("DeleteDnsRROnLeaseExpiry is disabled")
            $ScopeObject.Issues.Add("DNS update settings misconfigured")  # For minimal report matching
            $ScopeObject.HasIssues = $true
        }

        if (-not $ScopeObject.DomainNameOption -or [string]::IsNullOrEmpty($ScopeObject.DomainNameOption)) {
            $ScopeObject.Issues.Add("Domain name option (015) is empty")
            $ScopeObject.Issues.Add("DNS updates enabled but missing domain name option")  # For minimal report matching
            $ScopeObject.HasIssues = $true
        }
    }

    # Check for missing failover configuration
    if (-not $ScopeObject.FailoverPartner) {
        $ScopeObject.Issues.Add("DHCP Failover not configured")
        $ScopeObject.Issues.Add("Missing DHCP failover configuration")  # For minimal report matching
        $ScopeObject.HasIssues = $true
    }

    return $ScopeObject.HasIssues
}