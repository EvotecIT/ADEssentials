function Get-WinADDHCPScopeStatistics {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [Object] $Scope,
        [PSCustomObject] $ScopeObject,
        [System.Collections.Generic.List[Object]] $DHCPSummaryTimingStatistics,
        [System.Collections.Generic.List[Object]] $DHCPSummaryErrors,
        [switch] $SkipScopeDetails,
        [switch] $TestMode
    )

    if (-not $SkipScopeDetails) {
        $StatsStart = Get-Date
        try {
            if ($TestMode) {
                $ScopeStats = Get-TestModeDHCPData -DataType 'DhcpServerv4ScopeStatistics' -ComputerName $Computer -ScopeId $Scope.ScopeId
            } else {
                $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Computer -ScopeId $Scope.ScopeId -ErrorAction Stop
            }
            
            if ($DHCPSummaryTimingStatistics) {
                Add-DHCPTimingStatistic -TimingList $DHCPSummaryTimingStatistics -ServerName $Computer -Operation 'Scope Statistics' -StartTime $StatsStart -ItemCount 1
            }
            
            $ScopeObject.AddressesInUse = $ScopeStats.AddressesInUse
            $ScopeObject.AddressesFree = $ScopeStats.AddressesFree
            $ScopeObject.PercentageInUse = [Math]::Round($ScopeStats.PercentageInUse, 2)
            $ScopeObject.Reserved = $ScopeStats.Reserved

            # Calculate total addresses for server-level statistics
            $ScopeTotalAddresses = ($ScopeStats.AddressesInUse + $ScopeStats.AddressesFree)
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

            # Check utilization thresholds - Add to UtilizationIssues instead of Issues
            if ($ScopeObject.PercentageInUse -gt 95) {
                $ScopeObject.UtilizationIssues.Add("Critical utilization level ($($ScopeObject.PercentageInUse)%) - immediate expansion needed")
                $ScopeObject.HasUtilizationIssues = $true
            } elseif ($ScopeObject.PercentageInUse -gt 80) {
                $ScopeObject.UtilizationIssues.Add("High utilization level ($($ScopeObject.PercentageInUse)%) - expansion planning recommended")
                $ScopeObject.HasUtilizationIssues = $true
            } elseif ($ScopeObject.PercentageInUse -lt 5 -and $Scope.State -eq 'Active') {
                $ScopeObject.UtilizationIssues.Add("Very low utilization ($($ScopeObject.PercentageInUse)%) - scope may be unnecessary")
                $ScopeObject.HasUtilizationIssues = $true
            }

            # Add non-utilization best practice issues to main issues list
            foreach ($Issue in $BestPracticeIssues) {
                $ScopeObject.Issues.Add($Issue)
                $ScopeObject.HasIssues = $true
            }

            Write-Verbose "Get-WinADDHCPScopeStatistics - Scope $($Scope.ScopeId) statistics: Total=$ScopeTotalAddresses, InUse=$($ScopeStats.AddressesInUse), Free=$($ScopeStats.AddressesFree), Utilization=$($ScopeObject.PercentageInUse)%"
            
            return @{
                TotalAddresses = $ScopeTotalAddresses
                AddressesInUse = $ScopeStats.AddressesInUse
                AddressesFree = $ScopeStats.AddressesFree
            }
        } catch {
            if ($DHCPSummaryErrors) {
                Add-DHCPError -Summary @{ Errors = $DHCPSummaryErrors } -ServerName $Computer -ScopeId $Scope.ScopeId -Component 'Scope Statistics' -Operation 'Get-DhcpServerv4ScopeStatistics' -ErrorMessage $_.Exception.Message -Severity 'Warning'
            }
            return @{
                TotalAddresses = 0
                AddressesInUse = 0
                AddressesFree = 0
            }
        }
    } else {
        # When skipping scope statistics, set utilization fields to zero but keep scope in inventory
        Write-Verbose "Get-WinADDHCPScopeStatistics - Skipping statistics collection for scope $($Scope.ScopeId) on $Computer (SkipScopeDetails enabled)"
        $ScopeObject.AddressesInUse = 0
        $ScopeObject.AddressesFree = 0
        $ScopeObject.PercentageInUse = 0
        $ScopeObject.Reserved = 0
        $ScopeObject.TotalAddresses = 0
        
        return @{
            TotalAddresses = 0
            AddressesInUse = 0
            AddressesFree = 0
        }
    }
}