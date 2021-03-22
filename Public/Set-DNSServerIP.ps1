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

        try {
            $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction Stop | Where-Object { $_.DHCPEnabled -ne 'True' -and $null -ne $_.DNSServerSearchOrder }
        } catch {
            Write-Warning "Couldn't get adapters that fit what we're searching for on $Computer. Error $($_.Exception.Message.Replace([System.Environment]::NewLine,'')) Skipping"
            continue
        }
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
            try {
                $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction Stop | Where-Object { $_.DHCPEnabled -ne 'True' -and $null -ne $_.DNSServerSearchOrder }
                foreach ($Adapter in $Adapters) {
                    [PSCustomobject] @{
                        ComputerName         = $Adapter.PSComputerName
                        DNSHostName          = $Adapter.DNSHostName
                        IPAddress            = $Adapter.IPAddress -join ', '
                        DefaultIPGateway     = $Adapter.DefaultIPGateway -join ', '
                        DNSServerSearchOrder = $Adapter.DNSServerSearchOrder -join ', '
                        IPSubnet             = $Adapter.IPSubnet -join ', '
                        Description          = $Adapter.Description
                    }
                }
            } catch {
                Write-Warning "Couldn't get adapters that fit what we're searching for on $Computer. Error $($_.Exception.Message.Replace([System.Environment]::NewLine,'')) Skipping"
                continue
            }
        }
    }

}