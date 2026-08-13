function Get-DHCPFailoverEnumeratedServerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPSummary
    )

    $enumeratedServers = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($status in @($DHCPSummary.FailoverCollectionStatus)) {
        if (-not $status.Success) { continue }

        $server = Resolve-DHCPServerName -Name $status.ServerName -DHCPSummary $DHCPSummary
        if ($server) {
            [void] $enumeratedServers.Add($server)
        }
    }

    return ,$enumeratedServers
}
