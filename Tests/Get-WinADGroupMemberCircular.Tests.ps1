# Tests for circular-membership detection in Get-WinADGroupMember / Get-WinADGroupMemberOf (issue #39).
# The functions under test are dot-sourced directly and Get-WinADObject is replaced with an in-memory
# group graph, because Get-WinADObject is called module-internally and cannot be mocked across the
# module boundary - and circular group graphs are not practical to create in a real test domain.
BeforeAll {
    . "$PSScriptRoot\..\Private\ConvertTo-WinADCircularPath.ps1"
    . "$PSScriptRoot\..\Private\Find-WinADGroupCircularChain.ps1"
    . "$PSScriptRoot\..\Public\Get-WinADGroupMember.ps1"
    . "$PSScriptRoot\..\Public\Get-WinADGroupMemberOf.ps1"

    function ConvertFrom-DistinguishedName {
        [CmdletBinding()] param($DistinguishedName, [switch] $ToDomainCN)
        'test.local'
    }
    function Get-WinADObject {
        [CmdletBinding()]
        param([Parameter(Position = 0)] $Identity, [switch] $IncludeGroupMembership)
        foreach ($Item in $Identity) {
            if ($Item -is [System.Management.Automation.PSObject] -and $Item.PSObject.Properties['DistinguishedName'] -and $Item.DistinguishedName) {
                $DN = $Item.DistinguishedName
            } else {
                $DN = "$Item"
                if (-not $Script:TestGraph.ContainsKey($DN)) {
                    $Found = $Script:TestGraph.Values | Where-Object { $_.Name -eq "$Item" } | Select-Object -First 1
                    if ($Found) { $DN = $Found.DistinguishedName }
                }
            }
            $Script:TestGraph[$DN]
        }
    }
    function Get-TestDN([string] $Name) { "CN=$Name,DC=test,DC=local" }
    function Set-TestGraph {
        # $Members maps group name -> member names; MemberOf is derived. Names listed in $Users become user objects.
        param([System.Collections.IDictionary] $Members, [string[]] $Users = @())
        $Script:TestGraph = @{}
        $AllNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($GroupName in $Members.Keys) {
            $null = $AllNames.Add($GroupName)
            foreach ($MemberName in $Members[$GroupName]) { $null = $AllNames.Add($MemberName) }
        }
        foreach ($Name in $AllNames) {
            $Script:TestGraph[(Get-TestDN $Name)] = [PSCustomObject] @{
                Name              = $Name
                SamAccountName    = $Name
                DisplayName       = $Name
                Enabled           = $true
                ObjectClass       = if ($Users -contains $Name) { 'user' } else { 'group' }
                GroupType         = 'Security'
                GroupScope        = 'Universal'
                DomainName        = 'test.local'
                DistinguishedName = (Get-TestDN $Name)
                ObjectSID         = "S-1-5-21-0-0-0-$Name"
                Members           = @(foreach ($MemberName in $Members[$Name]) { Get-TestDN $MemberName })
                MemberOf          = @(foreach ($GroupName in $Members.Keys) { if ($Members[$GroupName] -contains $Name) { Get-TestDN $GroupName } })
            }
        }
        # Prime the module-level caches so the functions skip forest discovery and start clean per test
        $Script:WinADGroupMemberCache = @{}
        $Script:WinADGroupObjectCache = @{}
        $Script:WinADCircularChainMemo = @{}
        $Script:WinADCircularChainMemoWeight = 0
        $Script:WinADCircularChainWarned = $null
        $Script:WinADCircularChainMaximumNodes = $null
        $Script:WinADCircularChainMemoMaximumWeight = $null
        $Script:WinADForestCache = @{ Forest = $null; Domains = @('test.local') }
    }
}

Describe 'Issue #39 diamond (multi-path nesting) is not circular' {
    BeforeEach {
        # A contains B; B contains C and D; C contains D - two paths to D, no circle
        Set-TestGraph -Members ([ordered] @{ A = 'B'; B = 'C', 'D'; C = 'D' })
    }
    It 'Get-WinADGroupMemberOf from D reports no circular membership' {
        $Results = Get-WinADGroupMemberOf -Identity 'D'
        $Results.Count | Should -Be 5
        $Results.CircularDirect | Should -Not -Contain $true
        $Results.CircularIndirect | Should -Not -Contain $true
        ($Results.CircularPath | Where-Object { $_ }) | Should -BeNullOrEmpty
    }
    It 'Get-WinADGroupMember from A reports no circular membership' {
        $Results = Get-WinADGroupMember -Identity 'A' -All
        $Results.CircularDirect | Should -Not -Contain $true
        $Results.CircularIndirect | Should -Not -Contain $true
        ($Results.CircularPath | Where-Object { $_ }) | Should -BeNullOrEmpty
    }
}

Describe 'Direct circular membership' {
    It 'flags a mutual pair with the pair chain in both directions' {
        Set-TestGraph -Members ([ordered] @{ X = 'Y'; Y = 'X' })
        $MemberRows = Get-WinADGroupMember -Identity 'X' -All
        @($MemberRows | Where-Object { $_.CircularDirect }).Count | Should -BeGreaterThan 0
        @($MemberRows | Where-Object { $_.CircularDirect })[0].CircularPath | Should -Be 'X -> Y -> X'
        $MemberOfRows = Get-WinADGroupMemberOf -Identity 'X'
        @($MemberOfRows | Where-Object { $_.CircularDirect }).Count | Should -BeGreaterThan 0
    }
    It 'flags self-membership as direct only' {
        Set-TestGraph -Members ([ordered] @{ A = 'A', 'B'; B = @() })
        $Rows = Get-WinADGroupMember -Identity 'A' -All
        $SelfRow = @($Rows | Where-Object { $_.ParentGroup -eq 'A' -and $_.Name -eq 'A' })
        $SelfRow.Count | Should -Be 1
        $SelfRow[0].CircularDirect | Should -BeTrue
        $SelfRow[0].CircularIndirect | Should -BeFalse
        $SelfRow[0].CircularPath | Should -Be 'A -> A -> A'
    }
}

Describe 'Indirect three-group circle' {
    BeforeEach {
        Set-TestGraph -Members ([ordered] @{ G1 = 'G2'; G2 = 'G3'; G3 = 'G1' })
    }
    It 'is flagged exactly once with the full circle rendered (Members direction)' {
        $Rows = Get-WinADGroupMember -Identity 'G1' -All
        $Flagged = @($Rows | Where-Object { $_.CircularIndirect })
        $Flagged.Count | Should -Be 1
        $Flagged[0].CircularPath | Should -Be 'G1 -> G2 -> G3 -> G1'
        $Rows.CircularDirect | Should -Not -Contain $true
    }
    It 'is flagged exactly once with the full circle rendered (MemberOf direction)' {
        $Rows = Get-WinADGroupMemberOf -Identity 'G1'
        $Flagged = @($Rows | Where-Object { $_.CircularIndirect })
        $Flagged.Count | Should -Be 1
        $Flagged[0].CircularPath | Should -Be 'G1 -> G3 -> G2 -> G1'
    }
}

Describe 'Diamond combined with a real circle' {
    It 'flags each real circle once and leaves the diamond re-visit unflagged' {
        # A>B>C>D>A is a circle; B also contains D directly, creating a diamond on top of it
        Set-TestGraph -Members ([ordered] @{ A = 'B'; B = 'C', 'D'; C = 'D'; D = 'A' })
        $Rows = Get-WinADGroupMember -Identity 'A' -All
        $Flagged = @($Rows | Where-Object { $_.CircularIndirect })
        $Flagged.Count | Should -Be 2
        @($Flagged | Where-Object { $_.CircularPath -eq 'A -> B -> C -> D -> A' }).Count | Should -Be 1
        @($Flagged | Where-Object { $_.CircularPath -eq 'D -> A -> B -> D' }).Count | Should -Be 1
    }
}

Describe 'Circle hidden behind loop-prevention truncation' {
    It 'is still reported once with its full chain' {
        # S>M>Q, Q<->D2 (direct pair triggers truncation), Q>P, S>R>P, P>M closes M>Q>P>M
        Set-TestGraph -Members ([ordered] @{ S = 'M', 'R'; M = 'Q'; Q = 'D2', 'P'; D2 = 'Q'; R = 'P'; P = 'M' })
        $Rows = Get-WinADGroupMember -Identity 'S' -All
        $Flagged = @($Rows | Where-Object { $_.CircularIndirect })
        $Flagged.Count | Should -Be 1
        $Flagged[0].CircularPath | Should -Be 'M -> Q -> P -> M'
    }
}

Describe 'Traversal path that revisits a group' {
    It 'renders the tightest simple circle instead of a walk with repeats' {
        Set-TestGraph -Members ([ordered] @{ R = 'A'; A = 'B', 'X'; B = 'C'; C = 'A'; X = 'R' })
        $Rows = Get-WinADGroupMember -Identity 'R' -All
        $XRRow = @($Rows | Where-Object { $_.ParentGroup -eq 'X' -and $_.Name -eq 'R' -and $_.CircularIndirect })
        $XRRow.Count | Should -BeGreaterThan 0
        $XRRow[0].CircularPath | Should -Be 'R -> A -> X -> R'
    }
}

Describe 'Bounded circular search' {
    BeforeEach {
        # Diamond head S>H via two parents, H tops a chain of groups so the verification walk has real work
        Set-TestGraph -Members ([ordered] @{ S = 'P1', 'P2'; P1 = 'H'; P2 = 'H'; H = 'C1'; C1 = 'C2'; C2 = 'C3'; C3 = 'C4'; C4 = @() })
    }
    It 'helper reports LimitReached with a warning when the budget is too small' {
        $Warnings = $null
        $Result = Find-WinADGroupCircularChain -From (Get-TestDN 'H') -To (Get-TestDN 'P2') -Attribute 'Members' -Cache $Script:WinADGroupMemberCache -MaximumNodes 2 -WarningVariable Warnings -WarningAction SilentlyContinue
        $Result.Status | Should -Be 'LimitReached'
        $Result.Chain.Count | Should -Be 0
        "$Warnings" | Should -Match 'unverified'
        $Script:WinADCircularChainMemo.Count | Should -Be 0   # an unfinished walk must not be memoized
    }
    It 'helper proves NotFound and memoizes when the budget suffices' {
        $Result = Find-WinADGroupCircularChain -From (Get-TestDN 'H') -To (Get-TestDN 'P2') -Attribute 'Members' -Cache $Script:WinADGroupMemberCache -MaximumNodes 50
        $Result.Status | Should -Be 'NotFound'
        $Script:WinADCircularChainMemo.Count | Should -Be 1
        $Script:WinADCircularChainMemoWeight | Should -BeGreaterThan 0
    }
    It 'reports the row as unverified instead of clean when the walk is cut short' {
        $Script:WinADCircularChainMaximumNodes = 2
        $Rows = Get-WinADGroupMember -Identity 'S' -All -WarningAction SilentlyContinue
        $HRows = @($Rows | Where-Object { $_.Name -eq 'H' })
        $Unverified = @($HRows | Where-Object { $_.CircularPath -eq 'Unverified - search limit reached' })
        $Unverified.Count | Should -Be 1
        $Unverified[0].CircularIndirect | Should -BeNullOrEmpty   # unknown - neither proven nor disproven
        ($Rows | Where-Object { $_.CircularIndirect }) | Should -BeNullOrEmpty
    }
    It 'flags the same row normally when the budget suffices' {
        $Rows = Get-WinADGroupMember -Identity 'S' -All
        @($Rows | Where-Object { $_.CircularPath -eq 'Unverified - search limit reached' }).Count | Should -Be 0
        @($Rows | Where-Object { $_.CircularIndirect }).Count | Should -Be 0
        @($Rows | Where-Object { $_.CircularIndirect -eq $null -and $_.Type -eq 'group' }).Count | Should -Be 0
    }
    It 'a truncation-hidden circle degrades to unverified, never to a silent pass' {
        Set-TestGraph -Members ([ordered] @{ S = 'M', 'R'; M = 'Q'; Q = 'D2', 'P'; D2 = 'Q'; R = 'P'; P = 'M' })
        $Script:WinADCircularChainMaximumNodes = 1
        $Rows = Get-WinADGroupMember -Identity 'S' -All -WarningAction SilentlyContinue
        @($Rows | Where-Object { $_.CircularIndirect }).Count | Should -Be 0
        @($Rows | Where-Object { $_.CircularPath -eq 'Unverified - search limit reached' }).Count | Should -BeGreaterThan 0
    }
    It 'does not spend budget on user objects in flat groups' {
        $Members = [ordered] @{ S = 'P1', 'P2'; P1 = 'H'; P2 = 'H'; H = @(foreach ($i in 1..50) { "User$i" }) }
        Set-TestGraph -Members $Members -Users @(foreach ($i in 1..50) { "User$i" })
        $Script:WinADCircularChainMaximumNodes = 5
        $Rows = Get-WinADGroupMember -Identity 'S' -All
        # 50 users would exhaust a budget of 5 if they were enqueued; only groups may consume it
        @($Rows | Where-Object { $_.CircularPath -eq 'Unverified - search limit reached' }).Count | Should -Be 0
        @($Rows | Where-Object { $_.CircularIndirect }).Count | Should -Be 0
    }
    It 'stops growing the memo once the weight cap is reached' {
        $Script:WinADCircularChainMemoMaximumWeight = 3
        $Result = Find-WinADGroupCircularChain -From (Get-TestDN 'H') -To (Get-TestDN 'P2') -Attribute 'Members' -Cache $Script:WinADGroupMemberCache -MaximumNodes 50
        $Result.Status | Should -Be 'NotFound'
        $Script:WinADCircularChainMemo.Count | Should -Be 0   # closure of 5 groups exceeds the cap of 3
        $Script:WinADCircularChainMemoWeight | Should -Be 0
    }
}
