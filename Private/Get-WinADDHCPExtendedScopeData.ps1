function Get-WinADDHCPExtendedScopeData {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [Object[]] $Scopes,
        [System.Collections.IDictionary] $DHCPSummary,
        [switch] $TestMode
    )

    Write-Verbose "Get-WinADDHCPExtendedScopeData - Starting scope-intensive extended data collection for $Computer"

    # Reservations analysis for each scope (SCOPE-INTENSIVE)
    Write-Verbose "Get-WinADDHCPExtendedScopeData - Starting reservations analysis for $($Scopes.Count) scopes on $Computer"
    $ScopeReservationCounter = 0
    foreach ($Scope in $Scopes) {
        $ScopeReservationCounter++
        Write-Verbose "Get-WinADDHCPExtendedScopeData - Processing reservations for scope [$ScopeReservationCounter/$($Scopes.Count)]: $($Scope.ScopeId) on $Computer"

        try {
            $Reservations = Get-DhcpServerv4Reservation -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
            Write-Verbose "Get-WinADDHCPExtendedScopeData - Found $($Reservations.Count) reservations in scope $($Scope.ScopeId) on $Computer"

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
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Reservations' -Operation 'Get-DhcpServerv4Reservation' -ErrorMessage $_.Exception.Message -Severity 'Warning'
        }

        # Active leases analysis (sample for high utilization scopes) (SCOPE-INTENSIVE)
        try {
            Write-Verbose "Get-WinADDHCPExtendedScopeData - Checking lease information for scope $($Scope.ScopeId) on $Computer"
            $CurrentScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
            if ($Scope.State -eq 'Active' -and $CurrentScopeStats.PercentageInUse -gt 75) {
                Write-Verbose "Get-WinADDHCPExtendedScopeData - High utilization scope $($Scope.ScopeId) ($($CurrentScopeStats.PercentageInUse)%) - collecting lease sample on $Computer"
                $Leases = Get-DhcpServerv4Lease -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop | Select-Object -First 100
                Write-Verbose "Get-WinADDHCPExtendedScopeData - Retrieved $($Leases.Count) lease samples for scope $($Scope.ScopeId) on $Computer"

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
                Write-Verbose "Get-WinADDHCPExtendedScopeData - Scope $($Scope.ScopeId) on $Computer - utilization $($CurrentScopeStats.PercentageInUse)% (below threshold for lease collection)"
            }
        } catch {
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Leases' -Operation 'Get-DhcpServerv4Lease' -ErrorMessage $_.Exception.Message -Severity 'Warning'
        }

        # Enhanced options collection per scope (SCOPE-INTENSIVE)
        Write-Verbose "Get-WinADDHCPExtendedScopeData - Collecting DHCP options for scope $($Scope.ScopeId) on $Computer"
        try {
            $ScopeOptions = Get-DhcpServerv4OptionValue -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
            Write-Verbose "Get-WinADDHCPExtendedScopeData - Found $($ScopeOptions.Count) options for scope $($Scope.ScopeId) on $Computer"

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
            Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'DHCP Options Collection' -Operation 'Get-DhcpServerv4OptionValue' -ErrorMessage $_.Exception.Message -Severity 'Warning'
        }
    }
    Write-Verbose "Get-WinADDHCPExtendedScopeData - Completed scope-intensive extended data collection for $Computer"
}