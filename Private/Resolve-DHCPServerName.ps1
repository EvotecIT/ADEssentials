function Resolve-DHCPServerName {
    <#
    .SYNOPSIS
    Resolves a server name to a canonical, normalized form (prefer FQDN).

    .DESCRIPTION
    - Trims and lowercases the input.
    - If the name is already an FQDN (contains a dot), returns it in lowercase.
    - If it's a short host, attempts to find a matching DHCP server in the current
      summary ($DHCPSummary.Servers) and returns its FQDN; otherwise returns the
      short name (lowercased).

    .PARAMETER Name
    Server name to resolve.

    .PARAMETER DHCPSummary
    DHCP summary object used as a source of known server FQDNs.

    .EXAMPLE
    Resolve-DHCPServerName -Name 'xa-s-dhcp01p' -DHCPSummary $summary
    xa-s-dhcp01p.xa.abb.com
    #>
    [CmdletBinding()]
    param(
        [AllowNull()][string] $Name,
        [Parameter(Mandatory)][System.Collections.IDictionary] $DHCPSummary
    )

    # Simple cache to avoid repeated scans
    if (-not $script:DhcpCanonicalNameCache) { $script:DhcpCanonicalNameCache = @{} }

    $n = ConvertTo-NormalizedName -Name $Name
    if ($null -eq $n) { return $null }

    if ($script:DhcpCanonicalNameCache.ContainsKey($n)) { return $script:DhcpCanonicalNameCache[$n] }

    # Already FQDN
    if ($n -match '\.') { $script:DhcpCanonicalNameCache[$n] = $n; return $n }

    $short = $n
    # Try to match against known servers
    $match = $null
    foreach ($s in $DHCPSummary.Servers) {
        if ($null -eq $s.ServerName) { continue }
        $fqdn = ($s.ServerName.ToString()).Trim().ToLower()
        if ($fqdn.StartsWith("$short.")) { $match = $fqdn; break }
    }

    $resolved = if ($match) { $match } else { $n }
    $script:DhcpCanonicalNameCache[$n] = $resolved
    return $resolved
}

