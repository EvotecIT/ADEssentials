function Find-WinADGroupCircularChain {
    <#
    .SYNOPSIS
    Finds a nested membership chain leading from one group back to another, if one exists.

    .DESCRIPTION
    Finds a nested membership chain leading from one group back to another by walking the requested membership attribute breadth-first.
    Used to decide whether a group that was already visited on another branch of a traversal really closes a circle with the current group,
    or is simply reachable over more than one path (which is not circular).
    Already resolved objects are taken from the provided cache; unresolved objects are queried once and added to the cache.

    .PARAMETER From
    Distinguished name of the group to start walking from.

    .PARAMETER To
    Distinguished name of the group to find. When found, the chain of distinguished names from From to To is returned. Otherwise an empty array is returned.

    .PARAMETER Attribute
    Membership attribute to walk - Members (downwards) or MemberOf (upwards).

    .PARAMETER Cache
    Dictionary of already resolved AD objects, keyed by distinguished name.

    .EXAMPLE
    Find-WinADGroupCircularChain -From 'CN=GroupC,DC=ad,DC=local' -To 'CN=GroupA,DC=ad,DC=local' -Attribute 'Members' -Cache $Cache
    Returns 'CN=GroupC,...', 'CN=GroupB,...', 'CN=GroupA,...' when GroupC contains GroupB which contains GroupA. Returns an empty array when GroupC does not lead to GroupA.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $From,
        [Parameter(Mandatory)][string] $To,
        [Parameter(Mandatory)][ValidateSet('Members', 'MemberOf')][string] $Attribute,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Cache
    )
    if (-not $Script:WinADCircularChainMemo) {
        $Script:WinADCircularChainMemo = @{}
    }
    # A finished walk that found nothing leaves behind everything reachable from its starting group,
    # so repeated walks from the same group (a group nested under many parents) are answered without walking again
    $MemoKey = "$Attribute|$From"
    $KnownClosure = $Script:WinADCircularChainMemo[$MemoKey]
    if ($KnownClosure -and -not $KnownClosure.Contains($To)) {
        return , ([string[]] @())
    }
    $Visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $Parent = @{}
    $Queue = [System.Collections.Generic.Queue[string]]::new()
    $null = $Visited.Add($From)
    $Queue.Enqueue($From)
    while ($Queue.Count -gt 0) {
        $CurrentDN = $Queue.Dequeue()
        if ($CurrentDN -eq $To) {
            $Chain = [System.Collections.Generic.List[string]]::new()
            $Step = $CurrentDN
            while ($null -ne $Step) {
                $Chain.Insert(0, $Step)
                $Step = $Parent[$Step]
            }
            return , $Chain.ToArray()
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
                    $null = $Visited.Add($NextDN)
                    $Parent[$NextDN] = $CurrentDN
                    $Queue.Enqueue($NextDN)
                }
            }
        }
    }
    $Script:WinADCircularChainMemo[$MemoKey] = $Visited
    return , ([string[]] @())
}
