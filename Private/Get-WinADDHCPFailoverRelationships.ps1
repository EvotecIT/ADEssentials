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
            # Normalize to a consistent object shape used throughout the report
            $obj = [PSCustomObject]@{
                ServerName        = $Computer
                PrimaryServerName = if ($rel.PSObject.Properties.Name -contains 'PrimaryServerName' -and $rel.PrimaryServerName) { $rel.PrimaryServerName } else { $Computer }
                PartnerServer     = $rel.PartnerServer
                Name              = $rel.Name
                Mode              = $rel.Mode
                State             = $rel.State
                ScopeId           = $rel.ScopeId
                GatheredFrom      = $Computer
                GatheredDate      = Get-Date
            }
            $DHCPSummary.FailoverRelationships.Add($obj)
        }
    } catch {
        Add-DHCPError -Summary $DHCPSummary -ServerName $Computer -Component 'Failover Relationships' -Operation 'Get-DhcpServerv4Failover' -ErrorMessage $_.Exception.Message -Severity 'Warning'
    }
}
