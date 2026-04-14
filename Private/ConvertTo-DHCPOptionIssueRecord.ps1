function ConvertTo-DHCPOptionIssueRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Issue
    )

    if ($null -eq $Issue) {
        return $null
    }

    if ($Issue -is [string] -and [string]::IsNullOrWhiteSpace($Issue)) {
        return $null
    }

    if ($Issue -isnot [string]) {
        $text = if ($Issue.PSObject.Properties['Issue']) { [string] $Issue.Issue } else { [string] $Issue }
        $serverName = if ($Issue.PSObject.Properties['ServerName']) { [string] $Issue.ServerName } else { $null }
        $scopeId = if ($Issue.PSObject.Properties['ScopeId']) { [string] $Issue.ScopeId } else { $null }
        $category = if ($Issue.PSObject.Properties['Category']) { [string] $Issue.Category } else { 'Other' }
        $recommendation = if ($Issue.PSObject.Properties['Recommendation']) { [string] $Issue.Recommendation } else { 'Review the DHCP option configuration and align it with the approved standard.' }

        if ([string]::IsNullOrWhiteSpace($text)) {
            return $null
        }

        return [PSCustomObject]@{
            Category       = $category
            ServerName     = $serverName
            ScopeId        = $scopeId
            Details        = $text
            Recommendation = $recommendation
        }
    }

    $text = [string] $Issue
    $category = 'Other'
    $serverName = $null
    $scopeId = $null
    $recommendation = 'Review the DHCP option configuration and align it with the approved standard.'

    if ($text -match '^Public DNS servers configured in scope (?<scope>.+?) on (?<server>.+)$') {
        $category = 'Public DNS'
        $scopeId = $Matches.scope
        $serverName = $Matches.server
        $recommendation = 'Replace public DNS servers with approved internal DNS servers or document the exception.'
    } elseif ($text -match '^Very long lease time \((?<hours>\d+) hours\) in scope (?<scope>.+?) on (?<server>.+)$') {
        $category = 'Lease Time'
        $scopeId = $Matches.scope
        $serverName = $Matches.server
        $recommendation = 'Reduce the lease duration to 168 hours or less unless the longer value is explicitly approved.'
    } elseif ($text -match '^Empty domain name in scope (?<scope>.+?) on (?<server>.+)$') {
        $category = 'Domain Name'
        $scopeId = $Matches.scope
        $serverName = $Matches.server
        $recommendation = 'Configure DHCP option 15 with the expected DNS domain name.'
    } elseif ($text -match '^Invalid lease time format in scope (?<scope>.+?) on (?<server>.+)$') {
        $category = 'Lease Time Format'
        $scopeId = $Matches.scope
        $serverName = $Matches.server
        $recommendation = 'Verify DHCP option 51 uses a valid numeric value expressed in seconds.'
    }

    [PSCustomObject]@{
        Category       = $category
        ServerName     = $serverName
        ScopeId        = $scopeId
        Details        = $text
        Recommendation = $recommendation
    }
}
