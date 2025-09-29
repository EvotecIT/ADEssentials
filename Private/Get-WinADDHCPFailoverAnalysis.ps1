function Get-WinADDHCPFailoverAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    # Prepare containers for analysis results
    $OnlyOnPrimary   = [System.Collections.Generic.List[Object]]::new()
    $OnlyOnSecondary = [System.Collections.Generic.List[Object]]::new()
    $MissingOnBoth   = [System.Collections.Generic.List[Object]]::new()

    if (-not $DHCPSummary.FailoverRelationships -or $DHCPSummary.FailoverRelationships.Count -eq 0) {
        # Nothing to analyze
        $DHCPSummary.FailoverAnalysis = [ordered]@{
            OnlyOnPrimary   = $OnlyOnPrimary
            OnlyOnSecondary = $OnlyOnSecondary
            MissingOnBoth   = $MissingOnBoth
        }
        return
    }

    # Group relationships by pair (relationship name + normalized partner tuple)
    $pairs = @{}
    foreach ($rel in $DHCPSummary.FailoverRelationships) {
        $a = $rel.ServerName.ToLower()
        $b = $rel.PartnerServer.ToLower()
        $sorted = @($a,$b) | Sort-Object
        $pairKey = "$($rel.Name.ToLower())|$($sorted -join '↔')"
        if (-not $pairs.ContainsKey($pairKey)) {
            $pairs[$pairKey] = [ordered]@{
                Name = $rel.Name
                ServerA = $sorted[0]
                ServerB = $sorted[1]
                RelA = $null
                RelB = $null
            }
        }
        if ($rel.ServerName.ToLower() -eq $pairs[$pairKey].ServerA) {
            $pairs[$pairKey].RelA = $rel
        } else {
            $pairs[$pairKey].RelB = $rel
        }
    }

    foreach ($pair in $pairs.Values) {
        $relA = $pair.RelA
        $relB = $pair.RelB

        # Normalize lists
        $scopesA = @()
        $scopesB = @()
        if ($relA -and $relA.ScopeId) { $scopesA = @($relA.ScopeId) } else { $scopesA = @() }
        if ($relB -and $relB.ScopeId) { $scopesB = @($relB.ScopeId) } else { $scopesB = @() }

        # Compare differences
        $diff = Compare-Object -ReferenceObject $scopesA -DifferenceObject $scopesB
        foreach ($d in $diff) {
            $scopeId = $d.InputObject
            if ($d.SideIndicator -eq '<=') {
                # Present only on ServerA (treat as Primary for the pair)
                $OnlyOnPrimary.Add([PSCustomObject]@{
                    Relationship   = $pair.Name
                    PrimaryServer  = $pair.ServerA
                    SecondaryServer= $pair.ServerB
                    ScopeId        = $scopeId
                    Issue          = 'Present only on primary'
                })
            } elseif ($d.SideIndicator -eq '=>') {
                # Present only on ServerB (treat as Secondary)
                $OnlyOnSecondary.Add([PSCustomObject]@{
                    Relationship   = $pair.Name
                    PrimaryServer  = $pair.ServerA
                    SecondaryServer= $pair.ServerB
                    ScopeId        = $scopeId
                    Issue          = 'Present only on secondary'
                })
            }
        }

        # Missing on both (refined): only consider scopes that are present on BOTH servers
        # and are not assigned to failover on either partner for this relationship
        $scopesOnA = @($DHCPSummary.Scopes | Where-Object { $_.ServerName -and $_.ServerName.ToLower() -eq $pair.ServerA } | Select-Object -ExpandProperty ScopeId -Unique)
        $scopesOnB = @($DHCPSummary.Scopes | Where-Object { $_.ServerName -and $_.ServerName.ToLower() -eq $pair.ServerB } | Select-Object -ExpandProperty ScopeId -Unique)
        $commonScopes = @($scopesOnA | Where-Object { $scopesOnB -contains $_ })
        $assignedUnion = @($scopesA + $scopesB) | Select-Object -Unique
        foreach ($s in $commonScopes) {
            if ($assignedUnion -notcontains $s) {
                $MissingOnBoth.Add([PSCustomObject]@{
                    Relationship    = $pair.Name
                    PrimaryServer   = $pair.ServerA
                    SecondaryServer = $pair.ServerB
                    ScopeId         = $s
                    Issue           = 'Missing from both partners'
                })
            }
        }
    }

    $DHCPSummary.FailoverAnalysis = [ordered]@{
        OnlyOnPrimary   = $OnlyOnPrimary
        OnlyOnSecondary = $OnlyOnSecondary
        MissingOnBoth   = $MissingOnBoth
    }
}

