function Get-WinDHCPServerInfo {
    <#
    .SYNOPSIS
    Internal helper function to gather basic DHCP server information.

    .DESCRIPTION
    This internal function retrieves basic information about a DHCP server including version,
    connectivity status, and basic server details. Used by the main DHCP functions.

    .PARAMETER ComputerName
    The name or IP address of the DHCP server to query.

    .EXAMPLE
    Get-WinDHCPServerInfo -ComputerName "dhcp01.domain.com"

    .NOTES
    This is an internal helper function and should not be called directly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName
    )

    $ServerInfo = [ordered] @{
        ServerName   = $ComputerName
        IsReachable  = $false
        Version      = $null
        Status       = 'Unknown'
        ErrorMessage = $null
    }

    try {
        $DHCPServerInfo = Get-DhcpServerVersion -ComputerName $ComputerName -ErrorAction Stop
        $ServerInfo.IsReachable = $true
        $ServerInfo.Version = "$($DHCPServerInfo.MajorVersion).$($DHCPServerInfo.MinorVersion)"
        $ServerInfo.Status = 'Online'
    } catch {
        $ServerInfo.Status = 'Unreachable'
        $ServerInfo.ErrorMessage = $_.Exception.Message
        Write-Verbose "Get-WinDHCPServerInfo - Cannot reach DHCP server $ComputerName`: $($_.Exception.Message)"
    }

    return [PSCustomObject]$ServerInfo
}
