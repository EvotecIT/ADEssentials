function Get-WinADDHCPSummaryTestModeData {
    [CmdletBinding()]
    param(
        [switch] $SkipScopeDetails
    )
    Write-Verbose "Get-WinADDHCPSummary - Running in test mode with sample data"

    # Adjust test data based on SkipScopeDetails parameter
    if ($SkipScopeDetails) {
        Write-Verbose "Get-WinADDHCPSummary - Test mode with SkipScopeDetails enabled - scope utilization data will be empty"
        $testServers = @(
            [PSCustomObject]@{
                ServerName = 'dhcp01.domain.com'; ComputerName = 'dhcp01.domain.com'; Status = 'Online'; Version = '10.0'; PingSuccessful = $true; DNSResolvable = $true; DHCPResponding = $true
                ScopeCount = 15; ActiveScopeCount = 13; InactiveScopeCount = 2; TotalScopes = 15; ScopesActive = 13; ScopesInactive = 2; ScopesWithIssues = 2; TotalAddresses = 0; AddressesInUse = 0; AddressesFree = 0; PercentageInUse = 0
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
                ScopeCount = 8; ActiveScopeCount = 8; InactiveScopeCount = 0; TotalScopes = 8; ScopesActive = 8; ScopesInactive = 0; ScopesWithIssues = 1; TotalAddresses = 0; AddressesInUse = 0; AddressesFree = 0; PercentageInUse = 0
                IsADDomainController = $true; DomainName = 'domain.com'; IPAddress = '192.168.1.5'
                ReverseDNSName = 'dc01.domain.com'; ReverseDNSValid = $true; ResponseTimeMs = 3; DHCPRole = 'Backup'
            }
        )
        $testScopes = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 0; AddressesInUse = 0; AddressesFree = 0; HasIssues = $true; Issues = @('High lease duration (168 hours) without documented exception'); LeaseDurationHours = 168; FailoverPartner = $null; DNSServers = '10.1.1.1, 10.1.1.2'; DomainName = 'domain.com'; DynamicUpdates = 'OnClientRequest' }
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.1.0.0'; Name = 'Guest Network'; State = 'Active'; PercentageInUse = 0; AddressesInUse = 0; AddressesFree = 0; HasIssues = $false; Issues = @(); LeaseDurationHours = 24; FailoverPartner = 'dhcp02.domain.com'; DNSServers = '10.1.1.1, 10.1.1.2'; DomainName = 'guest.domain.com'; DynamicUpdates = 'Never' }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 0; AddressesInUse = 0; AddressesFree = 0; HasIssues = $true; Issues = @('No failover configured', 'UpdateDnsRRForOlderClients is disabled'); LeaseDurationHours = 168; FailoverPartner = $null; DNSServers = '10.1.1.1, 10.1.1.2'; DomainName = 'domain.com'; DynamicUpdates = 'OnClientRequest' }
        )
        $testScopesWithIssues = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 0; HasIssues = $true; Issues = @('High lease duration (168 hours) without documented exception'); LeaseDurationHours = 168; FailoverPartner = $null }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 0; HasIssues = $true; Issues = @('No failover configured', 'UpdateDnsRRForOlderClients is disabled'); LeaseDurationHours = 168; FailoverPartner = $null }
        )
    } else {
        $testServers = @(
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
        $testScopes = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; AddressesInUse = 170; AddressesFree = 30; HasIssues = $true; Issues = @('High utilization'); LeaseDurationHours = 8; FailoverPartner = $null }
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.1.0.0'; Name = 'Guest Network'; State = 'Active'; PercentageInUse = 25; AddressesInUse = 50; AddressesFree = 150; HasIssues = $false; Issues = @(); LeaseDurationHours = 24; FailoverPartner = 'dhcp02.domain.com' }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; AddressesInUse = 92; AddressesFree = 8; HasIssues = $true; Issues = @('Critical utilization', 'No failover configured'); LeaseDurationHours = 168; FailoverPartner = $null }
        )
        $testScopesWithIssues = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; HasIssues = $true; Issues = @('High utilization'); LeaseDurationHours = 8; FailoverPartner = $null }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('Critical utilization', 'No failover configured'); LeaseDurationHours = 168; FailoverPartner = $null }
        )
    }

    return @{
        Servers                   = $testServers
        Scopes                    = $testScopes
        ScopesWithIssues          = $testScopesWithIssues
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
            TotalScopes = if ($SkipScopeDetails) { 23 } else { 3 }; ScopesActive = if ($SkipScopeDetails) { 21 } else { 3 }; ScopesInactive = if ($SkipScopeDetails) { 2 } else { 0 }; ScopesWithIssues = if ($SkipScopeDetails) { 2 } else { 2 }
            TotalAddresses = if ($SkipScopeDetails) { 0 } else { 450 }; AddressesInUse = if ($SkipScopeDetails) { 0 } else { 312 }; AddressesFree = if ($SkipScopeDetails) { 0 } else { 138 }; OverallPercentageInUse = if ($SkipScopeDetails) { 0 } else { 69 }
        }
        SecurityAnalysis          = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; IsAuthorized = $true; AuthorizationStatus = 'Authorized in AD'; AuditLoggingEnabled = $true; ServiceAccount = 'Network Service'; SecurityRiskLevel = 'Low'; SecurityRecommendations = @() }
            [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; IsAuthorized = $false; AuthorizationStatus = 'Not authorized in AD'; AuditLoggingEnabled = $false; ServiceAccount = 'LocalSystem'; SecurityRiskLevel = 'Critical'; SecurityRecommendations = @('Authorize DHCP server in Active Directory immediately', 'Enable DHCP audit logging for security monitoring', 'Configure dedicated service account for DHCP service') }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; IsAuthorized = $true; AuthorizationStatus = 'Authorized in AD'; AuditLoggingEnabled = $false; ServiceAccount = 'LocalSystem'; SecurityRiskLevel = 'Medium'; SecurityRecommendations = @('Enable DHCP audit logging for security monitoring', 'Configure dedicated service account for DHCP service') }
        )
        PerformanceMetrics        = if ($SkipScopeDetails) { @() } else {
            @(
                [PSCustomObject]@{ TotalServers = 3; TotalScopes = 3; AverageUtilization = 67.33; HighUtilizationScopes = 2; CriticalUtilizationScopes = 1; UnderUtilizedScopes = 0; CapacityPlanningRecommendations = @('1 scope(s) require immediate expansion', '2 scope(s) need expansion planning') }
            )
        }
        NetworkDesignAnalysis     = @(
            [PSCustomObject]@{ TotalNetworkSegments = if ($SkipScopeDetails) { 23 } else { 3 }; ScopeOverlaps = @(); DesignRecommendations = @('Implement DHCP failover for high availability'); RedundancyAnalysis = @('2 scope(s) have no redundancy (single server)'); ScopeOverlapsCount = 0; RedundancyIssuesCount = 1; DesignRecommendationsCount = 1 }
        )
        BackupAnalysis            = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; BackupEnabled = $true; BackupIntervalMinutes = 60; CleanupIntervalMinutes = 1440; LastBackupTime = (Get-Date).AddHours(-2); BackupStatus = 'Healthy'; Recommendations = @() }
            [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; BackupEnabled = $false; BackupIntervalMinutes = 0; CleanupIntervalMinutes = 0; LastBackupTime = $null; BackupStatus = 'Critical'; Recommendations = @('Configure automated DHCP database backup', 'Set backup interval to 60 minutes', 'Set cleanup interval to 24 hours') }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; BackupEnabled = $true; BackupIntervalMinutes = 120; CleanupIntervalMinutes = 2880; LastBackupTime = (Get-Date).AddHours(-1); BackupStatus = 'Warning'; Recommendations = @('Reduce backup interval to 60 minutes for better recovery') }
        )
        ScopeRedundancyAnalysis   = @(
            [PSCustomObject]@{ ScopeId = '192.168.1.0'; ScopeName = 'Corporate LAN'; ServerName = 'dhcp01.domain.com'; State = 'Active'; UtilizationPercent = if ($SkipScopeDetails) { 0 } else { 85 }; FailoverPartner = 'None'; RedundancyStatus = 'No Failover - Risk'; RiskLevel = 'High'; Recommendation = 'Configure Failover' }
            [PSCustomObject]@{ ScopeId = '10.1.0.0'; ScopeName = 'Guest Network'; ServerName = 'dhcp01.domain.com'; State = 'Active'; UtilizationPercent = if ($SkipScopeDetails) { 0 } else { 25 }; FailoverPartner = 'dhcp02.domain.com'; RedundancyStatus = 'Failover Configured'; RiskLevel = 'Low'; Recommendation = 'Adequate' }
            [PSCustomObject]@{ ScopeId = '172.16.0.0'; ScopeName = 'Management'; ServerName = 'dc01.domain.com'; State = 'Active'; UtilizationPercent = if ($SkipScopeDetails) { 0 } else { 78 }; FailoverPartner = 'None'; RedundancyStatus = 'No Failover - Risk'; RiskLevel = 'High'; Recommendation = 'Configure Failover' }
        )
        ServerPerformanceAnalysis = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Status = 'Online'; TotalScopes = 15; ActiveScopes = 13; ScopesWithIssues = 2; TotalAddresses = if ($SkipScopeDetails) { 0 } else { 300 }; AddressesInUse = if ($SkipScopeDetails) { 0 } else { 135 }; UtilizationPercent = if ($SkipScopeDetails) { 0 } else { 45 }; PerformanceRating = if ($SkipScopeDetails) { 'Statistics Skipped' } else { 'Moderate' }; CapacityStatus = if ($SkipScopeDetails) { 'Statistics Skipped' } else { 'Adequate' } }
            [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Status = 'Unreachable'; TotalScopes = 0; ActiveScopes = 0; ScopesWithIssues = 0; TotalAddresses = 0; AddressesInUse = 0; UtilizationPercent = 0; PerformanceRating = 'Offline'; CapacityStatus = 'Server Offline' }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Status = 'Online'; TotalScopes = 8; ActiveScopes = 8; ScopesWithIssues = 1; TotalAddresses = if ($SkipScopeDetails) { 0 } else { 150 }; AddressesInUse = if ($SkipScopeDetails) { 0 } else { 117 }; UtilizationPercent = if ($SkipScopeDetails) { 0 } else { 78 }; PerformanceRating = if ($SkipScopeDetails) { 'Statistics Skipped' } else { 'Moderate' }; CapacityStatus = if ($SkipScopeDetails) { 'Statistics Skipped' } else { 'Adequate' } }
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
            CriticalIssues    = [ordered] @{
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
            WarningIssues     = [ordered] @{
                MissingFailover       = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '192.168.1.0'; Name = 'Corporate LAN'; State = 'Active'; PercentageInUse = 85; HasIssues = $true; Issues = @('No failover configured'); LeaseDurationHours = 8; FailoverPartner = $null }
                    [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('No failover configured'); LeaseDurationHours = 168; FailoverPartner = $null }
                )
                ExtendedLeaseDuration = @(
                    [PSCustomObject]@{ ServerName = 'dc01.domain.com'; ScopeId = '172.16.1.0'; Name = 'Server VLAN'; State = 'Active'; PercentageInUse = 92; HasIssues = $true; Issues = @('Extended lease duration'); LeaseDurationHours = 168; FailoverPartner = $null }
                )
                DNSRecordManagement   = @()
            }
            InfoIssues        = [ordered] @{
                MissingDomainName = @()
                InactiveScopes    = @()
            }
            Summary           = [ordered] @{
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
        TimingStatistics          = @(
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Operation = 'Server Total Processing'; StartTime = (Get-Date).AddSeconds(-15); EndTime = (Get-Date).AddSeconds(-10); DurationMs = 5000; DurationSeconds = 5; ItemCount = 15; ItemsPerSecond = 3; Success = $true; Timestamp = (Get-Date) }
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Operation = 'Scope Discovery'; StartTime = (Get-Date).AddSeconds(-15); EndTime = (Get-Date).AddSeconds(-14); DurationMs = 1000; DurationSeconds = 1; ItemCount = 15; ItemsPerSecond = 15; Success = $true; Timestamp = (Get-Date) }
            [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Operation = 'Scope Statistics'; StartTime = (Get-Date).AddSeconds(-14); EndTime = (Get-Date).AddSeconds(-12); DurationMs = 2000; DurationSeconds = 2; ItemCount = 15; ItemsPerSecond = 7.5; Success = $true; Timestamp = (Get-Date) }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Operation = 'Server Total Processing'; StartTime = (Get-Date).AddSeconds(-10); EndTime = (Get-Date).AddSeconds(-5); DurationMs = 5000; DurationSeconds = 5; ItemCount = 8; ItemsPerSecond = 1.6; Success = $true; Timestamp = (Get-Date) }
            [PSCustomObject]@{ ServerName = 'dc01.domain.com'; Operation = 'Scope Discovery'; StartTime = (Get-Date).AddSeconds(-10); EndTime = (Get-Date).AddSeconds(-9); DurationMs = 1000; DurationSeconds = 1; ItemCount = 8; ItemsPerSecond = 8; Success = $true; Timestamp = (Get-Date) }
            [PSCustomObject]@{ ServerName = 'Overall'; Operation = 'Complete DHCP Discovery'; StartTime = (Get-Date).AddSeconds(-20); EndTime = (Get-Date); DurationMs = 20000; DurationSeconds = 20; ItemCount = 3; ItemsPerSecond = 0.15; Success = $true; Timestamp = (Get-Date) }
        )
    }
}