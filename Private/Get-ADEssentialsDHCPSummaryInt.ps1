function Get-ADEssentialsDHCPSummaryInt {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object] $Value
    )
    if ($null -eq $Value) {
        return 0
    }
    return [int] $Value
}
