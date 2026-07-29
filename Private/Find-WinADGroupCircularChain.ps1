function Find-WinADGroupCircularChain {
    <#
    .SYNOPSIS
    Finds a nested membership chain leading from one group back to another, if one exists.

    .DESCRIPTION
    Finds a nested membership chain leading from one group back to another by walking the requested membership attribute breadth-first.
    Used to decide whether a group that was already visited on another branch of a traversal really closes a circle with the current group,
    or is simply reachable over more than one path (which is not circular).
    Already resolved objects are taken from the provided cache; unresolved objects are queried once and added to the cache.
    Only groups are expanded and enqueued - objects the cache already knows are not groups cannot continue a circle,
    so large flat memberships do not consume the search budget.

    The walk is bounded. It inspects at most MaximumNodes objects and gives up with Status 'LimitReached' when the budget
    is exhausted, so an unfinished search is never mistaken for a proven non-circle. Walks that finish without finding the
    target remember everything reachable from the starting group in $Script:WinADCircularChainMemo (so a group nested under
    many parents is checked once, not once per parent), and the total number of retained references is capped - once the
    cap is reached further walks simply run without memoization instead of growing memory.

    Returns an object with two properties:
    - Status : 'Found' (Chain holds the membership chain), 'NotFound' (proven - no chain exists), 'LimitReached' (unknown - budget exhausted)
    - Chain  : chain of distinguished names from From to To; empty unless Status is 'Found'

    .PARAMETER From
    Distinguished name of the group to start walking from.

    .PARAMETER To
    Distinguished name of the group to find.

    .PARAMETER Attribute
    Membership attribute to walk - Members (downwards) or MemberOf (upwards).

    .PARAMETER Cache
    Dictionary of already resolved AD objects, keyed by distinguished name.

    .PARAMETER MaximumNodes
    Maximum number of objects the walk may inspect before giving up with Status 'LimitReached'.
    Defaults to $Script:WinADCircularChainMaximumNodes when that variable is set, otherwise 5000.

    .PARAMETER MaximumMemoWeight
    Maximum total number of distinguished-name references kept across all memoized walk results.
    Defaults to $Script:WinADCircularChainMemoMaximumWeight when that variable is set, otherwise 100000.

    .EXAMPLE
    Find-WinADGroupCircularChain -From 'CN=GroupC,DC=ad,DC=local' -To 'CN=GroupA,DC=ad,DC=local' -Attribute 'Members' -Cache $Cache
    Returns Status 'Found' with Chain 'CN=GroupC,...', 'CN=GroupB,...', 'CN=GroupA,...' when GroupC contains GroupB which contains GroupA.
    Returns Status 'NotFound' with an empty Chain when GroupC provably does not lead to GroupA.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $From,
        [Parameter(Mandatory)][string] $To,
        [Parameter(Mandatory)][ValidateSet('Members', 'MemberOf')][string] $Attribute,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Cache,
        [int] $MaximumNodes = $(if ($Script:WinADCircularChainMaximumNodes) { $Script:WinADCircularChainMaximumNodes } else { 5000 }),
        [int] $MaximumMemoWeight = $(if ($Script:WinADCircularChainMemoMaximumWeight) { $Script:WinADCircularChainMemoMaximumWeight } else { 100000 })
    )
    if (-not $Script:WinADCircularChainMemo) {
        $Script:WinADCircularChainMemo = @{}
    }
    if (-not $Script:WinADCircularChainMemoWeight) {
        $Script:WinADCircularChainMemoWeight = 0
    }
    # A finished walk that found nothing leaves behind everything reachable from its starting group,
    # so repeated walks from the same group (a group nested under many parents) are answered without walking again
    $MemoKey = "$Attribute|$From"
    $KnownClosure = $Script:WinADCircularChainMemo[$MemoKey]
    if ($KnownClosure -and -not $KnownClosure.Contains($To)) {
        return [PSCustomObject] @{ Status = 'NotFound'; Chain = [string[]] @() }
    }
    $Visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $Parent = @{}
    $Queue = [System.Collections.Generic.Queue[string]]::new()
    $null = $Visited.Add($From)
    $Queue.Enqueue($From)
    $InspectedNodes = 0
    while ($Queue.Count -gt 0) {
        $CurrentDN = $Queue.Dequeue()
        if ($CurrentDN -eq $To) {
            $Chain = [System.Collections.Generic.List[string]]::new()
            $Step = $CurrentDN
            while ($null -ne $Step) {
                $Chain.Insert(0, $Step)
                $Step = $Parent[$Step]
            }
            return [PSCustomObject] @{ Status = 'Found'; Chain = $Chain.ToArray() }
        }
        $InspectedNodes++
        if ($InspectedNodes -gt $MaximumNodes) {
            # Budget exhausted - report honestly instead of letting an unfinished walk pass for a proven non-circle
            if (-not $Script:WinADCircularChainWarned) {
                $Script:WinADCircularChainWarned = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            if ($Script:WinADCircularChainWarned.Add($MemoKey)) {
                Write-Warning "Find-WinADGroupCircularChain - Circular check starting from '$From' stopped after inspecting $MaximumNodes objects and is reported as unverified. Set `$Script:WinADCircularChainMaximumNodes to a higher value to walk further."
            }
            return [PSCustomObject] @{ Status = 'LimitReached'; Chain = [string[]] @() }
        }
        $CurrentObject = $Cache[$CurrentDN]
        if (-not $CurrentObject -and -not $Cache.Contains($CurrentDN)) {
            $CurrentObject = Get-WinADObject -Identity $CurrentDN -IncludeGroupMembership:($Attribute -eq 'Members')
            # Cache even when nothing was found, the same way the traversal loops do, so failing lookups are not repeated
            $Cache[$CurrentDN] = $CurrentObject
        }
        if ($CurrentObject -and $CurrentObject.ObjectClass -eq 'group') {
            foreach ($NextDN in $CurrentObject.$Attribute) {
                if ($NextDN -and -not $Visited.Contains($NextDN)) {
                    if ($NextDN -ne $To -and $Cache.Contains($NextDN)) {
                        $NextObject = $Cache[$NextDN]
                        if (-not $NextObject -or $NextObject.ObjectClass -ne 'group') {
                            # Known non-groups and unresolvable objects cannot continue a circle of groups - skip without spending budget
                            continue
                        }
                    }
                    $null = $Visited.Add($NextDN)
                    $Parent[$NextDN] = $CurrentDN
                    $Queue.Enqueue($NextDN)
                }
            }
        }
    }
    if (($Script:WinADCircularChainMemoWeight + $Visited.Count) -le $MaximumMemoWeight) {
        $Script:WinADCircularChainMemo[$MemoKey] = $Visited
        $Script:WinADCircularChainMemoWeight += $Visited.Count
    }
    return [PSCustomObject] @{ Status = 'NotFound'; Chain = [string[]] @() }
}
