function Get-WinADDHCPFailoverAnalysis {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $DHCPSummary
    )

    # Prepare containers for analysis results
    $OnlyOnPrimary   = [System.Collections.Generic.List[Object]]::new()
    $OnlyOnSecondary = [System.Collections.Generic.List[Object]]::new()
    $MissingOnBoth   = [System.Collections.Generic.List[Object]]::new()
    $Stale           = [System.Collections.Generic.List[Object]]::new()
    $PerSubnetIssues = [System.Collections.Generic.List[Object]]::new()

    if (-not $DHCPSummary.FailoverRelationships -or $DHCPSummary.FailoverRelationships.Count -eq 0) {
        # No relationships at all. Still populate per-subnet issues so UI has a clear list.
        foreach ($scope in $DHCPSummary.Scopes) {
            if ($scope.State -eq 'Active' -and (-not $scope.FailoverPartner)) {
                $PerSubnetIssues.Add([PSCustomObject]@{
                    Relationship     = $null
                    PrimaryServer    = $scope.ServerName.ToLower()
                    SecondaryServer  = $null
                    ScopeId          = $scope.ScopeId
                    Issue            = 'No failover configured'
                })
            }
        }

        $DHCPSummary.FailoverAnalysis = [ordered]@{
            OnlyOnPrimary     = $OnlyOnPrimary
            OnlyOnSecondary   = $OnlyOnSecondary
            MissingOnBoth     = $MissingOnBoth
            StaleRelationships= $Stale
            PerSubnetIssues   = $PerSubnetIssues
        }
        return
    }

    # Helpers
    function _NormName([string]$n) { if ($null -eq $n) { return $null } return $n.Trim().ToLower() }
    function _IssueKey([string]$a,[string]$b,[string]$sid,[string]$issue) {
        # Stable key for deduplication of per-subnet rows
        $x = @($a,$b) | Sort-Object
        return ($x -join '↔') + '|' + $sid + '|' + $issue
    }

    # Build aggregated view by normalized server pair (ignore relationship Name for matching)
    # Also track per-scope relationship names on each side for better reporting
    $byPair = @{}
    foreach ($rel in $DHCPSummary.FailoverRelationships) {
        if (-not $rel) { continue }
        $a = _NormName $rel.ServerName
        $b = _NormName $rel.PartnerServer
        $sorted = @($a,$b) | Sort-Object
        $pairKey = $sorted -join '↔'
        if (-not $byPair.ContainsKey($pairKey)) {
            $byPair[$pairKey] = [ordered]@{
                ServerA  = $sorted[0]
                ServerB  = $sorted[1]
                ScopesA  = New-Object System.Collections.Generic.HashSet[string]
                ScopesB  = New-Object System.Collections.Generic.HashSet[string]
                NameMapA = @{}
                NameMapB = @{}
            }
        }

        $scopeList = @()
        if ($null -ne $rel.ScopeId) { $scopeList = @($rel.ScopeId | ForEach-Object { ([string]$_).Trim() }) }
        if ($scopeList.Count -eq 0) {
            # Stale relationship (no subnets attached)
            $Stale.Add([PSCustomObject]@{
                Relationship    = $rel.Name
                PrimaryServer   = $sorted[0]
                SecondaryServer = $sorted[1]
                Mode            = $rel.Mode
                State           = $rel.State
                ScopeCount      = 0
            })
        }

        foreach ($sid in $scopeList) {
            $sidStr = [string]$sid
            if ($rel.ServerName.ToLower() -eq $byPair[$pairKey].ServerA) {
                [void]$byPair[$pairKey].ScopesA.Add($sidStr)
                if (-not $byPair[$pairKey].NameMapA.ContainsKey($sidStr)) { $byPair[$pairKey].NameMapA[$sidStr] = New-Object System.Collections.Generic.HashSet[string] }
                [void]$byPair[$pairKey].NameMapA[$sidStr].Add([string]$rel.Name)
            } else {
                [void]$byPair[$pairKey].ScopesB.Add($sidStr)
                if (-not $byPair[$pairKey].NameMapB.ContainsKey($sidStr)) { $byPair[$pairKey].NameMapB[$sidStr] = New-Object System.Collections.Generic.HashSet[string] }
                [void]$byPair[$pairKey].NameMapB[$sidStr].Add([string]$rel.Name)
            }
        }
    }

    # Set used to ensure we don't duplicate per-subnet rows across pairs or variations
    $perSubnetKeys = New-Object System.Collections.Generic.HashSet[string]

    foreach ($pair in $byPair.Values) {
        $scopesA = @($pair.ScopesA)
        $scopesB = @($pair.ScopesB)

        # Differences (union across all relationships for this pair)
        $diff = Compare-Object -ReferenceObject $scopesA -DifferenceObject $scopesB
        foreach ($d in $diff) {
            $scopeId = [string]$d.InputObject
            if ($d.SideIndicator -eq '<=') {
                $relName = if ($pair.NameMapA.ContainsKey($scopeId)) { (@($pair.NameMapA[$scopeId]) -join ', ') } else { $null }
                $obj = [PSCustomObject]@{
                    Relationship     = $relName
                    PrimaryServer    = $pair.ServerA
                    SecondaryServer  = $pair.ServerB
                    ScopeId          = $scopeId
                    Issue            = "Missing on $($pair.ServerB)"
                }
                if ($perSubnetKeys.Add((_IssueKey $pair.ServerA $pair.ServerB $scopeId $obj.Issue))) {
                    $OnlyOnPrimary.Add($obj)
                    $PerSubnetIssues.Add($obj)
                }
            } elseif ($d.SideIndicator -eq '=>') {
                $relName = if ($pair.NameMapB.ContainsKey($scopeId)) { (@($pair.NameMapB[$scopeId]) -join ', ') } else { $null }
                $obj = [PSCustomObject]@{
                    Relationship     = $relName
                    PrimaryServer    = $pair.ServerA
                    SecondaryServer  = $pair.ServerB
                    ScopeId          = $scopeId
                    Issue            = "Missing on $($pair.ServerA)"
                }
                if ($perSubnetKeys.Add((_IssueKey $pair.ServerA $pair.ServerB $scopeId $obj.Issue))) {
                    $OnlyOnSecondary.Add($obj)
                    $PerSubnetIssues.Add($obj)
                }
            }
        }

        # Missing on both: scope exists on both servers but is not assigned to any relationship on either side
        $scopesOnA = @($DHCPSummary.Scopes | Where-Object { $_.ServerName -and $_.ServerName.ToLower() -eq $pair.ServerA } | Select-Object -ExpandProperty ScopeId -Unique)
        $scopesOnB = @($DHCPSummary.Scopes | Where-Object { $_.ServerName -and $_.ServerName.ToLower() -eq $pair.ServerB } | Select-Object -ExpandProperty ScopeId -Unique)
        $commonScopes = @($scopesOnA | Where-Object { $scopesOnB -contains $_ })
        foreach ($s in $commonScopes) {
            $sStr = [string]$s
            if ($scopesA -notcontains $sStr -and $scopesB -notcontains $sStr) {
                $obj = [PSCustomObject]@{
                    Relationship     = $null
                    PrimaryServer    = $pair.ServerA
                    SecondaryServer  = $pair.ServerB
                    ScopeId          = $sStr
                    Issue            = 'Missing from both partners'
                }
                if ($perSubnetKeys.Add((_IssueKey $pair.ServerA $pair.ServerB $sStr $obj.Issue))) {
                    $MissingOnBoth.Add($obj)
                    $PerSubnetIssues.Add($obj)
                }
            }
        }
    }

    # Add standalone "no failover configured" entries for scopes that didn't fall into any pair-based bucket
    foreach ($scope in $DHCPSummary.Scopes) {
        if ($scope.State -ne 'Active' -or $scope.FailoverPartner) { continue }
        $sid = ([string]$scope.ScopeId).Trim()
        $srv = (_NormName $scope.ServerName)
        $exists = $false
        foreach ($i in $PerSubnetIssues) {
            if ($i.ScopeId -eq $sid -and ($i.PrimaryServer -eq $srv -or $i.SecondaryServer -eq $srv)) { $exists = $true; break }
        }
        if (-not $exists) {
            $obj = [PSCustomObject]@{
                Relationship     = $null
                PrimaryServer    = $srv
                SecondaryServer  = $null
                ScopeId          = $sid
                Issue            = 'No failover configured'
            }
            if ($perSubnetKeys.Add((_IssueKey $srv $null $sid $obj.Issue))) {
                $PerSubnetIssues.Add($obj)
            }
        }
    }

    $DHCPSummary.FailoverAnalysis = [ordered]@{
        OnlyOnPrimary     = $OnlyOnPrimary   # Note: Primary/Secondary here mean ServerA/ServerB (alphabetical), not HA roles
        OnlyOnSecondary   = $OnlyOnSecondary
        MissingOnBoth     = $MissingOnBoth
        StaleRelationships= $Stale
        PerSubnetIssues   = $PerSubnetIssues
    }
}

