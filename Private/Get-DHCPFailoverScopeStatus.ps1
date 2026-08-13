function Get-DHCPFailoverScopeStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $Scope
    )

    if ($Scope.PSObject.Properties.Name -contains 'FailoverStatus') {
        $status = [string] $Scope.FailoverStatus
        if ($status -in @('Configured', 'Missing', 'Unknown', 'NotCollected')) {
            return $status
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string] $Scope.FailoverPartner)) {
        return 'Configured'
    }

    # Backward compatibility for callers passing scope objects produced before
    # explicit failover evidence was added.
    return 'Missing'
}
