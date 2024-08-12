function Get-DNSServerIP {
    <#
    .SYNOPSIS
    Retrieves DNS server IP information for specified computers.

    .DESCRIPTION
    This function retrieves DNS server IP information for the specified computers. It checks if the DNS servers are in the approved list and if at least two DNS servers are configured.

    .PARAMETER ComputerName
    Specifies the names of the computers to retrieve DNS server information from.

    .PARAMETER ApprovedList
    Specifies the list of approved DNS server IP addresses.

    .PARAMETER Credential
    Specifies a credential object to use for accessing the computers.

    .EXAMPLE
    Get-DNSServerIP -ComputerName "Computer01" -ApprovedList "192.168.1.1", "192.168.1.2"

    .NOTES
    File: Get-DNSServerIP.ps1
    Author: [Your Name]
    Version: 1.0
    Date: [Current Date]
    #>
    [alias('Get-WinDNSServerIP')]
    param(
        [string[]] $ComputerName,
        [string[]] $ApprovedList,
        [pscredential] $Credential
    )
    foreach ($Computer in $ComputerName) {
        $Adapters = Get-CimData -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction Stop | Where-Object { $_.DHCPEnabled -ne 'True' -and $null -ne $_.DNSServerSearchOrder }
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
}