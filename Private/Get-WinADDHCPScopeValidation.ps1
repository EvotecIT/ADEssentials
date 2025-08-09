function Get-WinADDHCPScopeValidation {
    [CmdletBinding()]
    param(
        [Object] $Scope,
        [PSCustomObject] $ScopeObject
    )

    # Validate scope configuration
    # Check lease duration (should not exceed 48 hours unless explicitly documented)
    if ($Scope.LeaseDuration.TotalHours -gt 48) {
        # Check for documented exceptions (like your validator's "DHCP lease time" check)
        if ($Scope.Description -notlike "*DHCP lease time*" -and
            $Scope.Description -notlike "*lease time*" -and
            $Scope.Description -notlike "*7d*" -and
            $Scope.Description -notlike "*day*") {
            $ScopeObject.Issues.Add("Lease duration exceeds 48 hours ($([Math]::Round($Scope.LeaseDuration.TotalHours, 1)) hours) without documented exception")
            $ScopeObject.HasIssues = $true
        }
    }

    # Check for dynamic DNS updates with public DNS servers
    if ($ScopeObject.DNSSettings -and $ScopeObject.DNSSettings.DynamicUpdates -ne 'Never') {
        if ($ScopeObject.DNSServers) {
            # Check for non-private DNS servers (similar to your validator's ^10. check)
            $DNSServerArray = $ScopeObject.DNSServers -split ',' | ForEach-Object { $_.Trim() }
            $NonPrivateDNS = $DNSServerArray | Where-Object { 
                $_ -notmatch "^10\." -and 
                $_ -notmatch "^192\.168\." -and 
                $_ -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\." 
            }
            if ($NonPrivateDNS) {
                $ScopeObject.Issues.Add("DNS updates enabled with non-private DNS servers: $($NonPrivateDNS -join ', ')")
                $ScopeObject.HasIssues = $true
            }
        }

        # Enhanced DNS update validation (from your validator)
        if (-not $ScopeObject.UpdateDnsRRForOlderClients -and -not $ScopeObject.DeleteDnsRROnLeaseExpiry) {
            $ScopeObject.Issues.Add("Both UpdateDnsRRForOlderClients and DeleteDnsRROnLeaseExpiry are disabled")
            $ScopeObject.HasIssues = $true
        } elseif (-not $ScopeObject.UpdateDnsRRForOlderClients) {
            $ScopeObject.Issues.Add("UpdateDnsRRForOlderClients is disabled")
            $ScopeObject.HasIssues = $true
        } elseif (-not $ScopeObject.DeleteDnsRROnLeaseExpiry) {
            $ScopeObject.Issues.Add("DeleteDnsRROnLeaseExpiry is disabled")
            $ScopeObject.HasIssues = $true
        }

        if (-not $ScopeObject.DomainNameOption -or [string]::IsNullOrEmpty($ScopeObject.DomainNameOption)) {
            $ScopeObject.Issues.Add("Domain name option (015) is empty")
            $ScopeObject.HasIssues = $true
        }
    }

    # Check for missing failover configuration
    if (-not $ScopeObject.FailoverPartner) {
        $ScopeObject.Issues.Add("DHCP Failover not configured")
        $ScopeObject.HasIssues = $true
    }

    return $ScopeObject.HasIssues
}