function Get-DHCPFailoverScopeEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $EvidenceMap,
        [Parameter(Mandatory)][object] $ScopeId
    )

    $key = ([string]$ScopeId).Trim()
    if ($EvidenceMap.ByScope.ContainsKey($key)) {
        $entry = $EvidenceMap.ByScope[$key]
        $partners = @($entry.Partners)
        $collectionSucceeded = [bool]($EvidenceMap.CollectionStatus -and $EvidenceMap.CollectionStatus.Success)
        return [PSCustomObject]@{
            Status            = 'Configured'
            Verified          = $collectionSucceeded
            PartnerServer     = if ($partners.Count -gt 0) { $partners[0] } else { $null }
            PartnerServers    = $partners
            RelationshipNames = @($entry.RelationshipNames)
            EvidenceSource    = if ($collectionSucceeded) { 'Successful bulk relationship enumeration' } else { 'Partial relationship evidence from incomplete enumeration' }
        }
    }

    if (-not $EvidenceMap.CollectionEnabled) {
        return [PSCustomObject]@{
            Status            = 'NotCollected'
            Verified          = $false
            PartnerServer     = $null
            PartnerServers    = @()
            RelationshipNames = @()
            EvidenceSource    = 'Failover component excluded'
        }
    }

    if ($EvidenceMap.CollectionStatus -and $EvidenceMap.CollectionStatus.Success) {
        return [PSCustomObject]@{
            Status            = 'Missing'
            Verified          = $true
            PartnerServer     = $null
            PartnerServers    = @()
            RelationshipNames = @()
            EvidenceSource    = 'Successful bulk relationship enumeration'
        }
    }

    [PSCustomObject]@{
        Status            = 'Unknown'
        Verified          = $false
        PartnerServer     = $null
        PartnerServers    = @()
        RelationshipNames = @()
        EvidenceSource    = if ($EvidenceMap.CollectionStatus -and $EvidenceMap.CollectionStatus.ErrorMessage) { $EvidenceMap.CollectionStatus.ErrorMessage } else { 'Failover relationship enumeration did not complete' }
    }
}
