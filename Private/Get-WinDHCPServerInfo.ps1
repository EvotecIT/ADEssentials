function Get-WinDHCPServerInfo {
    <#
    .SYNOPSIS
    Internal helper function to gather basic DHCP server information with comprehensive validation.

    .DESCRIPTION
    This internal function retrieves basic information about a DHCP server including version,
    connectivity status, and performs comprehensive validation including ping, DNS resolution,
    and DHCP service availability. Used by the main DHCP functions.

    .PARAMETER ComputerName
    The name or IP address of the DHCP server to query.

    .EXAMPLE
    Get-WinDHCPServerInfo -ComputerName "dhcp01.domain.com"

    .NOTES
    This is an internal helper function and should not be called directly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName,
        [switch] $TestMode
    )

    $ServerInfo = [ordered] @{
        ServerName       = $ComputerName
        IsReachable      = $false
        PingSuccessful   = $false
        DNSResolvable    = $false
        DHCPResponding   = $false
        Version          = $null
        Status           = 'Unknown'
        ErrorMessage     = $null
        ValidationIssues = [System.Collections.Generic.List[string]]::new()
        IPAddress        = $null
        ResponseTimeMs   = $null
        ReverseDNSName   = $null
        ReverseDNSValid  = $false
    }

    # Step 1: DNS Resolution Test
    Write-Verbose "Get-WinDHCPServerInfo - Testing DNS resolution for $ComputerName"
    try {
        if ($TestMode) {
            # In test mode, simulate successful DNS resolution
            $TestServers = Get-TestModeDHCPData -DataType 'DhcpServersInDC'
            $TestServer = $TestServers | Where-Object { $_.DnsName -eq $ComputerName }
            if ($TestServer) {
                $ServerInfo.DNSResolvable = $true
                $ServerInfo.IPAddress = $TestServer.IPAddress
            } else {
                throw "DNS resolution failed"
            }
        } else {
            $DNSResult = Resolve-DnsName -Name $ComputerName -Type A -ErrorAction Stop
            $ServerInfo.DNSResolvable = $true
            $ServerInfo.IPAddress = ($DNSResult | Where-Object { $_.Type -eq 'A' } | Select-Object -First 1).IPAddress
        }
        Write-Verbose "Get-WinDHCPServerInfo - DNS resolution successful: $ComputerName -> $($ServerInfo.IPAddress)"
    } catch {
        $ServerInfo.ValidationIssues.Add("DNS resolution failed: $($_.Exception.Message)")
        Write-Verbose "Get-WinDHCPServerInfo - DNS resolution failed for $ComputerName`: $($_.Exception.Message)"
    }

    # Step 2: Ping Test (using target IP if DNS resolved, otherwise try the name)
    $PingTarget = if ($ServerInfo.IPAddress) { $ServerInfo.IPAddress } else { $ComputerName }
    Write-Verbose "Get-WinDHCPServerInfo - Testing ping connectivity to $PingTarget"
    try {
        if ($TestMode) {
            # In test mode, simulate ping results (all online for demo)
            $ServerInfo.PingSuccessful = $true
            $ServerInfo.ResponseTimeMs = 5
        } else {
            $PingResult = Test-Connection -ComputerName $PingTarget -Count 1 -ErrorAction Stop
            $ServerInfo.PingSuccessful = $true
            $ServerInfo.ResponseTimeMs = $PingResult.ResponseTime
        }
        Write-Verbose "Get-WinDHCPServerInfo - Ping successful to $PingTarget ($($ServerInfo.ResponseTimeMs)ms)"
    } catch {
        $ServerInfo.ValidationIssues.Add("Ping failed: $($_.Exception.Message)")
        Write-Verbose "Get-WinDHCPServerInfo - Ping failed to $PingTarget`: $($_.Exception.Message)"
    }

    # Step 3: Reverse DNS Test (only if we have an IP address)
    if ($ServerInfo.IPAddress) {
        Write-Verbose "Get-WinDHCPServerInfo - Testing reverse DNS resolution for $($ServerInfo.IPAddress)"
        try {
            if ($TestMode) {
                # In test mode, simulate reverse DNS
                $ServerInfo.ReverseDNSName = $ComputerName
                $ServerInfo.ReverseDNSValid = $true
            } else {
                $ReverseDNSResult = Resolve-DnsName -Name $ServerInfo.IPAddress -Type PTR -ErrorAction Stop
            }
            if ($ReverseDNSResult -and $ReverseDNSResult.NameHost) {
                $ServerInfo.ReverseDNSName = $ReverseDNSResult.NameHost
                $ServerInfo.ReverseDNSValid = $true
                Write-Verbose "Get-WinDHCPServerInfo - Reverse DNS successful: $($ServerInfo.IPAddress) -> $($ServerInfo.ReverseDNSName)"

                # Check if reverse DNS matches original hostname (optional validation)
                if ($ServerInfo.ReverseDNSName -ne $ComputerName) {
                    $ServerInfo.ValidationIssues.Add("Reverse DNS mismatch: $($ServerInfo.ReverseDNSName) != $ComputerName")
                    Write-Verbose "Get-WinDHCPServerInfo - Reverse DNS name mismatch detected"
                }
            }
        } catch {
            $ServerInfo.ValidationIssues.Add("Reverse DNS failed: $($_.Exception.Message)")
            Write-Verbose "Get-WinDHCPServerInfo - Reverse DNS failed for $($ServerInfo.IPAddress): $($_.Exception.Message)"
        }
    } else {
        $ServerInfo.ValidationIssues.Add("No IP address available for reverse DNS test")
        Write-Verbose "Get-WinDHCPServerInfo - Skipping reverse DNS test - no IP address available"
    }

    # Step 4: DHCP Service Test
    Write-Verbose "Get-WinDHCPServerInfo - Testing DHCP service on $ComputerName"
    try {
        if ($TestMode) {
            $DHCPServerInfo = Get-TestModeDHCPData -DataType 'DhcpServerVersion' -ComputerName $ComputerName
        } else {
            $DHCPServerInfo = Get-DhcpServerVersion -ComputerName $ComputerName -ErrorAction Stop
        }
        $ServerInfo.DHCPResponding = $true
        $ServerInfo.IsReachable = $true
        $ServerInfo.Version = "$($DHCPServerInfo.MajorVersion).$($DHCPServerInfo.MinorVersion)"
        Write-Verbose "Get-WinDHCPServerInfo - DHCP service responding on $ComputerName (version: $($ServerInfo.Version))"
    } catch {
        $ServerInfo.ValidationIssues.Add("DHCP service not responding: $($_.Exception.Message)")
        Write-Verbose "Get-WinDHCPServerInfo - DHCP service not responding on $ComputerName`: $($_.Exception.Message)"
    }

    # Determine overall status based on validation results
    if ($ServerInfo.DHCPResponding) {
        $ServerInfo.Status = 'Online'
    } elseif ($ServerInfo.PingSuccessful) {
        $ServerInfo.Status = 'Reachable but DHCP not responding'
        $ServerInfo.ErrorMessage = "Server responds to ping but DHCP service is not accessible"
    } elseif ($ServerInfo.DNSResolvable) {
        $ServerInfo.Status = 'DNS OK but unreachable'
        $ServerInfo.ErrorMessage = "DNS resolves but server does not respond to ping"
    } else {
        $ServerInfo.Status = 'DNS resolution failed'
        $ServerInfo.ErrorMessage = "Server name cannot be resolved via DNS"
    }

    # Compile validation issues into error message if needed
    if ($ServerInfo.ValidationIssues.Count -gt 0) {
        if ([string]::IsNullOrEmpty($ServerInfo.ErrorMessage)) {
            $ServerInfo.ErrorMessage = $ServerInfo.ValidationIssues -join '; '
        }
    }

    return [PSCustomObject]$ServerInfo
}
