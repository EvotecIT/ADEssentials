function Get-DNSServerIP {
    [alias('Get-WinDNSServerIP')]
    param(
        [string[]] $ComputerName,
        [string[]] $ApprovedList,
        [pscredential] $Credential
    )
    foreach ($Computer in $ComputerName) {
        try {
            $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction Stop | Where-Object { $_.DHCPEnabled -ne 'True' -and $null -ne $_.DNSServerSearchOrder }
        } catch {
            Write-Warning "Couldn't get adapters that fit what we're searching for on $Computer. Error $($_.Exception.Message.Replace([System.Environment]::NewLine,'')) Skipping"
            $ErrorMessage = $($_.Exception.Message).Replace([System.Environment]::NewLine, '')
            $Adapters = $null
        }
        if ($Adapters) {
            foreach ($Adapter in $Adapters) {
                $AllApproved = $true
                foreach ($DNS in $Adapter.DNSServerSearchOrder) {
                    if ($DNS -notin $ApprovedList) {
                        $AllApproved = $true
                    }
                }
                $AtLeastTwo = $Adapter.DNSServerSearchOrder.Count -ge 2
                $Output = [ordered] @{
                    DNSHostName          = $Adapter.DNSHostName
                    Status               = $AllApproved -and $AtLeastTwo
                    Approved             = $AllApproved
                    AtLeastTwo           = $AtLeastTwo
                    Connected            = $true
                    IPAddress            = $Adapter.IPAddress -join ', '
                    DNSServerSearchOrder = $Adapter.DNSServerSearchOrder -join ', '
                    DefaultIPGateway     = $Adapter.DefaultIPGateway -join ', '
                    IPSubnet             = $Adapter.IPSubnet -join ', '
                    Description          = $Adapter.Description
                }
                if (-not $ApprovedList) {
                    $Output.Remove('Approved')
                    $Output.Remove('Status')
                }
                [PSCustomObject] $Output
            }
        } else {
            $Output = [ordered] @{
                DNSHostName          = $Computer
                Status               = $false
                Approved             = $false
                AtLeastTwo           = $false
                Connected            = $false
                IPAddress            = $null
                DNSServerSearchOrder = $null
                DefaultIPGateway     = $null
                IPSubnet             = $null
                Description          = $ErrorMessage
            }
            if (-not $ApprovedList) {
                $Output.Remove('Approved')
                $Output.Remove('Status')
            }
            [PSCustomObject] $Output
        }
    }
} }
}