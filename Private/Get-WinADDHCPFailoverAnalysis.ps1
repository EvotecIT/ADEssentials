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
    $UnverifiedScopes = [System.Collections.Generic.List[Object]]::new()

    $enumeratedServers = Get-DHCPFailoverEnumeratedServerSet -DHCPSummary $DHCPSummary

    # Build aggregated view by normalized server pair (ignore relationship Name for matching)
    # Also track per-scope relationship names on each side for better reporting
    $byPair = @{}
    foreach ($rel in $DHCPSummary.FailoverRelationships) {
        if (-not $rel) { continue }
        # Canonicalize partner names to FQDNs where possible to avoid short/FQDN mismatches
        $a = Resolve-DHCPServerName -Name $rel.ServerName -DHCPSummary $DHCPSummary
        $b = Resolve-DHCPServerName -Name $rel.PartnerServer -DHCPSummary $DHCPSummary
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
                Sources  = New-Object System.Collections.Generic.HashSet[string]  # servers we enumerated this pair from
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
            # Use canonicalized name for side selection as well
            if ($a -eq $byPair[$pairKey].ServerA) {
                [void]$byPair[$pairKey].ScopesA.Add($sidStr)
                if (-not $byPair[$pairKey].NameMapA.ContainsKey($sidStr)) { $byPair[$pairKey].NameMapA[$sidStr] = New-Object System.Collections.Generic.HashSet[string] }
                [void]$byPair[$pairKey].NameMapA[$sidStr].Add([string]$rel.Name)
            } else {
                [void]$byPair[$pairKey].ScopesB.Add($sidStr)
                if (-not $byPair[$pairKey].NameMapB.ContainsKey($sidStr)) { $byPair[$pairKey].NameMapB[$sidStr] = New-Object System.Collections.Generic.HashSet[string] }
                [void]$byPair[$pairKey].NameMapB[$sidStr].Add([string]$rel.Name)
            }
        }

        # Track which side(s) we successfully enumerated for this pair
        if ($rel.PSObject.Properties.Name -contains 'GatheredFrom' -and $rel.GatheredFrom) {
            $g = Resolve-DHCPServerName -Name $rel.GatheredFrom -DHCPSummary $DHCPSummary
            if ($g) { [void]$byPair[$pairKey].Sources.Add($g) }
        }
    }

    # Set used to ensure we don't duplicate per-subnet rows across pairs or variations
    $perSubnetKeys = New-Object System.Collections.Generic.HashSet[string]

    foreach ($pair in $byPair.Values) {
        $scopesA = @($pair.ScopesA)
        $scopesB = @($pair.ScopesB)

        # Differences (union across all relationships for this pair)
        $diff = Compare-Object -ReferenceObject $scopesA -DifferenceObject $scopesB
        $verified = ($enumeratedServers.Contains($pair.ServerA) -and $enumeratedServers.Contains($pair.ServerB))
        foreach ($d in $diff) {
            $scopeId = [string]$d.InputObject
            if (-not $verified) {
                $UnverifiedScopes.Add([PSCustomObject]@{
                    Relationship     = $null
                    PrimaryServer    = $pair.ServerA
                    SecondaryServer  = $pair.ServerB
                    ScopeId          = $scopeId
                    Issue            = 'Failover consistency could not be verified on both partners'
                    Verified         = $false
                })
                continue
            }
            if ($d.SideIndicator -eq '<=') {
                $relName = if ($pair.NameMapA.ContainsKey($scopeId)) { (@($pair.NameMapA[$scopeId]) -join ', ') } else { $null }
                $obj = [PSCustomObject]@{
                    Relationship     = $relName
                    PrimaryServer    = $pair.ServerA
                    SecondaryServer  = $pair.ServerB
                    ScopeId          = $scopeId
                    Issue            = "Missing on $($pair.ServerB)"
                    Verified         = $verified
                }
                if ($perSubnetKeys.Add((Get-FailoverIssueKey -ServerA $pair.ServerA -ServerB $pair.ServerB -ScopeId $scopeId -Issue $obj.Issue))) {
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
                    Verified         = $verified
                }
                if ($perSubnetKeys.Add((Get-FailoverIssueKey -ServerA $pair.ServerA -ServerB $pair.ServerB -ScopeId $scopeId -Issue $obj.Issue))) {
                    $OnlyOnSecondary.Add($obj)
                    $PerSubnetIssues.Add($obj)
                }
            }
        }

        # Missing on both: scope exists on both servers but is not assigned to any relationship on either side
        # Use canonicalized server names for comparison to avoid short vs FQDN mismatches
        $scopesOnA = @(
            $DHCPSummary.Scopes |
                Where-Object {
                    if (-not $_.ServerName) { return $false }
                    $srv = Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPSummary
                    return ($srv -eq $pair.ServerA)
                } |
                Select-Object -ExpandProperty ScopeId -Unique
        )
        $scopesOnB = @(
            $DHCPSummary.Scopes |
                Where-Object {
                    if (-not $_.ServerName) { return $false }
                    $srv = Resolve-DHCPServerName -Name $_.ServerName -DHCPSummary $DHCPSummary
                    return ($srv -eq $pair.ServerB)
                } |
                Select-Object -ExpandProperty ScopeId -Unique
        )
        $commonScopes = @($scopesOnA | Where-Object { $scopesOnB -contains $_ })
        foreach ($s in $commonScopes) {
            $sStr = [string]$s
            if ($verified -and $scopesA -notcontains $sStr -and $scopesB -notcontains $sStr) {
                $obj = [PSCustomObject]@{
                    Relationship     = $null
                    PrimaryServer    = $pair.ServerA
                    SecondaryServer  = $pair.ServerB
                    ScopeId          = $sStr
                    Issue            = 'Missing from both partners'
                    Verified         = $true
                }
                if ($perSubnetKeys.Add((Get-FailoverIssueKey -ServerA $pair.ServerA -ServerB $pair.ServerB -ScopeId $sStr -Issue $obj.Issue))) {
                    $MissingOnBoth.Add($obj)
                    $PerSubnetIssues.Add($obj)
                }
            }
        }
    }

    # Add standalone missing and unverified entries independently of whether
    # unrelated servers returned relationships.
    foreach ($scope in $DHCPSummary.Scopes) {
        if ($scope.State -ne 'Active') { continue }
        $sid = ([string]$scope.ScopeId).Trim()
        $srv = (Resolve-DHCPServerName -Name $scope.ServerName -DHCPSummary $DHCPSummary)
        $failoverStatus = Get-DHCPFailoverScopeStatus -Scope $scope
        $failoverVerified = Test-DHCPFailoverScopeVerified -Scope $scope

        if (-not $failoverVerified) {
            $unverifiedExists = @($UnverifiedScopes | Where-Object {
                $_.ScopeId -eq $sid -and ($_.PrimaryServer -eq $srv -or $_.SecondaryServer -eq $srv)
            }).Count -gt 0
            if (-not $unverifiedExists) {
                $UnverifiedScopes.Add([PSCustomObject]@{
                    Relationship     = $null
                    PrimaryServer    = $srv
                    SecondaryServer  = $null
                    ScopeId          = $sid
                    Issue            = if ($failoverStatus -eq 'NotCollected') { 'Failover data was not collected' } else { 'Failover status could not be verified' }
                    Verified         = $false
                })
            }
            continue
        }

        if ($failoverStatus -ne 'Missing') { continue }
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
                Verified         = $true
            }
            if ($perSubnetKeys.Add((Get-FailoverIssueKey -ServerA $srv -ServerB $null -ScopeId $sid -Issue $obj.Issue))) {
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
        UnverifiedScopes  = $UnverifiedScopes
    }
}
