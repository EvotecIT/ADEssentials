function Get-DHCPStandaloneServerName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPSummary
    )

    $enumeratedServers = Get-DHCPFailoverEnumeratedServerSet -DHCPSummary $DHCPSummary
    $mentionedServers = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($relationship in @($DHCPSummary.FailoverRelationships)) {
        foreach ($name in @($relationship.ServerName, $relationship.PartnerServer)) {
            $canonicalName = Resolve-DHCPServerName -Name $name -DHCPSummary $DHCPSummary
            if ($canonicalName) {
                [void] $mentionedServers.Add($canonicalName)
            }
        }
    }

    foreach ($server in @($DHCPSummary.Servers)) {
        $canonicalName = Resolve-DHCPServerName -Name $server.ServerName -DHCPSummary $DHCPSummary
        if ($canonicalName -and $enumeratedServers.Contains($canonicalName) -and -not $mentionedServers.Contains($canonicalName)) {
            $canonicalName
        }
    }
}
