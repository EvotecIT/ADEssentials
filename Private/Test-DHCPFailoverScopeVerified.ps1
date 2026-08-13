function Test-DHCPFailoverScopeVerified {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $Scope
    )

    $status = Get-DHCPFailoverScopeStatus -Scope $Scope
    if ($status -in @('Unknown', 'NotCollected')) {
        return $false
    }

    if ($Scope.PSObject.Properties.Name -contains 'FailoverVerified') {
        return [bool] $Scope.FailoverVerified
    }

    # Scope objects produced before explicit verification existed treated a
    # configured partner or a confirmed absence as assessed evidence.
    return $status -in @('Configured', 'Missing')
}
