function ConvertTo-NormalizedName {
    <#
    .SYNOPSIS
    Returns a normalized (trimmed, lowercase) representation of a server or domain-style name.

    .DESCRIPTION
    Trims leading/trailing whitespace and converts the input string to lowercase.
    Returns $null when the input is $null.

    .PARAMETER Name
    The string to normalize.

    .EXAMPLE
    ConvertTo-NormalizedName -Name '  Xa-S-DHCP01P.XA.ABB.COM  '
    xa-s-dhcp01p.xa.abb.com
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $Name
    )

    if ($null -eq $Name) { return $null }
    return $Name.Trim().ToLower()
}

