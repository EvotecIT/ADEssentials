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
                ServerA       = $sortedServers[0]
                ServerB       = $sortedServers[1]
                ScopesA       = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                ScopesB       = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                NamesByScopeA = @{}
                NamesByScopeB = @{}
            }
        }

        $pair = $pairs[$key]
        foreach ($scopeId in @($relationship.ScopeId)) {
            if (-not $scopeId) { continue }
            $scopeIdText = ([string] $scopeId).Trim()
            if ($serverA -eq $pair.ServerA) {
                [void] $pair.ScopesA.Add($scopeIdText)
                if (-not $pair.NamesByScopeA.ContainsKey($scopeIdText)) {
                    $pair.NamesByScopeA[$scopeIdText] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                }
                if ($relationship.Name) { [void] $pair.NamesByScopeA[$scopeIdText].Add([string] $relationship.Name) }
            } else {
                [void] $pair.ScopesB.Add($scopeIdText)
                if (-not $pair.NamesByScopeB.ContainsKey($scopeIdText)) {
                    $pair.NamesByScopeB[$scopeIdText] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                }
                if ($relationship.Name) { [void] $pair.NamesByScopeB[$scopeIdText].Add([string] $relationship.Name) }
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

        foreach ($scopeId in $allScopes) {
            $onA = $scopesA -contains $scopeId
            $onB = $scopesB -contains $scopeId
            $relationshipNamesA = @(if ($pair.NamesByScopeA.ContainsKey($scopeId)) { @($pair.NamesByScopeA[$scopeId]) | Sort-Object })
            $relationshipNamesB = @(if ($pair.NamesByScopeB.ContainsKey($scopeId)) { @($pair.NamesByScopeB[$scopeId]) | Sort-Object })
            $relationshipNames = @($relationshipNamesA + $relationshipNamesB) | Sort-Object -Unique
            $presentPartner = if ($onA -and -not $onB) { $pair.ServerA } elseif ($onB -and -not $onA) { $pair.ServerB } else { $null }
            $missingPartner = if ($onA -and -not $onB) { $pair.ServerB } elseif ($onB -and -not $onA) { $pair.ServerA } else { $null }
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
                Relationship           = $relationshipNames -join ', '
                RelationshipOnPartnerA = $relationshipNamesA -join ', '
                RelationshipOnPartnerB = $relationshipNamesB -join ', '
                Pair                   = '{0} {1} {2}' -f $pair.ServerA, [char] 0x2194, $pair.ServerB
                PartnerA               = $pair.ServerA
                PartnerB               = $pair.ServerB
                PresentPartner         = $presentPartner
                MissingPartner         = $missingPartner
                ScopeId                = $scopeId
                OnPartnerA             = $onA
                OnPartnerB             = $onB
                VerifiedFromBothSides  = $verified
                Status                 = $status
                FailoverConfiguration  = $failoverConfiguration
            }
        }
    }
}
