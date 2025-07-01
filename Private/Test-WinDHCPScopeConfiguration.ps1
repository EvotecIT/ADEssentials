function Test-WinDHCPScopeConfiguration {
    <#
    .SYNOPSIS
    Internal helper function to validate DHCP scope configuration.

    .DESCRIPTION
    This internal function performs validation checks on DHCP scope configuration
    to identify common misconfigurations and best practice violations.

    .PARAMETER ComputerName
    The name or IP address of the DHCP server.

    .PARAMETER Scope
    The DHCP scope object to validate.

    .EXAMPLE
    Test-WinDHCPScopeConfiguration -ComputerName "dhcp01.domain.com" -Scope $ScopeObject

    .NOTES
    This is an internal helper function and should not be called directly.
    Validation checks include:
    - Lease duration exceeding 48 hours without documentation
    - DNS update settings with public DNS servers
    - Missing DHCP failover configuration
    - DNS record management settings
    - Domain name option configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName,

        [Parameter(Mandatory)]
        [object] $Scope
    )

    $ValidationResults = [ordered] @{
        HasIssues = $false
        Issues    = [System.Collections.Generic.List[string]]::new()
    }

    # Check lease duration (should not exceed 48 hours unless explicitly documented)
    if ($Scope.LeaseDuration.TotalHours -gt 48) {
        $ExceptionKeywords = @('lease time', '7d', 'day', 'extended', 'long')
        $HasException = $false

        foreach ($keyword in $ExceptionKeywords) {
            if ($Scope.Description -like "*$keyword*") {
                $HasException = $true
                break
            }
        }

        if (-not $HasException) {
            $ValidationResults.Issues.Add("Lease duration exceeds 48 hours ($([Math]::Round($Scope.LeaseDuration.TotalHours, 1)) hours) without documentation")
            $ValidationResults.HasIssues = $true
        }
    }

    # Check DNS settings
    try {
        $DNSSettings = Get-DhcpServerv4DnsSetting -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction Stop

        if ($DNSSettings.DynamicUpdates -ne 'Never') {
            # Get DHCP options for DNS servers and domain name
            try {
                $Options = Get-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction Stop
                $Option6 = $Options | Where-Object { $_.OptionId -eq 6 }  # DNS Servers
                $Option15 = $Options | Where-Object { $_.OptionId -eq 15 } # Domain Name

                # Check for public DNS servers with dynamic updates enabled
                if ($Option6 -and $Option6.Value) {
                    $PublicDNSServers = @()

                    foreach ($DNSServer in $Option6.Value) {
                        # Check if DNS server is not in private IP ranges
                        if ($DNSServer -notmatch '^10\.' -and
                            $DNSServer -notmatch '^192\.168\.' -and
                            $DNSServer -notmatch '^172\.(1[6-9]|2[0-9]|3[0-1])\.' -and
                            $DNSServer -notmatch '^127\.' -and
                            $DNSServer -ne '::1') {
                            $PublicDNSServers += $DNSServer
                        }
                    }

                    if ($PublicDNSServers.Count -gt 0) {
                        $ValidationResults.Issues.Add("DNS updates enabled with public DNS servers: $($PublicDNSServers -join ', ')")
                        $ValidationResults.HasIssues = $true
                    }
                }

                # Check DNS record management settings
                if (-not $DNSSettings.UpdateDnsRRForOlderClients) {
                    $ValidationResults.Issues.Add("UpdateDnsRRForOlderClients is disabled")
                    $ValidationResults.HasIssues = $true
                }

                if (-not $DNSSettings.DeleteDnsRROnLeaseExpiry) {
                    $ValidationResults.Issues.Add("DeleteDnsRROnLeaseExpiry is disabled")
                    $ValidationResults.HasIssues = $true
                }

                # Check domain name option
                if (-not $Option15 -or [string]::IsNullOrEmpty($Option15.Value)) {
                    $ValidationResults.Issues.Add("Domain name option (015) is empty")
                    $ValidationResults.HasIssues = $true
                }

            } catch {
                Write-Verbose "Test-WinDHCPScopeConfiguration - Failed to get DHCP options for scope $($Scope.ScopeId) on $ComputerName`: $($_.Exception.Message)"
                $ValidationResults.Issues.Add("Unable to retrieve DHCP options for validation")
                $ValidationResults.HasIssues = $true
            }
        }
    } catch {
        Write-Verbose "Test-WinDHCPScopeConfiguration - Failed to get DNS settings for scope $($Scope.ScopeId) on $ComputerName`: $($_.Exception.Message)"
        $ValidationResults.Issues.Add("Unable to retrieve DNS settings for validation")
        $ValidationResults.HasIssues = $true
    }

    # Check DHCP failover configuration
    try {
        $Failover = Get-DhcpServerv4Failover -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction SilentlyContinue
        if (-not $Failover) {
            $ValidationResults.Issues.Add("DHCP Failover not configured")
            $ValidationResults.HasIssues = $true
        }
    } catch {
        Write-Verbose "Test-WinDHCPScopeConfiguration - Failed to check failover for scope $($Scope.ScopeId) on $ComputerName`: $($_.Exception.Message)"
    }

    # Check for very short lease durations (less than 1 hour) which might indicate test scopes
    if ($Scope.LeaseDuration.TotalHours -lt 1 -and $Scope.State -eq 'Active') {
        $ValidationResults.Issues.Add("Very short lease duration ($([Math]::Round($Scope.LeaseDuration.TotalMinutes, 0)) minutes) for active scope")
        $ValidationResults.HasIssues = $true
    }

    # Check for extremely high utilization
    try {
        $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction Stop
        if ($ScopeStats.PercentageInUse -gt 95 -and $Scope.State -eq 'Active') {
            $ValidationResults.Issues.Add("Critical utilization level: $([Math]::Round($ScopeStats.PercentageInUse, 1))% in use")
            $ValidationResults.HasIssues = $true
        }
    } catch {
        Write-Verbose "Test-WinDHCPScopeConfiguration - Failed to get scope statistics for $($Scope.ScopeId) on $ComputerName"
    }

    return $ValidationResults
}
