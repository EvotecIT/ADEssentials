function Get-WinADDHCPOptionsAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    Write-Verbose "Get-WinADDHCPOptionsAnalysis - Analyzing DHCP options configuration"
    
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
                        6 {
                            # DNS Servers
                            if ($Option.Value -match '8\.8\.8\.8|1\.1\.1\.1|208\.67\.222\.222') {
                                $OptionsAnalysis.OptionIssues.Add("Public DNS servers configured in scope $($Option.ScopeId) on $($Option.ServerName)")
                            }
                        }
                        15 {
                            # Domain Name
                            if ([string]::IsNullOrEmpty($Option.Value)) {
                                $OptionsAnalysis.OptionIssues.Add("Empty domain name in scope $($Option.ScopeId) on $($Option.ServerName)")
                            }
                        }
                        51 {
                            # Lease Time
                            try {
                                $LeaseHours = [int]$Option.Value / 3600
                                if ($LeaseHours -gt 168) {
                                    # More than 7 days
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
        Write-Verbose "Get-WinADDHCPOptionsAnalysis - No DHCP options data available for analysis"
    }
}