function Get-WinDHCPScopeDetails {
    <#
    .SYNOPSIS
    Internal helper function to gather detailed DHCP scope information.

    .DESCRIPTION
    This internal function retrieves comprehensive information about a specific DHCP scope
    including statistics, DNS settings, failover configuration, and validation results.

    .PARAMETER ComputerName
    The name or IP address of the DHCP server.

    .PARAMETER Scope
    The DHCP scope object to process.

    .PARAMETER IncludeValidation
    Whether to include configuration validation checks.

    .EXAMPLE
    Get-WinDHCPScopeDetails -ComputerName "dhcp01.domain.com" -Scope $ScopeObject -IncludeValidation

    .NOTES
    This is an internal helper function and should not be called directly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName,

        [Parameter(Mandatory)]
        [object] $Scope,

        [switch] $IncludeValidation
    )

    $ScopeObject = [ordered] @{
        ServerName          = $ComputerName
        ScopeId            = $Scope.ScopeId
        Name               = $Scope.Name
        Description        = $Scope.Description
        State              = $Scope.State
        SubnetMask         = $Scope.SubnetMask
        StartRange         = $Scope.StartRange
        EndRange           = $Scope.EndRange
        LeaseDuration      = $Scope.LeaseDuration
        LeaseDurationHours = $Scope.LeaseDuration.TotalHours
        Type               = $Scope.Type
        SuperscopeName     = $Scope.SuperscopeName
        AddressesInUse     = 0
        AddressesFree      = 0
        PercentageInUse    = 0
        Reserved           = 0
        HasIssues          = $false
        Issues             = [System.Collections.Generic.List[string]]::new()
        DNSUpdateSettings  = $null
        FailoverPartner    = $null
        FailoverState      = $null
        GatheredFrom       = $ComputerName
        GatheredDate       = Get-Date
    }

    # Get scope statistics
    try {
        $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction Stop
        $ScopeObject.AddressesInUse = $ScopeStats.AddressesInUse
        $ScopeObject.AddressesFree = $ScopeStats.AddressesFree
        $ScopeObject.PercentageInUse = [Math]::Round($ScopeStats.PercentageInUse, 2)
        $ScopeObject.Reserved = $ScopeStats.Reserved
    } catch {
        Write-Warning "Get-WinDHCPScopeDetails - Failed to get scope statistics for $($Scope.ScopeId) on $ComputerName`: $($_.Exception.Message)"
    }

    # Get DNS settings
    try {
        $DNSSettings = Get-DhcpServerv4DnsSetting -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction Stop
        $ScopeObject.DNSUpdateSettings = [PSCustomObject] @{
            DynamicUpdates             = $DNSSettings.DynamicUpdates
            UpdateDnsRRForOlderClients = $DNSSettings.UpdateDnsRRForOlderClients
            DeleteDnsRROnLeaseExpiry   = $DNSSettings.DeleteDnsRROnLeaseExpiry
            NameProtection             = $DNSSettings.NameProtection
        }
    } catch {
        Write-Verbose "Get-WinDHCPScopeDetails - Failed to get DNS settings for scope $($Scope.ScopeId) on $ComputerName`: $($_.Exception.Message)"
    }

    # Get failover configuration
    try {
        $Failover = Get-DhcpServerv4Failover -ComputerName $ComputerName -ScopeId $Scope.ScopeId -ErrorAction SilentlyContinue
        if ($Failover) {
            $ScopeObject.FailoverPartner = $Failover.PartnerServer
            $ScopeObject.FailoverState = $Failover.State
        }
    } catch {
        Write-Verbose "Get-WinDHCPScopeDetails - Failed to get failover information for scope $($Scope.ScopeId) on $ComputerName"
    }

    # Perform validation if requested
    if ($IncludeValidation) {
        $ValidationResults = Test-WinDHCPScopeConfiguration -ComputerName $ComputerName -Scope $Scope
        $ScopeObject.HasIssues = $ValidationResults.HasIssues
        $ScopeObject.Issues = $ValidationResults.Issues
    }

    return [PSCustomObject]$ScopeObject
}
