function Get-WinDnsServerVirtualizationInstance {
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