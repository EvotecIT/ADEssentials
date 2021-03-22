function Set-DnsServerIP {
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