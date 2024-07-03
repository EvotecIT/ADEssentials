function Set-DnsServerIP {
    <#
    .SYNOPSIS
    Sets the DNS server IP addresses for a specified list of computers.

    .DESCRIPTION
    This cmdlet sets the DNS server IP addresses for a specified list of computers. It supports both local and remote operations. 
    It can use a credential for remote connections. It filters out adapters that are DHCP enabled or do not have a DNS server search order set.
    It then sets the DNS server IP addresses for the remaining adapters. If the operation is successful, it retrieves the current DNS server IP addresses.

    .PARAMETER ComputerName
    Specifies the names of the computers on which to set the DNS server IP addresses.

    .PARAMETER DnsIpAddress
    Specifies the IP addresses of the DNS servers to set.

    .PARAMETER Credential
    Specifies the credentials to use for remote connections.

    .EXAMPLE
    Set-DnsServerIP -ComputerName 'Computer1', 'Computer2' -DnsIpAddress '8.8.8.8', '8.8.4.4'

    This example sets the DNS server IP addresses to '8.8.8.8' and '8.8.4.4' for 'Computer1' and 'Computer2'.

    .EXAMPLE
    Set-DnsServerIP -ComputerName 'Computer1', 'Computer2' -DnsIpAddress '8.8.8.8', '8.8.4.4' -Credential (Get-Credential)

    This example sets the DNS server IP addresses to '8.8.8.8' and '8.8.4.4' for 'Computer1' and 'Computer2' using the credentials provided by the user.
    #>
    [alias('Set-WinDNSServerIP')]
    [cmdletbInding(SupportsShouldProcess)]
    param(
        [string[]] $ComputerName,
        [string[]] $DnsIpAddress,
        [pscredential] $Credential
    )
    foreach ($Computer in $Computers) {
        try {
            if ($Credential) {
                $CimSession = New-CimSession -ComputerName $Computer -Credential $Credential -Authentication Negotiate -ErrorAction Stop
            } else {
                $CimSession = New-CimSession -ComputerName $Computer -ErrorAction Stop -Authentication Negotiate
            }
        } catch {
            Write-Warning "Couldn't authorize session to $Computer. Error $($_.Exception.Message). Skipping."
            continue
        }

        $Adapters = Get-CimData -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object { $_.DHCPEnabled -ne 'True' -and $null -ne $_.DNSServerSearchOrder }
        if ($Adapters) {
            $Text = "Setting DNS to $($DNSIPAddress -join ', ')"
            if ($PSCmdlet.ShouldProcess($Computer, $Text)) {
                if ($Adapters) {
                    try {
                        $Adapters | Set-DnsClientServerAddress -ServerAddresses $DnsIpAddress -CimSession $CimSession
                    } catch {
                        Write-Warning "Couldn't fix adapters with IP Address for $Computer. Error $($_.Exception.Message)"
                        continue
                    }
                }
                Get-DNSServerIP -ComputerName $Computer
            }
        }
    }

}