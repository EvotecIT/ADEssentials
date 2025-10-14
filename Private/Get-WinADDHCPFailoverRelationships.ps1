function Get-WinADDHCPFailoverRelationships {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [System.Collections.IDictionary] $DHCPSummary,
        [switch] $TestMode
    )

    try {
        $relationships = @()
        if ($TestMode) {
            $relationships = Get-TestModeDHCPData -DataType 'DhcpServerv4FailoverAll' -ComputerName $Computer
        } else {
            $relationships = Get-DhcpServerv4Failover -ComputerName $Computer -ErrorAction Stop
        }

        foreach ($rel in $relationships) {
            if (-not $rel) { continue }

            # Normalize partner/server names to avoid duplicates due to case/whitespace
            $serverNameNorm  = ([string]$Computer).Trim()
            $partnerNameNorm = if ($rel.PartnerServer) { ([string]$rel.PartnerServer).Trim() } else { $null }

            # Prefer explicit primary name if exposed by the provider; do NOT default to $Computer
            $primaryFromAPI = $null
            if ($rel.PSObject.Properties.Name -contains 'PrimaryServerName' -and $rel.PrimaryServerName) {
                $primaryFromAPI = ([string]$rel.PrimaryServerName).Trim()
            }

            # Capture server role information if available (not always provided by all servers/modules)
            $serverRole = $null
            if ($rel.PSObject.Properties.Name -contains 'ServerRole') {
                $serverRole = [string]$rel.ServerRole
            }

            # Normalize scope ids to strings for downstream set operations
            $scopeIds = $null
            if ($null -ne $rel.ScopeId) {
                $scopeIds = @()
                foreach ($sid in @($rel.ScopeId)) { $scopeIds += ([string]$sid).Trim() }
            }

            # Compose a stable pair key for quick grouping elsewhere
            $pair = @($serverNameNorm.ToLower(), $partnerNameNorm.ToLower()) | Where-Object { $_ } | Sort-Object
            $pairKey = ($pair -join '↔')

            # Normalize to a consistent object shape used throughout the report
            $obj = [PSCustomObject]@{
                ServerName        = $serverNameNorm
                PartnerServer     = $partnerNameNorm
                PrimaryServerName = $primaryFromAPI  # may be $null if not provided by API
                ServerRole        = $serverRole       # may be $null
                Name              = $rel.Name
                Mode              = $rel.Mode
                State             = $rel.State
                ScopeId           = $scopeIds
                PairKey           = $pairKey
                GatheredFrom      = $serverNameNorm
                GatheredDate      = Get-Date
            }
            $DHCPSummary.FailoverRelationships.Add($obj)
        }
    } catch {
        $msg = $_.Exception.Message
        # Treat access problems as Errors to surface visibility; others remain Warnings
        $sev = if ($msg -match '(?i)(access is denied|permissiondenied|win32\s*5|unauthorized)') { 'Error' } else { 'Warning' }
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Failover Relationships' -Operation 'Get-DhcpServerv4Failover' -ErrorMessage $msg -Severity $sev
    }
}
