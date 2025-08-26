function Get-WinADDHCPExtendedServerData {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [System.Collections.IDictionary] $DHCPSummary,
        [switch] $TestMode
    )

    Write-Verbose "Get-WinADDHCPExtendedServerData - Gathering extended server data for $Computer"

    # Get audit log information
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
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Audit Log Configuration' -Operation 'Get-DhcpServerAuditLog' -ErrorMessage $_.Exception.Message -Severity 'Warning'
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
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Database Configuration' -Operation 'Get-DhcpServerDatabase' -ErrorMessage $_.Exception.Message -Severity 'Warning'
    }

    # DHCP Server Options (global/server-level)
    try {
        Write-Verbose "Get-WinADDHCPExtendedServerData - Collecting server-level DHCP options for $Computer"
        if ($TestMode) {
            $ServerOptions = Get-TestModeDHCPData -DataType 'DhcpServerv4OptionValueAll' -ComputerName $Computer
        } else {
            $ServerOptions = Get-DhcpServerv4OptionValue -ComputerName $Computer -All -ErrorAction Stop
        }
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
        Write-Verbose "Get-WinADDHCPExtendedServerData - Found $($ServerOptions.Count) server-level options for $Computer"
    } catch {
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Server Options' -Operation 'Get-DhcpServerv4OptionValue -All' -ErrorMessage $_.Exception.Message -Severity 'Warning'
    }

    # DHCP Classes (Vendor/User Classes)
    try {
        Write-Verbose "Get-WinADDHCPExtendedServerData - Collecting DHCP classes for $Computer"
        if ($TestMode) {
            $Classes = Get-TestModeDHCPData -DataType 'DhcpServerv4Class' -ComputerName $Computer
        } else {
            $Classes = Get-DhcpServerv4Class -ComputerName $Computer -ErrorAction Stop
        }
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
        Write-Verbose "Get-WinADDHCPExtendedServerData - Found $($Classes.Count) DHCP classes for $Computer"
    } catch {
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'DHCP Classes' -Operation 'Get-DhcpServerv4Class' -ErrorMessage $_.Exception.Message -Severity 'Warning'
    }

    # Server settings
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
        Write-Verbose "Get-WinADDHCPExtendedServerData - Server settings collected for $Computer"
    } catch {
        $ErrorMessage = $_.Exception.Message
        if ($ErrorMessage -like "*access*denied*" -or $ErrorMessage -like "*permission*") {
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Server Settings' -Operation 'Get-DhcpServerSetting' -ErrorMessage "Insufficient permissions: $ErrorMessage" -Severity 'Warning'
        } else {
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Server Settings' -Operation 'Get-DhcpServerSetting' -ErrorMessage $ErrorMessage -Severity 'Warning'
        }
    }

    # Network bindings
    try {
        $Bindings = Get-DhcpServerv4Binding -ComputerName $Computer -ErrorAction Stop
        if ($Bindings -and $Bindings.Count -gt 0) {
            Write-Verbose "Get-WinADDHCPExtendedServerData - Found $($Bindings.Count) network bindings on $Computer"

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
            Write-Verbose "Get-WinADDHCPExtendedServerData - No network bindings found on $Computer"
        }
    } catch {
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Network Bindings' -Operation 'Get-DhcpServerv4Binding' -ErrorMessage $_.Exception.Message -Severity 'Warning'
    }

    # Security filters
    try {
        Write-Verbose "Get-WinADDHCPExtendedServerData - Checking security filters on $Computer"
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
        Write-Verbose "Get-WinADDHCPExtendedServerData - Security filter mode on $Computer`: $($SecurityFilterObject.FilteringMode)"
    } catch {
        $ErrorMessage = $_.Exception.Message
        if ($ErrorMessage -like "*not found*" -or $ErrorMessage -like "*not supported*") {
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Security Filters' -Operation 'Get-DhcpServerv4FilterList' -ErrorMessage "Security filtering not available (normal for older DHCP servers): $ErrorMessage" -Severity 'Warning'
        } else {
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Security Filters' -Operation 'Get-DhcpServerv4FilterList' -ErrorMessage $ErrorMessage -Severity 'Warning'
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
        Write-Verbose "Get-WinADDHCPExtendedServerData - Checking for IPv6 DHCP support on $Computer"

        $IPv6Scopes = $null
        $IPv6Supported = $false

        try {
            $IPv6Scopes = Get-DhcpServerv6Scope -ComputerName $Computer -ErrorAction Stop
            $IPv6Supported = $true
            Write-Verbose "Get-WinADDHCPExtendedServerData - IPv6 DHCP service detected on $Computer"
        } catch {
            $ErrorMessage = $_.Exception.Message
            # Common error patterns for IPv6 not supported/configured
            if ($ErrorMessage -like "*not found*" -or
                $ErrorMessage -like "*not supported*" -or
                $ErrorMessage -like "*service*" -or
                $ErrorMessage -like "*RPC*" -or
                $ErrorMessage -like "*access*denied*") {
                Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'IPv6 DHCP Service' -Operation 'Get-DhcpServerv6Scope' -ErrorMessage "IPv6 DHCP not available (normal): $ErrorMessage" -Severity 'Warning'
            } else {
                Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'IPv6 DHCP Service' -Operation 'Get-DhcpServerv6Scope' -ErrorMessage $ErrorMessage -Severity 'Warning'
            }
        }

        if ($IPv6Supported -and $IPv6Scopes -and $IPv6Scopes.Count -gt 0) {
            Write-Verbose "Get-WinADDHCPExtendedServerData - Found $($IPv6Scopes.Count) IPv6 scopes on $Computer"

            foreach ($IPv6Scope in $IPv6Scopes) {
                Write-Verbose "Get-WinADDHCPExtendedServerData - Processing IPv6 scope $($IPv6Scope.Prefix) on $Computer"

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
                    Write-Verbose "Get-WinADDHCPExtendedServerData - IPv6 scope $($IPv6Scope.Prefix) utilization: $($IPv6ScopeObject.PercentageInUse)%"
                } catch {
                    Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -ScopeId $IPv6Scope.Prefix -Component 'IPv6 Scope Statistics' -Operation 'Get-DhcpServerv6ScopeStatistics' -ErrorMessage $_.Exception.Message -Severity 'Warning'
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
            Write-Verbose "Get-WinADDHCPExtendedServerData - No IPv6 scopes found on $Computer (IPv6 DHCP not deployed)"
        }
    } catch {
        # This catch should rarely be reached due to inner try-catch, but provides final safety net
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'IPv6 DHCP Analysis' -Operation 'IPv6 Overall Processing' -ErrorMessage $_.Exception.Message -Severity 'Warning'
    }
}