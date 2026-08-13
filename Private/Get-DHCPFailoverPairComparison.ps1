function Get-DHCPFailoverPairComparison {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPSummary
    )

    $enumeratedServers = Get-DHCPFailoverEnumeratedServerSet -DHCPSummary $DHCPSummary
    $pairs = @{}

    foreach ($relationship in @($DHCPSummary.FailoverRelationships)) {
        $serverA = Resolve-DHCPServerName -Name $relationship.ServerName -DHCPSummary $DHCPSummary
        $serverB = Resolve-DHCPServerName -Name $relationship.PartnerServer -DHCPSummary $DHCPSummary
        if (-not $serverA -or -not $serverB) { continue }

        $sortedServers = @($serverA, $serverB) | Sort-Object
        $key = $sortedServers -join '|'
        if (-not $pairs.ContainsKey($key)) {
            $pairs[$key] = [ordered]@{
                Names    = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                ServerA  = $sortedServers[0]
                ServerB  = $sortedServers[1]
                ScopesA  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                ScopesB  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
        }

        $pair = $pairs[$key]
        if ($relationship.Name) { [void] $pair.Names.Add([string] $relationship.Name) }
        foreach ($scopeId in @($relationship.ScopeId)) {
            if (-not $scopeId) { continue }
            if ($serverA -eq $pair.ServerA) {
                [void] $pair.ScopesA.Add(([string] $scopeId).Trim())
            } else {
                [void] $pair.ScopesB.Add(([string] $scopeId).Trim())
            }
        }
    }

    foreach ($pair in @($pairs.Values | Sort-Object ServerA, ServerB)) {
        $scopesA = @($pair.ScopesA)
        $scopesB = @($pair.ScopesB)
        $scopesOnA = @(
            $DHCPSummary.Scopes |
                Where-Object {
                    if (-not $_.ServerName) { return $false }
                    (Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPSummary) -eq $pair.ServerA
                } |
                ForEach-Object { ([string] $_.ScopeId).Trim() } |
                Sort-Object -Unique
        )
        $scopesOnB = @(
            $DHCPSummary.Scopes |
                Where-Object {
                    if (-not $_.ServerName) { return $false }
                    (Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPSummary) -eq $pair.ServerB
                } |
                ForEach-Object { ([string] $_.ScopeId).Trim() } |
                Sort-Object -Unique
        )
        $commonScopes = @($scopesOnA | Where-Object { $scopesOnB -contains $_ })
        $allScopes = @($scopesA + $scopesB + $commonScopes) | Sort-Object -Unique
        $verified = $enumeratedServers.Contains($pair.ServerA) -and $enumeratedServers.Contains($pair.ServerB)
        $relationshipNames = @($pair.Names) | Sort-Object

        foreach ($scopeId in $allScopes) {
            $onA = $scopesA -contains $scopeId
            $onB = $scopesB -contains $scopeId
            $statusBase = if ($onA -and $onB) { 'On both partners' } elseif ($onA) { "Missing on $($pair.ServerB)" } elseif ($onB) { "Missing on $($pair.ServerA)" } else { 'Missing on both' }
            $status = $statusBase + $(if (-not $verified) { ' (Unverified)' } else { '' })
            $failoverConfiguration = if (-not $verified) {
                'unverified'
            } elseif ($statusBase -eq 'Missing on both') {
                'missing on both'
            } elseif ($statusBase -like 'Missing on *') {
                'missing on one partner'
            } else {
                'configured'
            }

            [PSCustomObject]@{
                Relationship          = $relationshipNames -join ', '
                Pair                  = '{0} {1} {2}' -f $pair.ServerA, [char] 0x2194, $pair.ServerB
                PartnerA              = $pair.ServerA
                PartnerB              = $pair.ServerB
                ScopeId               = $scopeId
                OnPartnerA            = $onA
                OnPartnerB            = $onB
                VerifiedFromBothSides = $verified
                Status                = $status
                FailoverConfiguration = $failoverConfiguration
            }
        }
    }
}
