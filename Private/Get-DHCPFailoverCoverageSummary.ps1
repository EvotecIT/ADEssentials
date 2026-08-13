function Get-DHCPFailoverCoverageSummary {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][object[]] $Scopes
    )

    $configuredCount = @($Scopes | Where-Object {
        $_.State -eq 'Active' -and
        (Get-DHCPFailoverScopeStatus -Scope $_) -eq 'Configured' -and
        (Test-DHCPFailoverScopeVerified -Scope $_)
    }).Count
    $missingCount = @($Scopes | Where-Object {
        $_.State -eq 'Active' -and (Get-DHCPFailoverScopeStatus -Scope $_) -eq 'Missing'
    }).Count
    $unverifiedCount = @($Scopes | Where-Object {
        $_.State -eq 'Active' -and -not (Test-DHCPFailoverScopeVerified -Scope $_)
    }).Count
    $assessedCount = $configuredCount + $missingCount

    $percentage = if ($assessedCount -gt 0) {
        [Math]::Round((100.0 * $configuredCount / $assessedCount), 2)
    } else {
        $null
    }

    [PSCustomObject]@{
        ConfiguredCount = $configuredCount
        MissingCount    = $missingCount
        UnverifiedCount = $unverifiedCount
        AssessedCount   = $assessedCount
        Percentage      = $percentage
        Display         = if ($null -eq $percentage) { 'N/A' } else { "$percentage%" }
    }
}
