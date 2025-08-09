function Get-WinADDHCPScopeConfiguration {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [Object] $Scope,
        [System.Collections.Generic.List[Object]] $DHCPSummaryErrors
    )

    Write-Verbose "Get-WinADDHCPScopeConfiguration - Processing scope $($Scope.ScopeId) on $Computer"

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
        # Enhanced scope analysis fields
        TotalAddresses             = 0
        DefinedRange               = 0
        UtilizationEfficiency      = 0
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

        } catch {
            if ($DHCPSummaryErrors) {
                Add-DHCPError -Summary @{ Errors = $DHCPSummaryErrors } -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Options' -Operation 'Get-DhcpServerv4OptionValue' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }
        }
    } catch {
        if ($DHCPSummaryErrors) {
            Add-DHCPError -Summary @{ Errors = $DHCPSummaryErrors } -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DNS Settings' -Operation 'Get-DhcpServerv4DnsSetting' -ErrorMessage $_.Exception.Message -Severity 'Warning'
        }
    }

    # Check DHCP failover configuration
    try {
        $Failover = Get-DhcpServerv4Failover -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction SilentlyContinue
        if ($Failover) {
            $ScopeObject.FailoverPartner = $Failover.PartnerServer
        }
    } catch {
        # Failover may not be configured, which is not necessarily an error
        Write-Verbose "Get-WinADDHCPScopeConfiguration - No failover configuration for scope $($Scope.ScopeId) on $Computer"
    }

    return [PSCustomObject]$ScopeObject
}