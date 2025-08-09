function Get-WinADDHCPServerValidation {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [System.Collections.IDictionary] $ForestInformation,
        [System.Collections.Generic.List[Object]] $DHCPSummaryServers,
        [switch] $TestMode
    )

    Write-Verbose "Get-WinADDHCPServerValidation - Processing DHCP server: $Computer"

    # Initialize server object
    $ServerInfo = [ordered] @{
        ServerName           = $Computer
        IsReachable          = $false
        PingSuccessful       = $null
        DNSResolvable        = $null
        DHCPResponding       = $null
        IsADDomainController = $false
        DHCPRole             = 'Unknown'
        Version              = $null
        Status               = 'Unknown'
        ErrorMessage         = $null
        IPAddress            = $null
        ResponseTimeMs       = $null
        ReverseDNSName       = $null
        ReverseDNSValid      = $null
        ScopeCount           = 0
        ActiveScopeCount     = 0
        InactiveScopeCount   = 0
        ScopesWithIssues     = 0
        TotalAddresses       = 0
        AddressesInUse       = 0
        AddressesFree        = 0
        PercentageInUse      = 0
        IsAuthorized         = $null
        AuthorizationStatus  = 'Unknown'
        Issues               = [System.Collections.Generic.List[string]]::new()
        HasIssues            = $false
        GatheredFrom         = $Computer
        GatheredDate         = Get-Date
    }

    # Check if server is a domain controller
    if ($ForestInformation) {
        $DC = $ForestInformation.ForestDomainControllers | Where-Object { $_.HostName -eq $Computer }
        if ($DC) {
            $ServerInfo.IsADDomainController = $true
            $ServerInfo.DHCPRole = 'Domain Controller'
        }
    }

    # Test connectivity and get server information
    Write-Verbose "Get-WinADDHCPServerValidation - Performing comprehensive validation for $Computer"
    $ValidationResult = Get-WinDHCPServerInfo -ComputerName $Computer -TestMode:$TestMode

    # Update server info with comprehensive validation results
    $ServerInfo.IsReachable = $ValidationResult.IsReachable
    $ServerInfo.PingSuccessful = $ValidationResult.PingSuccessful
    $ServerInfo.DNSResolvable = $ValidationResult.DNSResolvable
    $ServerInfo.DHCPResponding = $ValidationResult.DHCPResponding
    $ServerInfo.Version = $ValidationResult.Version
    $ServerInfo.Status = $ValidationResult.Status
    $ServerInfo.ErrorMessage = $ValidationResult.ErrorMessage
    $ServerInfo.IPAddress = $ValidationResult.IPAddress
    $ServerInfo.ResponseTimeMs = $ValidationResult.ResponseTimeMs
    $ServerInfo.ReverseDNSName = $ValidationResult.ReverseDNSName
    $ServerInfo.ReverseDNSValid = $ValidationResult.ReverseDNSValid

    # DHCP Authorization Analysis
    try {
        Write-Verbose "Get-WinADDHCPServerValidation - Checking DHCP authorization for $Computer"
        if ($TestMode) {
            $AuthorizedServers = Get-TestModeDHCPData -DataType 'DhcpServersInDC' | Where-Object { $_.DnsName -eq $Computer }
        } else {
            $AuthorizedServers = Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object { $_.DnsName -eq $Computer -or $_.IPAddress -eq $Computer }
        }
        if ($AuthorizedServers) {
            $ServerInfo.IsAuthorized = $true
            $ServerInfo.AuthorizationStatus = "Authorized in AD"
        } else {
            $ServerInfo.IsAuthorized = $false
            $ServerInfo.AuthorizationStatus = "Not authorized in AD"
            $ServerInfo.Issues.Add("DHCP server is not authorized in Active Directory")
            $ServerInfo.HasIssues = $true
        }
    } catch {
        $ServerInfo.IsAuthorized = $null
        $ServerInfo.AuthorizationStatus = "Unable to verify authorization: $($_.Exception.Message)"
        $ServerInfo.Issues.Add("Could not verify DHCP authorization status")
    }

    # Security Analysis
    try {
        Write-Verbose "Get-WinADDHCPServerValidation - Performing security analysis for $Computer"

        # Check for DHCP service account configuration
        if (-not $TestMode) {
            $DHCPService = Get-WmiObject -Class Win32_Service -Filter "Name='DHCPServer'" -ComputerName $Computer -ErrorAction SilentlyContinue
        } else {
            $DHCPService = $null  # Skip service check in test mode
        }
        if ($DHCPService) {
            if ($DHCPService.StartName -eq "LocalSystem") {
                $ServerInfo.Issues.Add("DHCP service running as LocalSystem - consider using dedicated service account")
            }
        }

        # Check for common security misconfigurations
        if (-not $TestMode) {
            $DHCPAuditSettings = Get-DhcpServerAuditLog -ComputerName $Computer -ErrorAction SilentlyContinue
        } else {
            # Simulate audit settings in test mode
            $DHCPAuditSettings = [PSCustomObject]@{ Enable = $Computer -ne 'dc01.domain.com' }
        }
        if ($DHCPAuditSettings) {
            if (-not $DHCPAuditSettings.Enable) {
                $ServerInfo.Issues.Add("DHCP audit logging is disabled - enable for security monitoring")
                $ServerInfo.HasIssues = $true
            }
        }

    } catch {
        Write-Warning "Get-WinADDHCPServerValidation - Security analysis failed for $Computer`: $($_.Exception.Message)"
    }

    return [PSCustomObject]$ServerInfo
}