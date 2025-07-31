function Get-WinADDHCPSummary {
    <#
    .SYNOPSIS
    Retrieves comprehensive DHCP server information from Active Directory forest.

    .DESCRIPTION
    This function gathers comprehensive DHCP server information from all DHCP servers in the Active Directory forest.
    It collects server details, scope information, database settings, audit logs, and performs validation checks
    for common DHCP configuration issues such as lease duration, DNS settings, and failover configuration.

    When Extended mode is enabled, the function additionally collects:
    - IPv6 scope information and statistics
    - Multicast scope configuration
    - DHCP security filters and MAC address filtering
    - Network binding configuration
    - DHCP policies and processing order
    - Static reservations across all scopes
    - Active lease information for high-utilization scopes
    - Comprehensive DHCP option analysis
    - Enhanced server settings and authorization status

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
    Specifies specific DHCP servers to perform detailed analysis on. If not provided, discovers all DHCP servers in the forest.
    When specified, all discovered servers will be shown but only the specified servers will have detailed scope and configuration analysis.

    .PARAMETER SkipRODC
    Indicates whether to skip Read-Only Domain Controllers (RODC) when retrieving DHCP information.

    .PARAMETER ExtendedForestInformation
    Specifies additional extended forest information to include in the output.

    .PARAMETER Extended
    When specified, includes additional detailed information about scopes, reservations, and options.

    .EXAMPLE
    Get-WinADDHCPSummary

    Retrieves DHCP summary information from all DHCP servers in the current forest.

    .EXAMPLE
    Get-WinADDHCPSummary -Forest "example.com" -Extended

    Retrieves extended DHCP summary information from all DHCP servers in the "example.com" forest.

    .EXAMPLE
    Get-WinADDHCPSummary -ComputerName "dhcp01.example.com", "dhcp02.example.com"

    Retrieves all DHCP servers from AD but performs detailed analysis only on the specified servers.

    .EXAMPLE
    Get-WinADDHCPSummary -IncludeDomains "domain1.com", "domain2.com" -SkipRODC

    Retrieves DHCP summary information from specific domains, excluding RODCs.

    .NOTES
    This function requires the DHCP PowerShell module and appropriate permissions to query DHCP servers.
    The function performs validation checks for common DHCP misconfigurations including:
    - Lease duration longer than 48 hours
    - Missing DHCP failover configuration
    - DNS update settings with public DNS servers
    - Missing domain name options

    .OUTPUTS
    Returns a hashtable containing:
    - Servers: List of DHCP servers with their status and configuration
    - Scopes: All IPv4 DHCP scopes with detailed information
    - ScopesWithIssues: IPv4 scopes that have configuration issues
    - IPv6Scopes: IPv6 scope information (Extended mode only)
    - IPv6ScopesWithIssues: IPv6 scopes with configuration problems (Extended mode only)
    - MulticastScopes: Multicast scope configuration (Extended mode only)
    - Reservations: Static IP reservations across all scopes (Extended mode only)
    - Leases: Active lease information for high-utilization scopes (Extended mode only)
    - Policies: DHCP policies and their configuration (Extended mode only)
    - SecurityFilters: MAC address filtering configuration (Extended mode only)
    - ServerSettings: Enhanced server configuration details (Extended mode only)
    - NetworkBindings: Network interface bindings (Extended mode only)
    - Options: Comprehensive DHCP option analysis (Extended mode only)
    - AuditLogs: Audit log configuration (Extended mode only)
    - Databases: Database configuration and backup settings (Extended mode only)
    - Statistics: Summary statistics about servers, scopes, and configurations
    - ValidationResults: Results of configuration validation checks

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
        [switch] $Extended,
        [switch] $TestMode
    )

    Write-Verbose "Get-WinADDHCPSummary - Starting DHCP information gathering"

    # Test Mode: Generate sample data for quick testing
    if ($TestMode) {
        Write-Verbose "Get-WinADDHCPSummary - Running in test mode with sample data"
        return @{
            Servers                   = @(
                [PSCustomObject]@{
                    ServerName = 'dhcp01.domain.com'; ComputerName = 'dhcp01.domain.com'; Status = 'Online'; Version = '10.0'; PingSuccessful = $true; DNSResolvable = $true; DHCPResponding = $true
                    ScopeCount = 15; ActiveScopeCount = 13; InactiveScopeCount = 2; TotalScopes = 15; ScopesActive = 13; ScopesInactive = 2; ScopesWithIssues = 2; TotalAddresses = 300; AddressesInUse = 135; AddressesFree = 165; PercentageInUse = 45
                    IsADDomainController = $false; DomainName = 'domain.com'; IPAddress = '192.168.1.10'
                    ReverseDNSName = 'dhcp01.domain.com'; ReverseDNSValid = $true; ResponseTimeMs = 5; DHCPRole = 'Primary'
                }
                [PSCustomObject]@{
                    ServerName = 'dhcp02.domain.com'; ComputerName = 'dhcp02.domain.com'; Status = 'Unreachable'; Version = $null; PingSuccessful = $false; DNSResolvable = $true; DHCPResponding = $false
                    ScopeCount = 0; ActiveScopeCount = 0; InactiveScopeCount = 0; TotalScopes = 0; ScopesActive = 0; ScopesInactive = 0; ScopesWithIssues = 0; TotalAddresses = 0; AddressesInUse = 0; AddressesFree = 0; PercentageInUse = 0
                    IsADDomainController = $false; DomainName = 'domain.com'; IPAddress = $null
                    ReverseDNSName = $null; ReverseDNSValid = $false; ResponseTimeMs = $null; DHCPRole = 'Unknown'
                }
                [PSCustomObject]@{
                    ServerName = 'dc01.domain.com'; ComputerName = 'dc01.domain.com'; Status = 'Online'; Version = '10.0'; PingSuccessful = $true; DNSResolvable = $true; DHCPResponding = $true
                    ScopeCount = 8; ActiveScopeCount = 8; InactiveScopeCount = 0; TotalScopes = 8; ScopesActive = 8; ScopesInactive = 0; ScopesWithIssues = 1; TotalAddresses = 150; AddressesInUse = 117; AddressesFree = 33; PercentageInUse = 78
                    IsADDomainController = $true; DomainName = 'domain.com'; IPAddress = '192.168.1.5'
                    ReverseDNSName = 'dc01.domain.com'; ReverseDNSValid = $true; ResponseTimeMs = 3; DHCPRole = 'Backup'
                }
            )
            Scopes                    = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; AddressesInUse = 170; AddressesFree = 30; HasIssues = $true; Issues = @('High utilization'); LeaseDurationHours = 8; FailoverPartner = $null }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.1.0.0'; Name = 'Guest Network'; State = 'Active'; PercentageInUse = 25; AddressesInUse = 50; AddressesFree = 150; HasIssues = $false; Issues = @(); LeaseDurationHours = 24; FailoverPartner = 'dhcp02.domain.com' }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; AddressesInUse = 92; AddressesFree = 8; HasIssues = $true; Issues = @('Critical utilization', 'No failover configured'); LeaseDurationHours = 168; FailoverPartner = $null }
            )
            ScopesWithIssues          = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; HasIssues = $true; Issues = @('High utilization'); LeaseDurationHours = 8; FailoverPartner = $null }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('Critical utilization', 'No failover configured'); LeaseDurationHours = 168; FailoverPartner = $null }
            )
            IPv6Scopes                = @()
            MulticastScopes           = @()
            SecurityFilters           = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; FilteringMode = 'Deny'; Allow = $false; Deny = $true }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; FilteringMode = 'None'; Allow = $false; Deny = $false }
            )
            Policies                  = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Name = 'Corporate Devices'; Enabled = $true; ProcessingOrder = 1; Condition = 'Vendor Class matches Corporate' }
            )
            ServerSettings            = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; IsAuthorized = $true; IsDomainJoined = $true; ActivatePolicies = $true; ConflictDetectionAttempts = 2 }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; IsAuthorized = $true; IsDomainJoined = $true; ActivatePolicies = $false; ConflictDetectionAttempts = 0 }
            )
            NetworkBindings           = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; InterfaceAlias = 'Ethernet'; IPAddress = '192.168.1.10'; State = $true }
            )
            Reservations              = @()
            AuditLogs                 = @()
            Databases                 = @()
            Statistics                = @{
                TotalServers = 3; ServersOnline = 2; ServersOffline = 1; ServersWithIssues = 1
                TotalScopes = 3; ScopesActive = 3; ScopesInactive = 0; ScopesWithIssues = 2
                TotalAddresses = 450; AddressesInUse = 312; AddressesFree = 138; OverallPercentageInUse = 69
            }
            SecurityAnalysis          = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; IsAuthorized = $true; AuthorizationStatus = 'Authorized in AD'; AuditLoggingEnabled = $true; ServiceAccount = 'Network Service'; SecurityRiskLevel = 'Low'; SecurityRecommendations = @() }
                [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; IsAuthorized = $false; AuthorizationStatus = 'Not authorized in AD'; AuditLoggingEnabled = $false; ServiceAccount = 'LocalSystem'; SecurityRiskLevel = 'Critical'; SecurityRecommendations = @('Authorize DHCP server in Active Directory immediately', 'Enable DHCP audit logging for security monitoring', 'Configure dedicated service account for DHCP service') }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; IsAuthorized = $true; AuthorizationStatus = 'Authorized in AD'; AuditLoggingEnabled = $false; ServiceAccount = 'LocalSystem'; SecurityRiskLevel = 'Medium'; SecurityRecommendations = @('Enable DHCP audit logging for security monitoring', 'Configure dedicated service account for DHCP service') }
            )
            PerformanceMetrics        = @(
                [PSCustomObject]@{ TotalServers = 3; TotalScopes = 3; AverageUtilization = 67.33; HighUtilizationScopes = 2; CriticalUtilizationScopes = 1; UnderUtilizedScopes = 0; CapacityPlanningRecommendations = @('1 scope(s) require immediate expansion', '2 scope(s) need expansion planning') }
            )
            NetworkDesignAnalysis     = @(
                [PSCustomObject]@{ TotalNetworkSegments = 3; ScopeOverlaps = @(); DesignRecommendations = @('Implement DHCP failover for high availability'); RedundancyAnalysis = @('2 scope(s) have no redundancy (single server)'); ScopeOverlapsCount = 0; RedundancyIssuesCount = 1; DesignRecommendationsCount = 1 }
            )
            BackupAnalysis            = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; BackupEnabled = $true; BackupIntervalMinutes = 60; CleanupIntervalMinutes = 1440; LastBackupTime = (Get-Date).AddHours(-2); BackupStatus = 'Healthy'; Recommendations = @() }
                [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; BackupEnabled = $false; BackupIntervalMinutes = 0; CleanupIntervalMinutes = 0; LastBackupTime = $null; BackupStatus = 'Critical'; Recommendations = @('Configure automated DHCP database backup', 'Set backup interval to 60 minutes', 'Set cleanup interval to 24 hours') }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; BackupEnabled = $true; BackupIntervalMinutes = 120; CleanupIntervalMinutes = 2880; LastBackupTime = (Get-Date).AddHours(-1); BackupStatus = 'Warning'; Recommendations = @('Reduce backup interval to 60 minutes for better recovery') }
            )
            ScopeRedundancyAnalysis   = @(
                [PSCustomObject]@{ ScopeId = '192.168.1.0'; ScopeName = 'Corporate LAN'; ServerName = 'dhcp01.domain.com'; State = 'Active'; UtilizationPercent = 85; FailoverPartner = 'None'; RedundancyStatus = 'No Failover - Risk'; RiskLevel = 'High'; Recommendation = 'Configure Failover' }
                [PSCustomObject]@{ ScopeId = '10.1.0.0'; ScopeName = 'Guest Network'; ServerName = 'dhcp01.domain.com'; State = 'Active'; UtilizationPercent = 25; FailoverPartner = 'dhcp02.domain.com'; RedundancyStatus = 'Failover Configured'; RiskLevel = 'Low'; Recommendation = 'Adequate' }
                [PSCustomObject]@{ ScopeId = '172.16.0.0'; ScopeName = 'Management'; ServerName = 'dc01.domain.com'; State = 'Active'; UtilizationPercent = 78; FailoverPartner = 'None'; RedundancyStatus = 'No Failover - Risk'; RiskLevel = 'High'; Recommendation = 'Configure Failover' }
            )
            ServerPerformanceAnalysis = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Status = 'Online'; TotalScopes = 15; ActiveScopes = 13; ScopesWithIssues = 2; TotalAddresses = 300; AddressesInUse = 135; UtilizationPercent = 45; PerformanceRating = 'Moderate'; CapacityStatus = 'Adequate' }
                [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Status = 'Unreachable'; TotalScopes = 0; ActiveScopes = 0; ScopesWithIssues = 0; TotalAddresses = 0; AddressesInUse = 0; UtilizationPercent = 0; PerformanceRating = 'Offline'; CapacityStatus = 'Server Offline' }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Status = 'Online'; TotalScopes = 8; ActiveScopes = 8; ScopesWithIssues = 1; TotalAddresses = 150; AddressesInUse = 117; UtilizationPercent = 78; PerformanceRating = 'Moderate'; CapacityStatus = 'Adequate' }
            )
            ServerNetworkAnalysis     = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; IPAddress = '192.168.1.10'; Status = 'Online'; IsDomainController = $false; TotalScopes = 15; ActiveScopes = 13; InactiveScopes = 2; DNSResolvable = $true; ReverseDNSValid = $true; NetworkHealth = 'Healthy'; DesignNotes = 'Standard Configuration' }
                [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; IPAddress = $null; Status = 'Unreachable'; IsDomainController = $false; TotalScopes = 0; ActiveScopes = 0; InactiveScopes = 0; DNSResolvable = $true; ReverseDNSValid = $false; NetworkHealth = 'Network Issues'; DesignNotes = 'Standard Configuration' }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; IPAddress = '192.168.1.5'; Status = 'Online'; IsDomainController = $true; TotalScopes = 8; ActiveScopes = 8; InactiveScopes = 0; DNSResolvable = $true; ReverseDNSValid = $true; NetworkHealth = 'Healthy'; DesignNotes = 'Domain Controller' }
            )
            # New safe, high-value test data
            DHCPOptions               = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = 'Server-Level'; OptionId = 6; Name = 'DNS Servers'; Value = '192.168.1.2, 192.168.1.3'; VendorClass = ''; UserClass = ''; PolicyName = ''; Level = 'Server'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = 'Server-Level'; OptionId = 15; Name = 'Domain Name'; Value = 'domain.com'; VendorClass = ''; UserClass = ''; PolicyName = ''; Level = 'Server'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = 'Server-Level'; OptionId = 6; Name = 'DNS Servers'; Value = '8.8.8.8, 1.1.1.1'; VendorClass = ''; UserClass = ''; PolicyName = ''; Level = 'Server'; GatheredFrom = 'dc01.domain.com'; GatheredDate = (Get-Date) }
            )
            DHCPClasses               = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Name = 'Microsoft Windows 2000 Options'; Type = 'Vendor'; Data = 'MSFT 5.0'; Description = 'Microsoft Windows 2000 vendor class'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Name = 'Corporate Laptops'; Type = 'User'; Data = 'CORP-LAPTOP'; Description = 'Corporate laptop user class'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Name = 'Microsoft Options'; Type = 'Vendor'; Data = 'MSFT'; Description = 'Standard Microsoft vendor class'; GatheredFrom = 'dc01.domain.com'; GatheredDate = (Get-Date) }
            )
            Superscopes               = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; SuperscopeName = 'Building-A'; ScopeId = '192.168.1.0'; SuperscopeState = 'Active'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; SuperscopeName = 'Building-A'; ScopeId = '192.168.2.0'; SuperscopeState = 'Active'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
            )
            FailoverRelationships     = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Name = 'dhcp01-dhcp02-failover'; PartnerServer = 'dhcp02.domain.com'; Mode = 'LoadBalance'; State = 'Normal'; LoadBalancePercent = 50; MaxClientLeadTime = '01:00:00'; StateSwitchInterval = '00:05:00'; AutoStateTransition = $true; EnableAuth = $true; ScopeCount = 3; ScopeIds = '10.1.0.0, 10.2.0.0, 10.3.0.0'; GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
            )
            ServerStatistics          = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; TotalScopes = 15; ScopesWithDelay = 0; TotalAddresses = 3000; AddressesInUse = 1350; AddressesAvailable = 1650; PercentageInUse = 45; PercentageAvailable = 55; Discovers = 2500; Offers = 2400; Requests = 2350; Acks = 2300; Naks = 50; Declines = 2; Releases = 150; ServerStartTime = (Get-Date).AddDays(-30); GatheredFrom = 'dhcp01.domain.com'; GatheredDate = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; TotalScopes = 8; ScopesWithDelay = 1; TotalAddresses = 1500; AddressesInUse = 1170; AddressesAvailable = 330; PercentageInUse = 78; PercentageAvailable = 22; Discovers = 1200; Offers = 1150; Requests = 1100; Acks = 1050; Naks = 50; Declines = 5; Releases = 80; ServerStartTime = (Get-Date).AddDays(-15); GatheredFrom = 'dc01.domain.com'; GatheredDate = (Get-Date) }
            )
            OptionsAnalysis           = @(
                [PSCustomObject]@{ AnalysisType = 'DHCP Options Configuration'; TotalServersAnalyzed = 2; TotalOptionsConfigured = 8; UniqueOptionTypes = 6; CriticalOptionsCovered = 3; MissingCriticalOptions = @('Option 3 (Router - Default Gateway)', 'Option 51 (Lease Time)', 'Option 66 (Boot Server Host Name)'); OptionIssues = @('Public DNS servers configured in scope Server-Level on dc01.domain.com'); OptionRecommendations = @('Configure missing critical DHCP options for proper client functionality', 'Consider configuring server-level options for common settings') }
            )
            ValidationResults         = [ordered] @{
                CriticalIssues = [ordered] @{
                    PublicDNSWithUpdates = @(
                        [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = 'Server-Level'; Name = 'Server-Level'; State = 'Active'; PercentageInUse = 0; HasIssues = $true; Issues = @('Public DNS servers configured with dynamic updates enabled'); LeaseDurationHours = 0; FailoverPartner = $null }
                    )
                    ServersOffline       = @(
                        [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; ComputerName = 'dhcp02.domain.com'; Status = 'Unreachable'; Version = $null; PingSuccessful = $false; DNSResolvable = $true; DHCPResponding = $false }
                    )
                }
                UtilizationIssues = [ordered] @{
                    HighUtilization     = @(
                        [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; AddressesInUse = 92; AddressesFree = 8; HasIssues = $true; Issues = @('Critical utilization'); LeaseDurationHours = 168; FailoverPartner = $null }
                    )
                    ModerateUtilization = @(
                        [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; AddressesInUse = 170; AddressesFree = 30; HasIssues = $true; Issues = @('High utilization'); LeaseDurationHours = 8; FailoverPartner = $null }
                    )
                }
                WarningIssues = [ordered] @{
                    MissingFailover       = @(
                        [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; HasIssues = $true; Issues = @('No failover configured'); LeaseDurationHours = 8; FailoverPartner = $null }
                        [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('No failover configured'); LeaseDurationHours = 168; FailoverPartner = $null }
                    )
                    ExtendedLeaseDuration = @(
                        [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('Extended lease duration'); LeaseDurationHours = 168; FailoverPartner = $null }
                    )
                    DNSRecordManagement   = @()
                }
                InfoIssues = [ordered] @{
                    MissingDomainName = @()
                    InactiveScopes    = @()
                }
                Summary = [ordered] @{
                    TotalCriticalIssues    = 2
                    TotalUtilizationIssues = 2
                    TotalWarningIssues     = 3
                    TotalInfoIssues        = 0
                    ScopesWithCritical     = 2
                    ScopesWithUtilization  = 2
                    ScopesWithWarnings     = 2
                    ScopesWithInfo         = 0
                }
            }
            TimingStatistics = @(
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Operation = 'Server Total Processing'; StartTime = (Get-Date).AddSeconds(-15); EndTime = (Get-Date).AddSeconds(-10); DurationMs = 5000; DurationSeconds = 5; ItemCount = 15; ItemsPerSecond = 3; Success = $true; Timestamp = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Operation = 'Scope Discovery'; StartTime = (Get-Date).AddSeconds(-15); EndTime = (Get-Date).AddSeconds(-14); DurationMs = 1000; DurationSeconds = 1; ItemCount = 15; ItemsPerSecond = 15; Success = $true; Timestamp = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Operation = 'Scope Statistics'; StartTime = (Get-Date).AddSeconds(-14); EndTime = (Get-Date).AddSeconds(-12); DurationMs = 2000; DurationSeconds = 2; ItemCount = 15; ItemsPerSecond = 7.5; Success = $true; Timestamp = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Operation = 'Server Total Processing'; StartTime = (Get-Date).AddSeconds(-10); EndTime = (Get-Date).AddSeconds(-5); DurationMs = 5000; DurationSeconds = 5; ItemCount = 8; ItemsPerSecond = 1.6; Success = $true; Timestamp = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Operation = 'Scope Discovery'; StartTime = (Get-Date).AddSeconds(-10); EndTime = (Get-Date).AddSeconds(-9); DurationMs = 1000; DurationSeconds = 1; ItemCount = 8; ItemsPerSecond = 8; Success = $true; Timestamp = (Get-Date) }
                [PSCustomObject]@{ ServerName = 'Overall'; Operation = 'Complete DHCP Discovery'; StartTime = (Get-Date).AddSeconds(-20); EndTime = (Get-Date); DurationMs = 20000; DurationSeconds = 20; ItemCount = 3; ItemsPerSecond = 0.15; Success = $true; Timestamp = (Get-Date) }
            )
        }
    }

    # Initialize result structure
    $DHCPSummary = [ordered] @{
        Servers                   = [System.Collections.Generic.List[Object]]::new()
        Scopes                    = [System.Collections.Generic.List[Object]]::new()
        ScopesWithIssues          = [System.Collections.Generic.List[Object]]::new()
        IPv6Scopes                = [System.Collections.Generic.List[Object]]::new()
        IPv6ScopesWithIssues      = [System.Collections.Generic.List[Object]]::new()
        MulticastScopes           = [System.Collections.Generic.List[Object]]::new()
        Reservations              = [System.Collections.Generic.List[Object]]::new()
        Leases                    = [System.Collections.Generic.List[Object]]::new()
        Policies                  = [System.Collections.Generic.List[Object]]::new()
        SecurityFilters           = [System.Collections.Generic.List[Object]]::new()
        ServerSettings            = [System.Collections.Generic.List[Object]]::new()
        NetworkBindings           = [System.Collections.Generic.List[Object]]::new()
        AuditLogs                 = [System.Collections.Generic.List[Object]]::new()
        Databases                 = [System.Collections.Generic.List[Object]]::new()
        Options                   = [System.Collections.Generic.List[Object]]::new()
        Errors                    = [System.Collections.Generic.List[Object]]::new()
        Warnings                  = [System.Collections.Generic.List[Object]]::new()
        # Enhanced analysis collections
        ScopeConflicts            = [System.Collections.Generic.List[Object]]::new()
        PerformanceMetrics        = [System.Collections.Generic.List[Object]]::new()
        SecurityAnalysis          = [System.Collections.Generic.List[Object]]::new()
        BestPracticeViolations    = [System.Collections.Generic.List[Object]]::new()
        CapacityAnalysis          = [System.Collections.Generic.List[Object]]::new()
        NetworkDesignAnalysis     = [System.Collections.Generic.List[Object]]::new()
        BackupAnalysis            = [System.Collections.Generic.List[Object]]::new()
        ScopeRedundancyAnalysis   = [System.Collections.Generic.List[Object]]::new()
        ServerPerformanceAnalysis = [System.Collections.Generic.List[Object]]::new()
        ServerNetworkAnalysis     = [System.Collections.Generic.List[Object]]::new()
        # New safe, high-value collections
        DHCPOptions               = [System.Collections.Generic.List[Object]]::new()
        DHCPClasses               = [System.Collections.Generic.List[Object]]::new()
        Superscopes               = [System.Collections.Generic.List[Object]]::new()
        FailoverRelationships     = [System.Collections.Generic.List[Object]]::new()
        ServerStatistics          = [System.Collections.Generic.List[Object]]::new()
        OptionsAnalysis           = [System.Collections.Generic.List[Object]]::new()
        Statistics                = [ordered] @{}
        ValidationResults         = [ordered] @{}
        TimingStatistics          = [System.Collections.Generic.List[Object]]::new()
    }

    # Get DHCP servers from AD for discovery
    Write-Verbose "Get-WinADDHCPSummary - Discovering DHCP servers in forest"
    try {
        $DHCPServersFromAD = Get-DhcpServerInDC -ErrorAction Stop
        Write-Verbose "Get-WinADDHCPSummary - Found $($DHCPServersFromAD.Count) DHCP servers in AD"
    } catch {
        Add-DHCPError -ServerName 'AD Discovery' -Component 'DHCP Server Discovery' -Operation 'Get-DhcpServerInDC' -ErrorMessage $_.Exception.Message -Severity 'Error'
        return $DHCPSummary
    }

    # Determine which servers to analyze in detail
    if ($ComputerName.Count -eq 0) {
        # If no specific servers provided, analyze all discovered servers
        $ServersToAnalyze = $DHCPServersFromAD.DnsName
        Write-Verbose "Get-WinADDHCPSummary - Will perform detailed analysis on all $($ServersToAnalyze.Count) discovered servers"
    } else {
        # If specific servers provided, only analyze those
        $ServersToAnalyze = $ComputerName
        Write-Verbose "Get-WinADDHCPSummary - Will perform detailed analysis on $($ServersToAnalyze.Count) specified servers"
    }

    # Create lookup for servers to analyze
    $ServersToAnalyzeSet = @{}
    foreach ($Server in $ServersToAnalyze) {
        $ServersToAnalyzeSet[$Server.ToLower()] = $true
    }

    if ($DHCPServersFromAD.Count -eq 0) {
        Add-DHCPError -ServerName 'AD Discovery' -Component 'DHCP Server Discovery' -Operation 'Server Count Check' -ErrorMessage 'No DHCP servers found in Active Directory' -Severity 'Warning'

        # Initialize statistics with zero values for empty environments
        $DHCPSummary.Statistics = [ordered] @{
            TotalServers           = 0
            ServersOnline          = 0
            ServersOffline         = 0
            ServersWithIssues      = 0
            ServersWithoutIssues   = 0
            TotalScopes            = 0
            ScopesActive           = 0
            ScopesInactive         = 0
            ScopesWithIssues       = 0
            ScopesWithoutIssues    = 0
            TotalAddresses         = 0
            AddressesInUse         = 0
            AddressesFree          = 0
            OverallPercentageInUse = 0
        }

        # Initialize empty validation results
        $DHCPSummary.ValidationResults = [ordered] @{
            Summary  = [ordered] @{
                TotalCriticalIssues    = 0
                TotalUtilizationIssues = 0
                TotalWarningIssues     = 0
                TotalInfoIssues        = 0
                ScopesWithCritical     = 0
                ScopesWithUtilization  = 0
                ScopesWithWarnings     = 0
                ScopesWithInfo         = 0
            }
            Critical    = @()
            Utilization = @()
            Warning     = @()
            Info        = @()
        }

        return $DHCPSummary
    }

    # Get forest information for cross-referencing
    $ForestInformation = $null
    if ($Forest -or $IncludeDomains -or $ExcludeDomains -or $IncludeDomainControllers -or $ExcludeDomainControllers) {
        try {
            $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
        } catch {
            Add-DHCPError -ServerName 'Forest Information' -Component 'Forest Discovery' -Operation 'Get-WinADForestDetails' -ErrorMessage $_.Exception.Message -Severity 'Warning'
        }
    }

    # Process each DHCP server (all discovered servers)
    $TotalServers = $DHCPServersFromAD.Count
    $ProcessedServers = 0
    $ServersWithIssues = 0
    $TotalScopes = 0
    $ScopesWithIssues = 0

    # Track overall timing
    $OverallStartTime = Get-Date
    
    foreach ($DHCPServer in $DHCPServersFromAD) {
        $Computer = $DHCPServer.DnsName
        $ProcessedServers++
        Write-Progress -Activity "Processing DHCP Servers" -Status "Processing $Computer ($ProcessedServers of $TotalServers)" -PercentComplete (($ProcessedServers / $TotalServers) * 100) -Id 1

        Write-Verbose "Get-WinADDHCPSummary - Processing DHCP server: $Computer"
        
        # Start server timing
        $ServerStartTime = Get-Date

        # Determine if this server should be analyzed in detail
        $ShouldAnalyze = $ServersToAnalyzeSet[$Computer.ToLower()] -eq $true

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

        # Test connectivity and get server information only for servers to analyze
        if ($ShouldAnalyze) {
            Write-Verbose "Get-WinADDHCPSummary - Performing comprehensive validation for $Computer"
            $ValidationResult = Get-WinDHCPServerInfo -ComputerName $Computer

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

            # If DHCP service is not responding, mark as having issues and continue to next server
            if (-not $ValidationResult.DHCPResponding) {
                Add-DHCPError -ServerName $Computer -Component 'DHCP Service Validation' -Operation 'Service Connectivity Test' -ErrorMessage "DHCP service not responding: $($ValidationResult.ErrorMessage)" -Severity 'Error'
                $ServersWithIssues++
                $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
                continue
            }
        } else {
            # For non-analyzed servers, mark as not tested
            $ServerInfo.Status = 'Not Analyzed'
            $ServerInfo.ErrorMessage = 'Server discovered but not selected for detailed analysis'
            $ServerInfo.PingSuccessful = $null
            $ServerInfo.DNSResolvable = $null
            $ServerInfo.DHCPResponding = $null
            $ServerInfo.IPAddress = $null
            $ServerInfo.ResponseTimeMs = $null
            $ServerInfo.ReverseDNSName = $null
            $ServerInfo.ReverseDNSValid = $null
            $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
            continue
        }

        # Get DHCP scopes
        $ScopeCollectionStart = Get-Date
        try {
            $Scopes = Get-DhcpServerv4Scope -ComputerName $Computer -ErrorAction Stop
            Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName $Computer -Operation 'Scope Discovery' -StartTime $ScopeCollectionStart -ItemCount $Scopes.Count
            $ServerInfo.ScopeCount = $Scopes.Count
            $TotalScopes += $Scopes.Count

            $ActiveScopes = $Scopes | Where-Object { $_.State -eq 'Active' }
            $ServerInfo.ActiveScopeCount = $ActiveScopes.Count
            $ServerInfo.InactiveScopeCount = $Scopes.Count - $ActiveScopes.Count

            Write-Verbose "Get-WinADDHCPSummary - Found $($Scopes.Count) scopes on $Computer"
        } catch {
            Add-DHCPError -ServerName $Computer -Component 'DHCP Scope Discovery' -Operation 'Get-DhcpServerv4Scope' -ErrorMessage $_.Exception.Message -Severity 'Error'
            $ServerInfo.ErrorMessage = $_.Exception.Message
            $ServersWithIssues++
            $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
            continue
        }

        # Process each scope
        $ServerScopesWithIssues = 0
        $ServerTotalAddresses = 0
        $ServerAddressesInUse = 0
        $ServerAddressesFree = 0
        $ScopeCounter = 0

        foreach ($Scope in $Scopes) {
            $ScopeCounter++
            Write-Progress -Activity "Processing DHCP Servers" -Status "Processing $Computer ($ProcessedServers of $TotalServers)" -PercentComplete (($ProcessedServers / $TotalServers) * 100) -Id 1
            Write-Progress -Activity "Processing Scopes on $Computer" -Status "Scope $($Scope.ScopeId) ($ScopeCounter of $($Scopes.Count))" -PercentComplete (($ScopeCounter / $Scopes.Count) * 100) -ParentId 1 -Id 2
            Write-Verbose "Get-WinADDHCPSummary - Processing scope $($Scope.ScopeId) on $Computer"

            $ScopeObject = [ordered] @{
                ServerName                 = $Computer
                ScopeId                    = $Scope.ScopeId
                Name                       = $Scope.Name
                Description                = $Scope.Description
                State                      = $Scope.State
                SubnetMask                 = $Scope.SubnetMask
                StartRange                 = $Scope.StartRange
                EndRange                   = $Scope.EndRange
                LeaseDuration              = $Scope.LeaseDuration
                LeaseDurationHours         = $Scope.LeaseDuration.TotalHours
                Type                       = $Scope.Type
                SuperscopeName             = $Scope.SuperscopeName
                AddressesInUse             = 0
                AddressesFree              = 0
                PercentageInUse            = 0
                Reserved                   = 0
                HasIssues                  = $false
                Issues                     = [System.Collections.Generic.List[string]]::new()
                # DNS Configuration fields
                DomainName                 = $null
                DomainNameOption           = $null
                DNSServers                 = $null
                UpdateDnsRRForOlderClients = $null
                DeleteDnsRROnLeaseExpiry   = $null
                DynamicUpdates             = $null
                DNSSettings                = $null
                FailoverPartner            = $null
                GatheredFrom               = $Computer
                GatheredDate               = Get-Date
            }

            # Get scope statistics
            $StatsStart = Get-Date
            try {
                $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName $Computer -Operation 'Scope Statistics' -StartTime $StatsStart -ItemCount 1
                $ScopeObject.AddressesInUse = $ScopeStats.AddressesInUse
                $ScopeObject.AddressesFree = $ScopeStats.AddressesFree
                $ScopeObject.PercentageInUse = [Math]::Round($ScopeStats.PercentageInUse, 2)
                $ScopeObject.Reserved = $ScopeStats.Reserved

                # Calculate total addresses for server-level statistics
                $ScopeTotalAddresses = ($ScopeStats.AddressesInUse + $ScopeStats.AddressesFree)
                $ServerTotalAddresses += $ScopeTotalAddresses
                $ServerAddressesInUse += $ScopeStats.AddressesInUse
                $ServerAddressesFree += $ScopeStats.AddressesFree

                # Enhanced scope analysis and best practice validation
                $ScopeObject.TotalAddresses = $ScopeTotalAddresses

                # Calculate scope efficiency metrics
                $ScopeRange = [System.Net.IPAddress]::Parse($Scope.EndRange).GetAddressBytes()[3] - [System.Net.IPAddress]::Parse($Scope.StartRange).GetAddressBytes()[3] + 1
                $ScopeObject.DefinedRange = $ScopeRange
                $ScopeObject.UtilizationEfficiency = if ($ScopeRange -gt 0) { [Math]::Round(($ScopeTotalAddresses / $ScopeRange) * 100, 2) } else { 0 }

                # Best practice validations
                $BestPracticeIssues = [System.Collections.Generic.List[string]]::new()

                # Check scope size best practices
                if ($ScopeTotalAddresses -lt 10) {
                    $BestPracticeIssues.Add("Very small scope size ($ScopeTotalAddresses addresses) - consider consolidation")
                } elseif ($ScopeTotalAddresses -gt 1000) {
                    $BestPracticeIssues.Add("Very large scope size ($ScopeTotalAddresses addresses) - consider segmentation")
                }

                # Check utilization thresholds
                if ($ScopeObject.PercentageInUse -gt 95) {
                    $BestPracticeIssues.Add("Critical utilization level ($($ScopeObject.PercentageInUse)%) - immediate expansion needed")
                } elseif ($ScopeObject.PercentageInUse -gt 80) {
                    $BestPracticeIssues.Add("High utilization level ($($ScopeObject.PercentageInUse)%) - expansion planning recommended")
                } elseif ($ScopeObject.PercentageInUse -lt 5 -and $Scope.State -eq 'Active') {
                    $BestPracticeIssues.Add("Very low utilization ($($ScopeObject.PercentageInUse)%) - scope may be unnecessary")
                }

                # Add best practice issues to main issues list
                foreach ($Issue in $BestPracticeIssues) {
                    $ScopeObject.Issues.Add($Issue)
                    if ($Issue -like "*Critical*" -or $Issue -like "*immediate*") {
                        $ScopeObject.HasIssues = $true
                    }
                }

                Write-Verbose "Get-WinADDHCPSummary - Scope $($Scope.ScopeId) statistics: Total=$ScopeTotalAddresses, InUse=$($ScopeStats.AddressesInUse), Free=$($ScopeStats.AddressesFree), Utilization=$($ScopeObject.PercentageInUse)%"
            } catch {
                Add-DHCPError -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'Scope Statistics' -Operation 'Get-DhcpServerv4ScopeStatistics' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }

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

            # Check DNS settings
            try {
                $DNSSettings = Get-DhcpServerv4DnsSetting -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                $ScopeObject.DNSSettings = $DNSSettings

                # Populate DNS configuration fields
                $ScopeObject.DynamicUpdates = $DNSSettings.DynamicUpdates
                $ScopeObject.UpdateDnsRRForOlderClients = $DNSSettings.UpdateDnsRRForOlderClients
                $ScopeObject.DeleteDnsRROnLeaseExpiry = $DNSSettings.DeleteDnsRROnLeaseExpiry

                # Get DHCP options for this scope
                try {
                    $Options = Get-DhcpServerv4OptionValue -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                    $Option6 = $Options | Where-Object { $_.OptionId -eq 6 }  # DNS Servers
                    $Option15 = $Options | Where-Object { $_.OptionId -eq 15 } # Domain Name

                    # Populate option fields
                    $ScopeObject.DNSServers = if ($Option6 -and $Option6.Value) { $Option6.Value -join ', ' } else { $null }
                    $ScopeObject.DomainNameOption = if ($Option15 -and $Option15.Value) { $Option15.Value } else { $null }
                    $ScopeObject.DomainName = $ScopeObject.DomainNameOption

                    # Check for dynamic DNS updates with public DNS servers
                    if ($DNSSettings.DynamicUpdates -ne 'Never') {
                        if ($Option6 -and $Option6.Value) {
                            # Check for non-private DNS servers (similar to your validator's ^10. check)
                            $NonPrivateDNS = $Option6.Value | Where-Object { $_ -notmatch "^10\." -and $_ -notmatch "^192\.168\." -and $_ -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\." }
                            if ($NonPrivateDNS) {
                                $ScopeObject.Issues.Add("DNS updates enabled with non-private DNS servers: $($NonPrivateDNS -join ', ')")
                                $ScopeObject.HasIssues = $true
                            }
                        }

                        # Enhanced DNS update validation (from your validator)
                        if (-not $DNSSettings.UpdateDnsRRForOlderClients -and -not $DNSSettings.DeleteDnsRROnLeaseExpiry) {
                            $ScopeObject.Issues.Add("Both UpdateDnsRRForOlderClients and DeleteDnsRROnLeaseExpiry are disabled")
                            $ScopeObject.HasIssues = $true
                        } elseif (-not $DNSSettings.UpdateDnsRRForOlderClients) {
                            $ScopeObject.Issues.Add("UpdateDnsRRForOlderClients is disabled")
                            $ScopeObject.HasIssues = $true
                        } elseif (-not $DNSSettings.DeleteDnsRROnLeaseExpiry) {
                            $ScopeObject.Issues.Add("DeleteDnsRROnLeaseExpiry is disabled")
                            $ScopeObject.HasIssues = $true
                        }

                        if (-not $Option15 -or [string]::IsNullOrEmpty($Option15.Value)) {
                            $ScopeObject.Issues.Add("Domain name option (015) is empty")
                            $ScopeObject.HasIssues = $true
                        }
                    }
                } catch {
                    Add-DHCPError -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Options' -Operation 'Get-DhcpServerv4OptionValue' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }
            } catch {
                Add-DHCPError -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DNS Settings' -Operation 'Get-DhcpServerv4DnsSetting' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }

            # Check DHCP failover configuration
            try {
                $Failover = Get-DhcpServerv4Failover -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction SilentlyContinue
                if ($Failover) {
                    $ScopeObject.FailoverPartner = $Failover.PartnerServer
                } else {
                    $ScopeObject.Issues.Add("DHCP Failover not configured")
                    $ScopeObject.HasIssues = $true
                }
            } catch {
                # Failover may not be configured, which is not necessarily an error
                Write-Verbose "Get-WinADDHCPSummary - No failover configuration for scope $($Scope.ScopeId) on $Computer"
            }

            if ($ScopeObject.HasIssues) {
                $ServerScopesWithIssues++
                $ScopesWithIssues++
                $DHCPSummary.ScopesWithIssues.Add([PSCustomObject]$ScopeObject)
            }

            $DHCPSummary.Scopes.Add([PSCustomObject]$ScopeObject)
        }

        # Clear scope-level progress when done with this server's scopes
        Write-Progress -Activity "Processing Scopes on $Computer" -Completed -Id 2

        # Update server statistics
        $ServerInfo.ScopesWithIssues = $ServerScopesWithIssues
        $ServerInfo.TotalAddresses = $ServerTotalAddresses
        $ServerInfo.AddressesInUse = $ServerAddressesInUse
        $ServerInfo.AddressesFree = $ServerAddressesFree
        if ($ServerTotalAddresses -gt 0) {
            $ServerInfo.PercentageInUse = [Math]::Round(($ServerAddressesInUse / $ServerTotalAddresses) * 100, 2)
        }

        if ($ServerScopesWithIssues -gt 0) {
            $ServersWithIssues++
        }

        # DHCP Authorization Analysis
        try {
            Write-Verbose "Get-WinADDHCPSummary - Checking DHCP authorization for $Computer"
            $AuthorizedServers = Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object { $_.DnsName -eq $Computer -or $_.IPAddress -eq $Computer }
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
            Write-Verbose "Get-WinADDHCPSummary - Performing security analysis for $Computer"

            # Check for DHCP service account configuration
            $DHCPService = Get-WmiObject -Class Win32_Service -Filter "Name='DHCPServer'" -ComputerName $Computer -ErrorAction SilentlyContinue
            if ($DHCPService) {
                if ($DHCPService.StartName -eq "LocalSystem") {
                    $ServerInfo.Issues.Add("DHCP service running as LocalSystem - consider using dedicated service account")
                }
            }

            # Check for common security misconfigurations
            $DHCPAuditSettings = Get-DhcpServerAuditLog -ComputerName $Computer -ErrorAction SilentlyContinue
            if ($DHCPAuditSettings) {
                if (-not $DHCPAuditSettings.Enable) {
                    $ServerInfo.Issues.Add("DHCP audit logging is disabled - enable for security monitoring")
                    $ServerInfo.HasIssues = $true
                }
            }

        } catch {
            Write-Warning "Get-WinADDHCPSummary - Security analysis failed for $Computer`: $($_.Exception.Message)"
        }

        # Add the successfully processed server to the collection
        $DHCPSummary.Servers.Add([PSCustomObject]$ServerInfo)
        
        # Track server processing time
        Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName $Computer -Operation 'Server Total Processing' -StartTime $ServerStartTime -ItemCount $ServerInfo.ScopeCount
        
        Write-Verbose "Get-WinADDHCPSummary - Server $Computer processing completed: Scopes=$($ServerInfo.ScopeCount), Total Addresses=$($ServerInfo.TotalAddresses), Utilization=$($ServerInfo.PercentageInUse)%"

        # Get audit log information
        if ($Extended) {
            try {
                $AuditLog = Get-DhcpServerAuditLog -ComputerName $Computer -ErrorAction Stop
                $AuditLogObject = [PSCustomObject] @{
                    ServerName        = $Computer
                    DiskCheckInterval = $AuditLog.DiskCheckInterval
                    Enable            = $AuditLog.Enable
                    MaxMBFileSize     = $AuditLog.MaxMBFileSize
                    MinMBDiskSpace    = $AuditLog.MinMBDiskSpace
                    Path              = $AuditLog.Path
                    GatheredFrom      = $Computer
                    GatheredDate      = Get-Date
                }
                $DHCPSummary.AuditLogs.Add($AuditLogObject)
            } catch {
                Add-DHCPError -ServerName $Computer -Component 'Audit Log Configuration' -Operation 'Get-DhcpServerAuditLog' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }

            # Get database information
            try {
                $Database = Get-DhcpServerDatabase -ComputerName $Computer -ErrorAction Stop
                $DatabaseObject = [PSCustomObject] @{
                    ServerName             = $Computer
                    FileName               = $Database.FileName
                    BackupPath             = $Database.BackupPath
                    BackupIntervalMinutes  = $Database.'BackupInterval(m)'
                    CleanupIntervalMinutes = $Database.'CleanupInterval(m)'
                    LoggingEnabled         = $Database.LoggingEnabled
                    RestoreFromBackup      = $Database.RestoreFromBackup
                    GatheredFrom           = $Computer
                    GatheredDate           = Get-Date
                }
                $DHCPSummary.Databases.Add($DatabaseObject)
            } catch {
                Add-DHCPError -ServerName $Computer -Component 'Database Configuration' -Operation 'Get-DhcpServerDatabase' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }

            # Get enhanced server configuration (with comprehensive error handling)
            try {
                Write-Verbose "Get-WinADDHCPSummary - Gathering enhanced server configuration for $Computer"

                # Server settings (may require elevated permissions)
                try {
                    $ServerSettings = Get-DhcpServerSetting -ComputerName $Computer -ErrorAction Stop
                    $ServerSettingsObject = [PSCustomObject] @{
                        ServerName                = $Computer
                        ActivatePolicies          = if ($null -ne $ServerSettings.ActivatePolicies) { $ServerSettings.ActivatePolicies } else { $false }
                        ConflictDetectionAttempts = if ($ServerSettings.ConflictDetectionAttempts) { $ServerSettings.ConflictDetectionAttempts } else { 0 }
                        DynamicBootp              = if ($null -ne $ServerSettings.DynamicBootp) { $ServerSettings.DynamicBootp } else { $false }
                        IsAuthorized              = if ($null -ne $ServerSettings.IsAuthorized) { $ServerSettings.IsAuthorized } else { $false }
                        IsDomainJoined            = if ($null -ne $ServerSettings.IsDomainJoined) { $ServerSettings.IsDomainJoined } else { $false }
                        NapEnabled                = if ($null -ne $ServerSettings.NapEnabled) { $ServerSettings.NapEnabled } else { $false }
                        NpsUnreachableAction      = $ServerSettings.NpsUnreachableAction
                        RestoreStatus             = $ServerSettings.RestoreStatus
                        GatheredFrom              = $Computer
                        GatheredDate              = Get-Date
                    }
                    $DHCPSummary.ServerSettings.Add($ServerSettingsObject)
                    Write-Verbose "Get-WinADDHCPSummary - Server settings collected for $Computer"
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*access*denied*" -or $ErrorMessage -like "*permission*") {
                        Add-DHCPError -ServerName $Computer -Component 'Server Settings' -Operation 'Get-DhcpServerSetting' -ErrorMessage "Insufficient permissions: $ErrorMessage" -Severity 'Warning'
                    } else {
                        Add-DHCPError -ServerName $Computer -Component 'Server Settings' -Operation 'Get-DhcpServerSetting' -ErrorMessage $ErrorMessage -Severity 'Warning'
                    }
                }

                # Network bindings (should be accessible with basic DHCP permissions)
                try {
                    $Bindings = Get-DhcpServerv4Binding -ComputerName $Computer -ErrorAction Stop
                    if ($Bindings -and $Bindings.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($Bindings.Count) network bindings on $Computer"

                        foreach ($Binding in $Bindings) {
                            $BindingObject = [PSCustomObject] @{
                                ServerName     = $Computer
                                InterfaceIndex = if ($Binding.InterfaceIndex) { $Binding.InterfaceIndex } else { 0 }
                                InterfaceAlias = $Binding.InterfaceAlias
                                IPAddress      = $Binding.IPAddress
                                SubnetMask     = $Binding.SubnetMask
                                State          = if ($null -ne $Binding.State) { $Binding.State } else { 'Unknown' }
                                GatheredFrom   = $Computer
                                GatheredDate   = Get-Date
                            }
                            $DHCPSummary.NetworkBindings.Add($BindingObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No network bindings found on $Computer"
                    }
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'Network Bindings' -Operation 'Get-DhcpServerv4Binding' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                # Security filters (may not be configured on all servers)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking security filters on $Computer"
                    $FilterList = Get-DhcpServerv4FilterList -ComputerName $Computer -ErrorAction Stop

                    $SecurityFilterObject = [PSCustomObject] @{
                        ServerName    = $Computer
                        Allow         = if ($FilterList.Allow) { $FilterList.Allow } else { $false }
                        Deny          = if ($FilterList.Deny) { $FilterList.Deny } else { $false }
                        FilteringMode = if ($FilterList.Allow -and $FilterList.Deny) { 'Both' } elseif ($FilterList.Allow) { 'Allow' } elseif ($FilterList.Deny) { 'Deny' } else { 'None' }
                        GatheredFrom  = $Computer
                        GatheredDate  = Get-Date
                    }
                    $DHCPSummary.SecurityFilters.Add($SecurityFilterObject)
                    Write-Verbose "Get-WinADDHCPSummary - Security filter mode on $Computer`: $($SecurityFilterObject.FilteringMode)"
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*") {
                        Add-DHCPError -ServerName $Computer -Component 'Security Filters' -Operation 'Get-DhcpServerv4FilterList' -ErrorMessage "Security filtering not available (normal for older DHCP servers): $ErrorMessage" -Severity 'Warning'
                    } else {
                        Add-DHCPError -ServerName $Computer -Component 'Security Filters' -Operation 'Get-DhcpServerv4FilterList' -ErrorMessage $ErrorMessage -Severity 'Warning'
                    }

                    # Add a default entry indicating no filtering
                    $SecurityFilterObject = [PSCustomObject] @{
                        ServerName    = $Computer
                        Allow         = $false
                        Deny          = $false
                        FilteringMode = 'Not Available'
                        GatheredFrom  = $Computer
                        GatheredDate  = Get-Date
                    }
                    $DHCPSummary.SecurityFilters.Add($SecurityFilterObject)
                }

                # IPv6 Scopes (with robust error handling since IPv6 DHCP is rarely deployed)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking for IPv6 DHCP support on $Computer"

                    # Test if IPv6 DHCP service is available first
                    $IPv6Scopes = $null
                    $IPv6Supported = $false

                    try {
                        $IPv6Scopes = Get-DhcpServerv6Scope -ComputerName $Computer -ErrorAction Stop
                        $IPv6Supported = $true
                        Write-Verbose "Get-WinADDHCPSummary - IPv6 DHCP service detected on $Computer"
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        # Common error patterns for IPv6 not supported/configured
                        if ($ErrorMessage -like "*not found*" -or
                            $ErrorMessage -like "*not supported*" -or
                            $ErrorMessage -like "*service*" -or
                            $ErrorMessage -like "*RPC*" -or
                            $ErrorMessage -like "*access*denied*") {
                            Add-DHCPError -ServerName $Computer -Component 'IPv6 DHCP Service' -Operation 'Get-DhcpServerv6Scope' -ErrorMessage "IPv6 DHCP not available (normal): $ErrorMessage" -Severity 'Warning'
                        } else {
                            Add-DHCPError -ServerName $Computer -Component 'IPv6 DHCP Service' -Operation 'Get-DhcpServerv6Scope' -ErrorMessage $ErrorMessage -Severity 'Warning'
                        }
                    }

                    if ($IPv6Supported -and $IPv6Scopes -and $IPv6Scopes.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($IPv6Scopes.Count) IPv6 scopes on $Computer"

                        foreach ($IPv6Scope in $IPv6Scopes) {
                            Write-Verbose "Get-WinADDHCPSummary - Processing IPv6 scope $($IPv6Scope.Prefix) on $Computer"

                            $IPv6ScopeObject = [ordered] @{
                                ServerName        = $Computer
                                Prefix            = $IPv6Scope.Prefix
                                Name              = $IPv6Scope.Name
                                Description       = $IPv6Scope.Description
                                State             = $IPv6Scope.State
                                Preference        = $IPv6Scope.Preference
                                ValidLifetime     = $IPv6Scope.ValidLifetime
                                PreferredLifetime = $IPv6Scope.PreferredLifetime
                                T1                = $IPv6Scope.T1
                                T2                = $IPv6Scope.T2
                                AddressesInUse    = 0
                                AddressesFree     = 0
                                PercentageInUse   = 0
                                HasIssues         = $false
                                Issues            = [System.Collections.Generic.List[string]]::new()
                                GatheredFrom      = $Computer
                                GatheredDate      = Get-Date
                            }

                            # Get IPv6 scope statistics (with additional error handling)
                            try {
                                $IPv6Stats = Get-DhcpServerv6ScopeStatistics -ComputerName $Computer -Prefix $IPv6Scope.Prefix -ErrorAction Stop
                                $IPv6ScopeObject.AddressesInUse = if ($IPv6Stats.AddressesInUse) { $IPv6Stats.AddressesInUse } else { 0 }
                                $IPv6ScopeObject.AddressesFree = if ($IPv6Stats.AddressesFree) { $IPv6Stats.AddressesFree } else { 0 }
                                $IPv6ScopeObject.PercentageInUse = if ($IPv6Stats.PercentageInUse) { [Math]::Round($IPv6Stats.PercentageInUse, 2) } else { 0 }
                                Write-Verbose "Get-WinADDHCPSummary - IPv6 scope $($IPv6Scope.Prefix) utilization: $($IPv6ScopeObject.PercentageInUse)%"
                            } catch {
                                Add-DHCPError -ServerName $Computer -ScopeId $IPv6Scope.Prefix -Component 'IPv6 Scope Statistics' -Operation 'Get-DhcpServerv6ScopeStatistics' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                                $IPv6ScopeObject.Issues.Add("Unable to retrieve IPv6 scope statistics")
                                $IPv6ScopeObject.HasIssues = $true
                            }

                            # IPv6 scope validation (basic checks since IPv6 DHCP is different)
                            if ($IPv6Scope.State -eq 'InActive') {
                                $IPv6ScopeObject.Issues.Add("IPv6 scope is inactive")
                                $IPv6ScopeObject.HasIssues = $true
                            }

                            # Check for reasonable lifetimes (IPv6 specific)
                            if ($IPv6Scope.ValidLifetime -and $IPv6Scope.ValidLifetime.TotalDays -gt 30) {
                                $IPv6ScopeObject.Issues.Add("Very long valid lifetime: $([Math]::Round($IPv6Scope.ValidLifetime.TotalDays, 1)) days")
                                $IPv6ScopeObject.HasIssues = $true
                            }

                            if ($IPv6ScopeObject.HasIssues) {
                                $DHCPSummary.IPv6ScopesWithIssues.Add([PSCustomObject]$IPv6ScopeObject)
                            }

                            $DHCPSummary.IPv6Scopes.Add([PSCustomObject]$IPv6ScopeObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No IPv6 scopes found on $Computer (IPv6 DHCP not deployed)"
                    }
                } catch {
                    # This catch should rarely be reached due to inner try-catch, but provides final safety net
                    Add-DHCPError -ServerName $Computer -Component 'IPv6 DHCP Analysis' -Operation 'IPv6 Overall Processing' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                # Multicast scopes (rarely used - handle gracefully)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking for multicast DHCP scopes on $Computer"
                    $MulticastScopes = Get-DhcpServerv4MulticastScope -ComputerName $Computer -ErrorAction Stop

                    if ($MulticastScopes -and $MulticastScopes.Count -gt 0) {
                        Write-Verbose "Get-WinADDHCPSummary - Found $($MulticastScopes.Count) multicast scopes on $Computer"

                        foreach ($MulticastScope in $MulticastScopes) {
                            Write-Verbose "Get-WinADDHCPSummary - Processing multicast scope $($MulticastScope.Name) on $Computer"

                            $MulticastScopeObject = [PSCustomObject] @{
                                ServerName      = $Computer
                                Name            = $MulticastScope.Name
                                StartRange      = $MulticastScope.StartRange
                                EndRange        = $MulticastScope.EndRange
                                Description     = $MulticastScope.Description
                                State           = $MulticastScope.State
                                Ttl             = $MulticastScope.Ttl
                                ExpiryTime      = $MulticastScope.ExpiryTime
                                LeaseDuration   = $MulticastScope.LeaseDuration
                                AddressesInUse  = 0
                                AddressesFree   = 0
                                PercentageInUse = 0
                                GatheredFrom    = $Computer
                                GatheredDate    = Get-Date
                            }

                            # Get multicast scope statistics (with error handling)
                            try {
                                $MulticastStats = Get-DhcpServerv4MulticastScopeStatistics -ComputerName $Computer -Name $MulticastScope.Name -ErrorAction Stop
                                $MulticastScopeObject.AddressesInUse = if ($MulticastStats.AddressesInUse) { $MulticastStats.AddressesInUse } else { 0 }
                                $MulticastScopeObject.AddressesFree = if ($MulticastStats.AddressesFree) { $MulticastStats.AddressesFree } else { 0 }
                                $MulticastScopeObject.PercentageInUse = if ($MulticastStats.PercentageInUse) { [Math]::Round($MulticastStats.PercentageInUse, 2) } else { 0 }
                                Write-Verbose "Get-WinADDHCPSummary - Multicast scope $($MulticastScope.Name) utilization: $($MulticastScopeObject.PercentageInUse)%"
                            } catch {
                                Add-DHCPError -ServerName $Computer -ScopeId $MulticastScope.Name -Component 'Multicast Scope Statistics' -Operation 'Get-DhcpServerv4MulticastScopeStatistics' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                            }

                            $DHCPSummary.MulticastScopes.Add($MulticastScopeObject)
                        }
                    } else {
                        Write-Verbose "Get-WinADDHCPSummary - No multicast scopes found on $Computer (multicast DHCP not configured)"
                    }
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*") {
                        Add-DHCPError -ServerName $Computer -Component 'Multicast DHCP' -Operation 'Get-DhcpServerv4MulticastScope' -ErrorMessage "Multicast DHCP not available (normal): $ErrorMessage" -Severity 'Warning'
                    } else {
                        Add-DHCPError -ServerName $Computer -Component 'Multicast DHCP' -Operation 'Get-DhcpServerv4MulticastScope' -ErrorMessage $ErrorMessage -Severity 'Warning'
                    }
                }

                # DHCP Policies (advanced feature - may not be available on all DHCP servers)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Checking for DHCP policies on $Computer"

                    # Add more granular verbose messages to track where it might be hanging
                    Write-Verbose "Get-WinADDHCPSummary - Attempting to enumerate DHCP policies on $Computer..."

                    try {
                        $Policies = Get-DhcpServerv4Policy -ComputerName $Computer -ErrorAction Stop
                        Write-Verbose "Get-WinADDHCPSummary - Successfully retrieved policy list from $Computer"

                        if ($Policies -and $Policies.Count -gt 0) {
                            Write-Verbose "Get-WinADDHCPSummary - Found $($Policies.Count) DHCP policies on $Computer - starting individual processing"

                            $PolicyCounter = 0
                            foreach ($Policy in $Policies) {
                                $PolicyCounter++
                                try {
                                    Write-Verbose "Get-WinADDHCPSummary - Processing policy [$PolicyCounter/$($Policies.Count)]: '$($Policy.Name)' on $Computer"

                                    # Add a check for potentially problematic policy properties
                                    $PolicyConditionText = if ($Policy.Condition) {
                                        if ($Policy.Condition.ToString().Length -gt 100) {
                                            "Complex condition (${($Policy.Condition.ToString().Length)} chars)"
                                        } else {
                                            $Policy.Condition.ToString()
                                        }
                                    } else {
                                        "No condition"
                                    }

                                    Write-Verbose "Get-WinADDHCPSummary - Policy '$($Policy.Name)' details - Enabled: $($Policy.Enabled), Order: $($Policy.ProcessingOrder), Condition: $PolicyConditionText"

                                    $PolicyObject = [PSCustomObject] @{
                                        ServerName      = $Computer
                                        Name            = $Policy.Name
                                        ScopeId         = $Policy.ScopeId
                                        Description     = $Policy.Description
                                        Enabled         = if ($Policy.Enabled) { $Policy.Enabled } else { $false }
                                        ProcessingOrder = if ($Policy.ProcessingOrder) { $Policy.ProcessingOrder } else { 0 }
                                        Condition       = $PolicyConditionText
                                        GatheredFrom    = $Computer
                                        GatheredDate    = Get-Date
                                    }
                                    $DHCPSummary.Policies.Add($PolicyObject)
                                    Write-Verbose "Get-WinADDHCPSummary - Successfully processed policy '$($Policy.Name)' on $Computer"
                                } catch {
                                    Add-DHCPError -ServerName $Computer -Component 'DHCP Policy Processing' -Operation "Individual Policy: $($Policy.Name)" -ErrorMessage $_.Exception.Message -Severity 'Warning'
                                    Write-Verbose "Get-WinADDHCPSummary - Continuing with next policy despite error..."
                                }
                            }
                            Write-Verbose "Get-WinADDHCPSummary - Completed processing all $($Policies.Count) policies on $Computer"
                        } else {
                            Write-Verbose "Get-WinADDHCPSummary - No DHCP policies configured on $Computer"
                        }
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Verbose "Get-WinADDHCPSummary - Policy enumeration failed on $Computer with error: $ErrorMessage"

                        if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*" -or $ErrorMessage -like "*not available*") {
                            Add-DHCPError -ServerName $Computer -Component 'DHCP Policies' -Operation 'Get-DhcpServerv4Policy' -ErrorMessage "DHCP policies not available (requires Windows Server 2012+): $ErrorMessage" -Severity 'Warning'
                        } elseif ($ErrorMessage -like "*RPC*" -or $ErrorMessage -like "*timeout*" -or $ErrorMessage -like "*network*") {
                            Add-DHCPError -ServerName $Computer -Component 'DHCP Policies' -Operation 'Get-DhcpServerv4Policy' -ErrorMessage "Network/RPC connectivity issue: $ErrorMessage" -Severity 'Error'
                        } elseif ($ErrorMessage -like "*access*denied*" -or $ErrorMessage -like "*permission*") {
                            Add-DHCPError -ServerName $Computer -Component 'DHCP Policies' -Operation 'Get-DhcpServerv4Policy' -ErrorMessage "Access denied - insufficient permissions: $ErrorMessage" -Severity 'Warning'
                        } else {
                            Add-DHCPError -ServerName $Computer -Component 'DHCP Policies' -Operation 'Get-DhcpServerv4Policy' -ErrorMessage $ErrorMessage -Severity 'Error'
                        }
                    }

                    Write-Verbose "Get-WinADDHCPSummary - DHCP policy processing completed for $Computer"
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'DHCP Policy Processing' -Operation 'Overall Policy Processing' -ErrorMessage $_.Exception.Message -Severity 'Error'
                }

                # Reservations analysis for each scope
                Write-Verbose "Get-WinADDHCPSummary - Starting reservations analysis for $($Scopes.Count) scopes on $Computer"
                $ScopeReservationCounter = 0
                foreach ($Scope in $Scopes) {
                    $ScopeReservationCounter++
                    Write-Verbose "Get-WinADDHCPSummary - Processing reservations for scope [$ScopeReservationCounter/$($Scopes.Count)]: $($Scope.ScopeId) on $Computer"

                    try {
                        $Reservations = Get-DhcpServerv4Reservation -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        Write-Verbose "Get-WinADDHCPSummary - Found $($Reservations.Count) reservations in scope $($Scope.ScopeId) on $Computer"

                        foreach ($Reservation in $Reservations) {
                            $ReservationObject = [PSCustomObject] @{
                                ServerName   = $Computer
                                ScopeId      = $Scope.ScopeId
                                IPAddress    = $Reservation.IPAddress
                                ClientId     = $Reservation.ClientId
                                Name         = $Reservation.Name
                                Description  = $Reservation.Description
                                Type         = $Reservation.Type
                                GatheredFrom = $Computer
                                GatheredDate = Get-Date
                            }
                            $DHCPSummary.Reservations.Add($ReservationObject)
                        }
                    } catch {
                        Add-DHCPError -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Reservations' -Operation 'Get-DhcpServerv4Reservation' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                    }

                    # Active leases analysis (sample for high utilization scopes)
                    try {
                        Write-Verbose "Get-WinADDHCPSummary - Checking lease information for scope $($Scope.ScopeId) on $Computer"
                        $CurrentScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        if ($Scope.State -eq 'Active' -and $CurrentScopeStats.PercentageInUse -gt 75) {
                            Write-Verbose "Get-WinADDHCPSummary - High utilization scope $($Scope.ScopeId) ($($CurrentScopeStats.PercentageInUse)%) - collecting lease sample on $Computer"
                            $Leases = Get-DhcpServerv4Lease -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop | Select-Object -First 100
                            Write-Verbose "Get-WinADDHCPSummary - Retrieved $($Leases.Count) lease samples for scope $($Scope.ScopeId) on $Computer"

                            foreach ($Lease in $Leases) {
                                $LeaseObject = [PSCustomObject] @{
                                    ServerName      = $Computer
                                    ScopeId         = $Scope.ScopeId
                                    IPAddress       = $Lease.IPAddress
                                    AddressState    = $Lease.AddressState
                                    ClientId        = $Lease.ClientId
                                    HostName        = $Lease.HostName
                                    LeaseExpiryTime = $Lease.LeaseExpiryTime
                                    ProbationEnds   = $Lease.ProbationEnds
                                    GatheredFrom    = $Computer
                                    GatheredDate    = Get-Date
                                }
                                $DHCPSummary.Leases.Add($LeaseObject)
                            }
                        } else {
                            Write-Verbose "Get-WinADDHCPSummary - Scope $($Scope.ScopeId) on $Computer - utilization $($CurrentScopeStats.PercentageInUse)% (below threshold for lease collection)"
                        }
                    } catch {
                        Add-DHCPError -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Leases' -Operation 'Get-DhcpServerv4Lease' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                    }

                    # Enhanced options collection
                    Write-Verbose "Get-WinADDHCPSummary - Collecting DHCP options for scope $($Scope.ScopeId) on $Computer"
                    try {
                        $ScopeOptions = Get-DhcpServerv4OptionValue -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
                        Write-Verbose "Get-WinADDHCPSummary - Found $($ScopeOptions.Count) options for scope $($Scope.ScopeId) on $Computer"

                        foreach ($Option in $ScopeOptions) {
                            $OptionObject = [PSCustomObject] @{
                                ServerName   = $Computer
                                ScopeId      = $Scope.ScopeId
                                OptionId     = $Option.OptionId
                                Name         = $Option.Name
                                Value        = ($Option.Value -join ', ')
                                VendorClass  = $Option.VendorClass
                                UserClass    = $Option.UserClass
                                PolicyName   = $Option.PolicyName
                                GatheredFrom = $Computer
                                GatheredDate = Get-Date
                            }
                            $DHCPSummary.Options.Add($OptionObject)
                        }
                    } catch {
                        Add-DHCPError -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Options Collection' -Operation 'Get-DhcpServerv4OptionValue' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                    }
                }
                Write-Verbose "Get-WinADDHCPSummary - Completed reservations and options analysis for all scopes on $Computer"

                # NEW: Collect additional safe, high-value data
                Write-Verbose "Get-WinADDHCPSummary - Collecting enhanced DHCP configuration data for $Computer"

                # DHCP Server Options (global/server-level)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Collecting server-level DHCP options for $Computer"
                    $ServerOptions = Get-DhcpServerv4OptionValue -ComputerName $Computer -All -ErrorAction Stop
                    foreach ($Option in $ServerOptions) {
                        $ServerOptionObject = [PSCustomObject] @{
                            ServerName   = $Computer
                            ScopeId      = 'Server-Level'
                            OptionId     = $Option.OptionId
                            Name         = $Option.Name
                            Value        = ($Option.Value -join ', ')
                            VendorClass  = $Option.VendorClass
                            UserClass    = $Option.UserClass
                            PolicyName   = $Option.PolicyName
                            Level        = 'Server'
                            GatheredFrom = $Computer
                            GatheredDate = Get-Date
                        }
                        $DHCPSummary.DHCPOptions.Add($ServerOptionObject)
                    }
                    Write-Verbose "Get-WinADDHCPSummary - Found $($ServerOptions.Count) server-level options for $Computer"
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'Server Options' -Operation 'Get-DhcpServerv4OptionValue -All' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                # DHCP Classes (Vendor/User Classes)
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Collecting DHCP classes for $Computer"
                    $Classes = Get-DhcpServerv4Class -ComputerName $Computer -ErrorAction Stop
                    foreach ($Class in $Classes) {
                        $ClassObject = [PSCustomObject] @{
                            ServerName   = $Computer
                            Name         = $Class.Name
                            Type         = $Class.Type
                            Data         = $Class.Data
                            Description  = $Class.Description
                            GatheredFrom = $Computer
                            GatheredDate = Get-Date
                        }
                        $DHCPSummary.DHCPClasses.Add($ClassObject)
                    }
                    Write-Verbose "Get-WinADDHCPSummary - Found $($Classes.Count) DHCP classes for $Computer"
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'DHCP Classes' -Operation 'Get-DhcpServerv4Class' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                # Superscopes
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Collecting superscopes for $Computer"
                    $Superscopes = Get-DhcpServerv4Superscope -ComputerName $Computer -ErrorAction Stop
                    foreach ($Superscope in $Superscopes) {
                        $SuperscopeObject = [PSCustomObject] @{
                            ServerName        = $Computer
                            SuperscopeName    = $Superscope.SuperscopeName
                            ScopeId           = $Superscope.ScopeId
                            SuperscopeState   = $Superscope.SuperscopeState
                            GatheredFrom      = $Computer
                            GatheredDate      = Get-Date
                        }
                        $DHCPSummary.Superscopes.Add($SuperscopeObject)
                    }
                    Write-Verbose "Get-WinADDHCPSummary - Found $($Superscopes.Count) superscopes for $Computer"
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'Superscopes' -Operation 'Get-DhcpServerv4Superscope' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                # Failover Relationships
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Collecting failover relationships for $Computer"
                    $FailoverRelationships = Get-DhcpServerv4Failover -ComputerName $Computer -ErrorAction Stop
                    foreach ($Failover in $FailoverRelationships) {
                        $FailoverObject = [PSCustomObject] @{
                            ServerName              = $Computer
                            Name                    = $Failover.Name
                            PartnerServer           = $Failover.PartnerServer
                            Mode                    = $Failover.Mode
                            State                   = $Failover.State
                            LoadBalancePercent      = $Failover.LoadBalancePercent
                            MaxClientLeadTime       = $Failover.MaxClientLeadTime
                            StateSwitchInterval     = $Failover.StateSwitchInterval
                            AutoStateTransition     = $Failover.AutoStateTransition
                            EnableAuth              = $Failover.EnableAuth
                            ScopeCount              = ($Failover.ScopeId | Measure-Object).Count
                            ScopeIds                = ($Failover.ScopeId -join ', ')
                            GatheredFrom            = $Computer
                            GatheredDate            = Get-Date
                        }
                        $DHCPSummary.FailoverRelationships.Add($FailoverObject)
                    }
                    Write-Verbose "Get-WinADDHCPSummary - Found $($FailoverRelationships.Count) failover relationships for $Computer"
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'Failover Relationships' -Operation 'Get-DhcpServerv4Failover' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                # Server Statistics
                try {
                    Write-Verbose "Get-WinADDHCPSummary - Collecting server statistics for $Computer"
                    $ServerStats = Get-DhcpServerv4Statistics -ComputerName $Computer -ErrorAction Stop
                    $ServerStatsObject = [PSCustomObject] @{
                        ServerName          = $Computer
                        TotalScopes         = $ServerStats.TotalScopes
                        ScopesWithDelay     = $ServerStats.ScopesWithDelay
                        TotalAddresses      = $ServerStats.TotalAddresses
                        AddressesInUse      = $ServerStats.AddressesInUse
                        AddressesAvailable  = $ServerStats.AddressesAvailable
                        PercentageInUse     = $ServerStats.PercentageInUse
                        PercentageAvailable = $ServerStats.PercentageAvailable
                        Discovers           = $ServerStats.Discovers
                        Offers              = $ServerStats.Offers
                        Requests            = $ServerStats.Requests
                        Acks                = $ServerStats.Acks
                        Naks                = $ServerStats.Naks
                        Declines            = $ServerStats.Declines
                        Releases            = $ServerStats.Releases
                        ServerStartTime     = $ServerStats.ServerStartTime
                        GatheredFrom        = $Computer
                        GatheredDate        = Get-Date
                    }
                    $DHCPSummary.ServerStatistics.Add($ServerStatsObject)
                    Write-Verbose "Get-WinADDHCPSummary - Server statistics collected for $Computer"
                } catch {
                    Add-DHCPError -ServerName $Computer -Component 'Server Statistics' -Operation 'Get-DhcpServerv4Statistics' -ErrorMessage $_.Exception.Message -Severity 'Warning'
                }

                Write-Verbose "Get-WinADDHCPSummary - Completed enhanced configuration data collection for $Computer"

            } catch {
                Add-DHCPError -ServerName $Computer -Component 'Enhanced Server Configuration' -Operation 'Overall Enhanced Configuration Gathering' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }
        }
    }

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

    foreach ($Scope in $DHCPSummary.Scopes) {
        if ($Scope.State -eq 'Active') { $ScopesActiveCount++ }
        elseif ($Scope.State -eq 'Inactive') { $ScopesInactiveCount++ }
    }

    $DHCPSummary.Statistics = [ordered] @{
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

    # Categorize validation results efficiently using single-pass operations
    $PublicDNSWithUpdates = [System.Collections.Generic.List[Object]]::new()
    $HighUtilization = [System.Collections.Generic.List[Object]]::new()
    $ServersOffline = [System.Collections.Generic.List[Object]]::new()
    $MissingFailover = [System.Collections.Generic.List[Object]]::new()
    $ExtendedLeaseDuration = [System.Collections.Generic.List[Object]]::new()
    $ModerateUtilization = [System.Collections.Generic.List[Object]]::new()
    $DNSRecordManagement = [System.Collections.Generic.List[Object]]::new()
    $MissingDomainName = [System.Collections.Generic.List[Object]]::new()
    $InactiveScopes = [System.Collections.Generic.List[Object]]::new()

    # Single pass through servers for offline check
    foreach ($Server in $DHCPSummary.Servers) {
        if ($Server.Status -eq 'Unreachable') {
            $ServersOffline.Add($Server)
        }
    }

    # Single pass through scopes for all validations
    foreach ($Scope in $DHCPSummary.Scopes) {
        # Check utilization levels
        if ($Scope.State -eq 'Active') {
            if ($Scope.PercentageInUse -gt 90) {
                $HighUtilization.Add($Scope)
            } elseif ($Scope.PercentageInUse -gt 75) {
                $ModerateUtilization.Add($Scope)
            }
        }

        # Check inactive scopes
        if ($Scope.State -eq 'Inactive') {
            $InactiveScopes.Add($Scope)
        }
    }

    # Single pass through scopes with issues for detailed validations
    foreach ($Scope in $DHCPSummary.ScopesWithIssues) {
        foreach ($Issue in $Scope.Issues) {
            if ($Issue -like "*public DNS servers*") {
                $PublicDNSWithUpdates.Add($Scope)
            } elseif ($Issue -like "*Failover not configured*") {
                $MissingFailover.Add($Scope)
            } elseif ($Issue -like "*exceeds 48 hours*") {
                $ExtendedLeaseDuration.Add($Scope)
            } elseif ($Issue -like "*UpdateDnsRRForOlderClients*" -or $Issue -like "*DeleteDnsRROnLeaseExpiry*") {
                $DNSRecordManagement.Add($Scope)
            } elseif ($Issue -like "*Domain name option*") {
                $MissingDomainName.Add($Scope)
            }
        }
    }

    $DHCPSummary.ValidationResults = [ordered] @{
        # Critical issues that require immediate attention
        CriticalIssues = [ordered] @{
            PublicDNSWithUpdates = $PublicDNSWithUpdates
            ServersOffline       = $ServersOffline
        }
        # Utilization issues that may need capacity planning
        UtilizationIssues = [ordered] @{
            HighUtilization     = $HighUtilization
            ModerateUtilization = $ModerateUtilization
        }
        # Warning issues that should be addressed soon
        WarningIssues  = [ordered] @{
            MissingFailover       = $MissingFailover
            ExtendedLeaseDuration = $ExtendedLeaseDuration
            DNSRecordManagement   = $DNSRecordManagement
        }
        # Information issues that are good to know but not urgent
        InfoIssues     = [ordered] @{
            MissingDomainName = $MissingDomainName
            InactiveScopes    = $InactiveScopes
        }
        # Summary counters for quick overview
        Summary        = [ordered] @{
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

    if ($DHCPSummary.Statistics.TotalAddresses -gt 0) {
        $DHCPSummary.Statistics.OverallPercentageInUse = [Math]::Round(($DHCPSummary.Statistics.AddressesInUse / $DHCPSummary.Statistics.TotalAddresses) * 100, 2)
    }

    # Calculate validation summary counters efficiently
    $DHCPSummary.ValidationResults.Summary.TotalCriticalIssues = (
        $PublicDNSWithUpdates.Count +
        $ServersOffline.Count
    )

    $DHCPSummary.ValidationResults.Summary.TotalUtilizationIssues = (
        $HighUtilization.Count +
        $ModerateUtilization.Count
    )

    $DHCPSummary.ValidationResults.Summary.TotalWarningIssues = (
        $MissingFailover.Count +
        $ExtendedLeaseDuration.Count +
        $DNSRecordManagement.Count
    )

    $DHCPSummary.ValidationResults.Summary.TotalInfoIssues = (
        $MissingDomainName.Count +
        $InactiveScopes.Count
    )

    # Calculate unique scope counts for each severity level using efficient single-pass array comprehension
    $CriticalScopes = @(
        $PublicDNSWithUpdates
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithCritical = ($CriticalScopes | Sort-Object -Property ScopeId -Unique).Count

    $UtilizationScopes = @(
        $HighUtilization
        $ModerateUtilization
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithUtilization = ($UtilizationScopes | Sort-Object -Property ScopeId -Unique).Count

    $WarningScopes = @(
        $MissingFailover
        $ExtendedLeaseDuration
        $DNSRecordManagement
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithWarnings = ($WarningScopes | Sort-Object -Property ScopeId -Unique).Count

    $InfoScopes = @(
        $MissingDomainName
        $InactiveScopes
    )
    $DHCPSummary.ValidationResults.Summary.ScopesWithInfo = ($InfoScopes | Sort-Object -Property ScopeId -Unique).Count

    # Enhanced Analysis: Security Analysis
    Write-Verbose "Get-WinADDHCPSummary - Performing enhanced security analysis"
    foreach ($Server in $DHCPSummary.Servers) {
        $SecurityIssues = [PSCustomObject]@{
            ServerName              = $Server.ServerName
            IsAuthorized            = $Server.IsAuthorized
            AuthorizationStatus     = $Server.AuthorizationStatus
            AuditLoggingEnabled     = $null
            ServiceAccount          = $null
            SecurityRiskLevel       = 'Low'
            SecurityRecommendations = [System.Collections.Generic.List[string]]::new()
        }

        # Determine security risk level based on issues
        if ($Server.Issues | Where-Object { $_ -like "*not authorized*" }) {
            $SecurityIssues.SecurityRiskLevel = 'Critical'
            $SecurityIssues.SecurityRecommendations.Add("Authorize DHCP server in Active Directory immediately")
        }
        if ($Server.Issues | Where-Object { $_ -like "*audit*" }) {
            $SecurityIssues.SecurityRiskLevel = if ($SecurityIssues.SecurityRiskLevel -eq 'Critical') { 'Critical' } else { 'High' }
            $SecurityIssues.SecurityRecommendations.Add("Enable DHCP audit logging for security monitoring")
        }
        if ($Server.Issues | Where-Object { $_ -like "*LocalSystem*" }) {
            $SecurityIssues.SecurityRiskLevel = if ($SecurityIssues.SecurityRiskLevel -eq 'Critical') { 'Critical' } else { 'Medium' }
            $SecurityIssues.SecurityRecommendations.Add("Configure dedicated service account for DHCP service")
        }

        $DHCPSummary.SecurityAnalysis.Add($SecurityIssues)
    }

    # Enhanced Analysis: Performance Metrics
    Write-Verbose "Get-WinADDHCPSummary - Calculating performance metrics"
    $OverallPerformance = [PSCustomObject]@{
        TotalServers                    = $DHCPSummary.Summary.TotalServers
        TotalScopes                     = $DHCPSummary.Summary.TotalScopes
        AverageUtilization              = if ($DHCPSummary.Summary.TotalScopes -gt 0) {
            [Math]::Round(($DHCPSummary.Servers | ForEach-Object { $_.PercentageInUse } | Measure-Object -Average).Average, 2)
        } else { 0 }
        HighUtilizationScopes           = ($DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -gt 80 }).Count
        CriticalUtilizationScopes       = ($DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -gt 95 }).Count
        UnderUtilizedScopes             = ($DHCPSummary.Scopes | Where-Object { $_.PercentageInUse -lt 5 -and $_.State -eq 'Active' }).Count
        CapacityPlanningRecommendations = [System.Collections.Generic.List[string]]::new()
    }

    if ($OverallPerformance.CriticalUtilizationScopes -gt 0) {
        $OverallPerformance.CapacityPlanningRecommendations.Add("$($OverallPerformance.CriticalUtilizationScopes) scope(s) require immediate expansion")
    }
    if ($OverallPerformance.HighUtilizationScopes -gt 0) {
        $OverallPerformance.CapacityPlanningRecommendations.Add("$($OverallPerformance.HighUtilizationScopes) scope(s) need expansion planning")
    }
    if ($OverallPerformance.UnderUtilizedScopes -gt 0) {
        $OverallPerformance.CapacityPlanningRecommendations.Add("$($OverallPerformance.UnderUtilizedScopes) scope(s) are underutilized and may need review")
    }

    $DHCPSummary.PerformanceMetrics.Add($OverallPerformance)

    # Enhanced Analysis: Network Design Analysis
    Write-Verbose "Get-WinADDHCPSummary - Analyzing network design"
    $NetworkDesign = [PSCustomObject]@{
        TotalNetworkSegments       = ($DHCPSummary.Scopes | Group-Object { [System.Net.IPAddress]::Parse($_.ScopeId).GetAddressBytes()[0..2] -join '.' }).Count
        ScopeOverlaps              = [System.Collections.Generic.List[string]]::new()
        DesignRecommendations      = [System.Collections.Generic.List[string]]::new()
        RedundancyAnalysis         = [System.Collections.Generic.List[string]]::new()
        ScopeOverlapsCount         = 0  # Will be updated after analysis
        RedundancyIssuesCount      = 0  # Will be updated after analysis
        DesignRecommendationsCount = 0  # Will be updated after analysis
    }

    # Check for potential scope overlaps (simplified check)
    $ScopeRanges = $DHCPSummary.Scopes | Where-Object { $_.State -eq 'Active' }
    for ($i = 0; $i -lt $ScopeRanges.Count; $i++) {
        for ($j = $i + 1; $j -lt $ScopeRanges.Count; $j++) {
            $Scope1 = $ScopeRanges[$i]
            $Scope2 = $ScopeRanges[$j]
            if ($Scope1.ScopeId -eq $Scope2.ScopeId -and $Scope1.ServerName -ne $Scope2.ServerName) {
                $NetworkDesign.ScopeOverlaps.Add("Scope $($Scope1.ScopeId) exists on multiple servers: $($Scope1.ServerName), $($Scope2.ServerName)")
            }
        }
    }

    # Analyze redundancy
    $ServersPerScope = $DHCPSummary.Scopes | Where-Object { $_.State -eq 'Active' } | Group-Object ScopeId
    $SingleServerScopes = ($ServersPerScope | Where-Object { $_.Count -eq 1 }).Count
    if ($SingleServerScopes -gt 0) {
        $NetworkDesign.RedundancyAnalysis.Add("$SingleServerScopes scope(s) have no redundancy (single server)")
        $NetworkDesign.DesignRecommendations.Add("Implement DHCP failover for high availability")
    }

    # Update count properties
    $NetworkDesign.ScopeOverlapsCount = $NetworkDesign.ScopeOverlaps.Count
    $NetworkDesign.RedundancyIssuesCount = $NetworkDesign.RedundancyAnalysis.Count
    $NetworkDesign.DesignRecommendationsCount = $NetworkDesign.DesignRecommendations.Count

    $DHCPSummary.NetworkDesignAnalysis.Add($NetworkDesign)

    # Enhanced Analysis: Scope Redundancy Analysis
    Write-Verbose "Get-WinADDHCPSummary - Generating scope redundancy analysis"
    foreach ($Scope in $DHCPSummary.Scopes) {
        $ScopeRedundancy = [PSCustomObject]@{
            'ScopeId'            = $Scope.ScopeId
            'ScopeName'          = $Scope.Name
            'ServerName'         = $Scope.ServerName
            'State'              = $Scope.State
            'UtilizationPercent' = $Scope.PercentageInUse
            'FailoverPartner'    = if ([string]::IsNullOrEmpty($Scope.FailoverPartner)) { 'None' } else { $Scope.FailoverPartner }
            'RedundancyStatus'   = if ([string]::IsNullOrEmpty($Scope.FailoverPartner)) {
                if ($Scope.State -eq 'Active') { 'No Failover - Risk' } else { 'No Failover - Inactive' }
            } else { 'Failover Configured' }
            'RiskLevel'          = if ([string]::IsNullOrEmpty($Scope.FailoverPartner) -and $Scope.State -eq 'Active' -and $Scope.PercentageInUse -gt 50) { 'High' }
            elseif ([string]::IsNullOrEmpty($Scope.FailoverPartner) -and $Scope.State -eq 'Active') { 'Medium' }
            else { 'Low' }
            'Recommendation'     = if ([string]::IsNullOrEmpty($Scope.FailoverPartner) -and $Scope.State -eq 'Active') { 'Configure Failover' }
            elseif ($Scope.State -ne 'Active') { 'Review Scope Status' }
            else { 'Adequate' }
        }
        $DHCPSummary.ScopeRedundancyAnalysis.Add($ScopeRedundancy)
    }

    # Enhanced Analysis: Server Performance Analysis
    Write-Verbose "Get-WinADDHCPSummary - Generating server performance analysis"
    foreach ($Server in $DHCPSummary.Servers) {
        $ServerPerformance = [PSCustomObject]@{
            'ServerName'         = $Server.ServerName
            'Status'             = $Server.Status
            'TotalScopes'        = $Server.ScopeCount
            'ActiveScopes'       = $Server.ActiveScopeCount
            'ScopesWithIssues'   = $Server.ScopesWithIssues
            'TotalAddresses'     = $Server.TotalAddresses
            'AddressesInUse'     = $Server.AddressesInUse
            'UtilizationPercent' = $Server.PercentageInUse
            'PerformanceRating'  = if ($Server.Status -ne 'Online') { 'Offline' }
            elseif (-not $Server.DHCPResponding) { 'Service Failed' }
            elseif (-not $Server.DNSResolvable) { 'DNS Issues' }
            elseif (-not $Server.PingSuccessful) { 'Network Issues' }
            elseif ($Server.PercentageInUse -gt 95) { 'Critical' }
            elseif ($Server.PercentageInUse -gt 80) { 'High Risk' }
            elseif ($Server.PercentageInUse -gt 60) { 'Moderate' }
            elseif ($Server.PercentageInUse -lt 5 -and $Server.ScopeCount -gt 0) { 'Under-utilized' }
            else { 'Optimal' }
            'CapacityStatus'     = if ($Server.Status -ne 'Online') { 'Server Offline' }
            elseif (-not $Server.DHCPResponding) { 'Service Not Responding' }
            elseif (-not $Server.DNSResolvable) { 'DNS Resolution Failed' }
            elseif (-not $Server.PingSuccessful) { 'Network Unreachable' }
            elseif ($Server.PercentageInUse -gt 95) { 'Immediate Expansion Needed' }
            elseif ($Server.PercentageInUse -gt 80) { 'Plan Expansion' }
            elseif ($Server.PercentageInUse -lt 5 -and $Server.ScopeCount -gt 0) { 'Review Necessity' }
            else { 'Adequate' }
        }
        $DHCPSummary.ServerPerformanceAnalysis.Add($ServerPerformance)
    }

    # Enhanced Analysis: Server Network Analysis
    Write-Verbose "Get-WinADDHCPSummary - Generating server network analysis"
    foreach ($Server in $DHCPSummary.Servers) {
        $RedundancyNotes = @()
        if ($Server.IsADDomainController) {
            $RedundancyNotes += "Domain Controller"
        }
        if ($Server.ScopeCount -gt 10) {
            $RedundancyNotes += "High scope count - consider load balancing"
        }

        $ServerNetwork = [PSCustomObject]@{
            'ServerName'         = $Server.ServerName
            'IPAddress'          = $Server.IPAddress
            'Status'             = $Server.Status
            'IsDomainController' = $Server.IsADDomainController
            'TotalScopes'        = $Server.ScopeCount
            'ActiveScopes'       = $Server.ActiveScopeCount
            'InactiveScopes'     = $Server.InactiveScopeCount
            'DNSResolvable'      = $Server.DNSResolvable
            'ReverseDNSValid'    = $Server.ReverseDNSValid
            'NetworkHealth'      = if (-not $Server.PingSuccessful) { 'Network Issues' }
            elseif (-not $Server.DNSResolvable) { 'DNS Issues' }
            elseif (-not $Server.DHCPResponding) { 'DHCP Service Issues' }
            else { 'Healthy' }
            'DesignNotes'        = if ($RedundancyNotes.Count -gt 0) { $RedundancyNotes -join ', ' } else { 'Standard Configuration' }
        }
        $DHCPSummary.ServerNetworkAnalysis.Add($ServerNetwork)
    }

    # Enhanced Analysis: Backup Analysis (placeholder - would need actual DHCP server access)
    Write-Verbose "Get-WinADDHCPSummary - Generating backup analysis placeholder"
    foreach ($Server in $DHCPSummary.Servers | Where-Object { $_.Status -eq 'Online' }) {
        $BackupAnalysis = [PSCustomObject]@{
            'ServerName'             = $Server.ServerName
            'BackupEnabled'          = $null  # Would require Get-DhcpServerDatabase access
            'BackupIntervalMinutes'  = $null  # Available in Database collection if populated
            'CleanupIntervalMinutes' = $null # Available in Database collection if populated
            'LastBackupTime'         = $null  # Would require additional queries
            'BackupStatus'           = 'Unknown - Requires Server Access'
            'Recommendations'        = @('Enable regular backup validation', 'Verify backup restoration procedures')
        }
        $DHCPSummary.BackupAnalysis.Add($BackupAnalysis)
    }

    # Enhanced Analysis: DHCP Options Analysis
    Write-Verbose "Get-WinADDHCPSummary - Analyzing DHCP options configuration"
    if ($DHCPSummary.DHCPOptions.Count -gt 0 -or $DHCPSummary.Options.Count -gt 0) {
        # Combine server-level and scope-level options for analysis
        $AllOptions = @()
        $AllOptions += $DHCPSummary.DHCPOptions
        $AllOptions += $DHCPSummary.Options

        # Analyze critical options
        $CriticalOptions = @{
            3  = 'Router (Default Gateway)'
            6  = 'DNS Servers'
            15 = 'Domain Name'
            51 = 'Lease Time'
            66 = 'Boot Server Host Name'
            67 = 'Bootfile Name'
        }

        $OptionsAnalysis = [PSCustomObject]@{
            'AnalysisType'           = 'DHCP Options Configuration'
            'TotalServersAnalyzed'   = ($AllOptions | Group-Object ServerName).Count
            'TotalOptionsConfigured' = $AllOptions.Count
            'UniqueOptionTypes'      = ($AllOptions | Group-Object OptionId).Count
            'CriticalOptionsCovered' = 0
            'MissingCriticalOptions' = [System.Collections.Generic.List[string]]::new()
            'OptionIssues'           = [System.Collections.Generic.List[string]]::new()
            'OptionRecommendations'  = [System.Collections.Generic.List[string]]::new()
            'ServerLevelOptions'     = ($DHCPSummary.DHCPOptions | Group-Object OptionId).Count
            'ScopeLevelOptions'      = ($DHCPSummary.Options | Group-Object OptionId).Count
        }

        # Check for critical options coverage
        foreach ($OptionId in $CriticalOptions.Keys) {
            $OptionExists = $AllOptions | Where-Object { $_.OptionId -eq $OptionId }
            if ($OptionExists) {
                $OptionsAnalysis.CriticalOptionsCovered++

                # Analyze specific option values for issues
                foreach ($Option in $OptionExists) {
                    switch ($OptionId) {
                        6 { # DNS Servers
                            if ($Option.Value -match '8\.8\.8\.8|1\.1\.1\.1|208\.67\.222\.222') {
                                $OptionsAnalysis.OptionIssues.Add("Public DNS servers configured in scope $($Option.ScopeId) on $($Option.ServerName)")
                            }
                        }
                        15 { # Domain Name
                            if ([string]::IsNullOrEmpty($Option.Value)) {
                                $OptionsAnalysis.OptionIssues.Add("Empty domain name in scope $($Option.ScopeId) on $($Option.ServerName)")
                            }
                        }
                        51 { # Lease Time
                            try {
                                $LeaseHours = [int]$Option.Value / 3600
                                if ($LeaseHours -gt 168) { # More than 7 days
                                    $OptionsAnalysis.OptionIssues.Add("Very long lease time ($LeaseHours hours) in scope $($Option.ScopeId) on $($Option.ServerName)")
                                }
                            } catch {
                                $OptionsAnalysis.OptionIssues.Add("Invalid lease time format in scope $($Option.ScopeId) on $($Option.ServerName)")
                            }
                        }
                    }
                }
            } else {
                $OptionsAnalysis.MissingCriticalOptions.Add("Option $OptionId ($($CriticalOptions[$OptionId])) not configured on any server/scope")
            }
        }

        # Generate recommendations
        if ($OptionsAnalysis.MissingCriticalOptions.Count -gt 0) {
            $OptionsAnalysis.OptionRecommendations.Add("Configure missing critical DHCP options for proper client functionality")
        }
        if ($OptionsAnalysis.OptionIssues.Count -eq 0) {
            $OptionsAnalysis.OptionRecommendations.Add("DHCP options configuration appears healthy")
        }
        if ($OptionsAnalysis.ServerLevelOptions -eq 0) {
            $OptionsAnalysis.OptionRecommendations.Add("Consider configuring server-level options for common settings")
        }

        $DHCPSummary.OptionsAnalysis.Add($OptionsAnalysis)
    } else {
        Write-Verbose "Get-WinADDHCPSummary - No DHCP options data available for analysis"
    }

    Write-Progress -Activity "Processing DHCP Servers" -Completed
    
    # Add overall timing summary
    if ($OverallStartTime) {
        Add-DHCPTimingStatistic -TimingList $DHCPSummary.TimingStatistics -ServerName 'Overall' -Operation 'Complete DHCP Discovery' -StartTime $OverallStartTime -ItemCount $ProcessedServers
    }
    
    Write-Verbose "Get-WinADDHCPSummary - DHCP information gathering completed"

    return $DHCPSummary
}
