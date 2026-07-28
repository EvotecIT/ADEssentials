function Get-WinADCustomDiagramIcon {
    <#
    .SYNOPSIS
    Resolves a custom diagram icon for an object based on wildcard name patterns.

    .DESCRIPTION
    Resolves a custom diagram icon for an object based on wildcard name patterns provided by the user.
    Returns a hashtable ready to be splatted onto New-DiagramNode, or $null when no pattern matches
    (in which case the caller falls back to the default icon for the object type).
    The first matching pattern wins - provide an [ordered] dictionary to control precedence.
    Icon names are validated against the PSWriteHTML icon dictionary when it is loaded; unknown names
    and invalid wildcard patterns produce a single warning and fall back to default icons.

    .PARAMETER Name
    Name of the object (user, group, computer) to match against the patterns.

    .PARAMETER CustomIcons
    Dictionary where each key is a wildcard pattern matched against the object name (-like) and each value is either:
    - a string with an image URL, or
    - a dictionary with Image, or IconSolid/IconRegular/IconBrands (Font Awesome icon name) plus optional IconColor.

    .EXAMPLE
    Get-WinADCustomDiagramIcon -Name 'GG-RBAC-FileShares' -CustomIcons ([ordered] @{ '*-RBAC-*' = 'https://cdn-icons-png.flaticon.com/512/1687/1687242.png' })
    Returns @{ Image = 'https://cdn-icons-png.flaticon.com/512/1687/1687242.png' }

    .EXAMPLE
    Get-WinADCustomDiagramIcon -Name 'Enterprise Admins' -CustomIcons ([ordered] @{ 'Enterprise Admins' = @{ IconSolid = 'user-shield'; IconColor = 'Red' } })
    Returns @{ IconSolid = 'user-shield'; IconColor = 'Red' }
    #>
    [CmdletBinding()]
    param(
        [string] $Name,
        [System.Collections.IDictionary] $CustomIcons
    )
    if (-not $CustomIcons -or -not $Name) {
        return $null
    }
    if (-not $Script:WinADCustomDiagramIconWarnings) {
        $Script:WinADCustomDiagramIconWarnings = [System.Collections.Generic.HashSet[string]]::new()
    }
    foreach ($Pattern in $CustomIcons.Keys) {
        try {
            $PatternMatched = $Name -like $Pattern
        } catch {
            if ($Script:WinADCustomDiagramIconWarnings.Add("Pattern|$Pattern")) {
                Write-Warning "Get-WinADCustomDiagramIcon - Invalid wildcard pattern '$Pattern' in CustomIcons. Skipping it."
            }
            continue
        }
        if ($PatternMatched) {
            $Value = $CustomIcons[$Pattern]
            if ($Value -is [System.Collections.IDictionary]) {
                if ($Value['Image']) {
                    return @{ Image = [string] $Value['Image'] }
                }
                $IconSplat = @{}
                foreach ($IconType in 'IconSolid', 'IconRegular', 'IconBrands') {
                    if ($Value[$IconType]) {
                        $IconName = [string] $Value[$IconType]
                        # New-DiagramNode validates icon names against the PSWriteHTML icon dictionary,
                        # and a failing name would silently drop the node while keeping its links.
                        # Verify upfront so a typo falls back to the default icon instead.
                        $IconDictionary = if ($Global:HTMLIcons) { $Global:HTMLIcons["FontAwesome$($IconType.Substring(4))"] } else { $null }
                        if ($IconDictionary -and -not $IconDictionary.Contains($IconName)) {
                            if ($Script:WinADCustomDiagramIconWarnings.Add("Icon|$IconName")) {
                                Write-Warning "Get-WinADCustomDiagramIcon - Icon '$IconName' ($IconType) for pattern '$Pattern' does not exist in the PSWriteHTML icon set. Using default icon."
                            }
                            return $null
                        }
                        $IconSplat[$IconType] = $IconName
                        break
                    }
                }
                if ($IconSplat.Count -gt 0) {
                    if ($Value['IconColor']) {
                        $IconSplat['IconColor'] = [string] $Value['IconColor']
                    }
                    return $IconSplat
                }
            } elseif ($Value -is [string] -and $Value) {
                return @{ Image = $Value }
            }
            # matched pattern without a usable value - fall back to default icons
            return $null
        }
    }
    return $null
}
