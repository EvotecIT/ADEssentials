function ConvertTo-WinADCircularPath {
    <#
    .SYNOPSIS
    Converts a chain of distinguished names into a readable circular membership path.

    .DESCRIPTION
    Converts a chain of distinguished names into a readable circular membership path such as "GroupA -> GroupB -> GroupA".
    Names are resolved from the provided object cache. If an object is not cached its distinguished name is used as is.

    .PARAMETER DistinguishedName
    Chain of distinguished names describing the circular membership, in traversal order.

    .PARAMETER Cache
    Dictionary of already resolved AD objects, keyed by distinguished name.

    .EXAMPLE
    ConvertTo-WinADCircularPath -DistinguishedName @('CN=GroupA,DC=ad,DC=local', 'CN=GroupB,DC=ad,DC=local', 'CN=GroupA,DC=ad,DC=local') -Cache $Cache
    Returns 'GroupA -> GroupB -> GroupA' when both groups are present in the cache.
    #>
    [CmdletBinding()]
    param(
        [string[]] $DistinguishedName,
        [System.Collections.IDictionary] $Cache
    )
    $Names = foreach ($DN in $DistinguishedName) {
        if ($Cache -and $Cache[$DN] -and $Cache[$DN].Name) {
            $Cache[$DN].Name
        } else {
            $DN
        }
    }
    $Names -join ' -> '
}
