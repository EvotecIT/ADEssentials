function Get-WinDnsServerVirtualizationInstance {
    <#
    .SYNOPSIS
    Retrieves information about DNS server virtualization instances on a specified computer.

    .DESCRIPTION
    This function retrieves information about DNS server virtualization instances on a specified computer.

    .PARAMETER ComputerName
    Specifies the name of the computer from which to retrieve DNS server virtualization instances.

    .EXAMPLE
    Get-WinDnsServerVirtualizationInstance -ComputerName "Server01"
    Retrieves DNS server virtualization instances from a computer named Server01.

    #>
    [CmdLetBinding()]
    param(
        [string] $ComputerName
    )

    $DnsServerVirtualizationInstance = Get-DnsServerVirtualizationInstance -ComputerName $ComputerName
    foreach ($_ in $DnsServerVirtualizationInstance) {
        [PSCustomObject] @{
            VirtualizationInstance = $_.VirtualizationInstance
            FriendlyName           = $_.FriendlyName
            Description            = $_.Description
            GatheredFrom           = $ComputerName
        }
    }
}