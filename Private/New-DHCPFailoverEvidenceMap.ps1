function New-DHCPFailoverEvidenceMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Computer,
        [AllowNull()][object[]] $Relationships,
        [AllowNull()][object] $CollectionStatus,
        [bool] $CollectionEnabled = $true
    )

    $byScope = @{}
    foreach ($relationship in @($Relationships)) {
        if (-not $relationship) { continue }

        foreach ($scopeId in @($relationship.ScopeId)) {
            $key = ([string]$scopeId).Trim()
            if ([string]::IsNullOrWhiteSpace($key)) { continue }

            if (-not $byScope.ContainsKey($key)) {
                $byScope[$key] = [ordered]@{
                    Partners         = [System.Collections.Generic.List[string]]::new()
                    RelationshipNames = [System.Collections.Generic.List[string]]::new()
                }
            }

            $entry = $byScope[$key]
            $partner = ([string]$relationship.PartnerServer).Trim()
            if ($partner -and -not $entry.Partners.Contains($partner)) {
                [void]$entry.Partners.Add($partner)
            }
            $name = ([string]$relationship.Name).Trim()
            if ($name -and -not $entry.RelationshipNames.Contains($name)) {
                [void]$entry.RelationshipNames.Add($name)
            }
        }
    }

    [PSCustomObject]@{
        ServerName        = $Computer
        CollectionEnabled = $CollectionEnabled
        CollectionStatus  = $CollectionStatus
        ByScope           = $byScope
    }
}
