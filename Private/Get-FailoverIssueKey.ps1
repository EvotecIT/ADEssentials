function Get-FailoverIssueKey {
    <#
    .SYNOPSIS
    Builds a stable deduplication key for failover-issue rows.

    .DESCRIPTION
    Produces a consistent key of the form "<PartnerA↔PartnerB>|<ScopeId>|<Issue>" where
    partners are normalized (trimmed/lowercase) and sorted alphabetically to be order-insensitive.

    .PARAMETER ServerA
    First partner name.

    .PARAMETER ServerB
    Second partner name.

    .PARAMETER ScopeId
    Scope identifier (string).

    .PARAMETER Issue
    Issue description text.

    .EXAMPLE
    Get-FailoverIssueKey -ServerA 'X' -ServerB 'Y' -ScopeId '10.1.0.0' -Issue 'Missing on y'
    x↔y|10.1.0.0|Missing on y
    #>
    [CmdletBinding()]
    param(
        [AllowNull()][string] $ServerA,
        [AllowNull()][string] $ServerB,
        [AllowNull()][string] $ScopeId,
        [AllowNull()][string] $Issue
    )

    $a = ConvertTo-NormalizedName -Name $ServerA
    $b = ConvertTo-NormalizedName -Name $ServerB
    $pair = @($a, $b) | Where-Object { $_ } | Sort-Object
    return ($pair -join '↔') + '|' + ([string]$ScopeId) + '|' + ([string]$Issue)
}

