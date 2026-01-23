function Get-ADEssentialsDHCPSummaryCount {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object] $Value
    )
    if ($null -eq $Value) {
        return 0
    }
    return @($Value).Count
}
