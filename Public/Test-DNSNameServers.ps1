function Test-DNSNameServers {
    <#
    .SYNOPSIS
    Tests the DNS name servers for a specified domain controller and domain.

    .DESCRIPTION
    This cmdlet queries the specified domain controller for the DNS name servers of the specified domain. It returns a custom object with details about the domain controllers, name servers, their status, and any errors encountered during the query.

    .PARAMETER DomainController
    The name of the domain controller to query.

    .PARAMETER Domain
    The name of the domain to query.

    .EXAMPLE
    Test-DNSNameServers -DomainController "DC1" -Domain "example.com"

    .NOTES
    This cmdlet is useful for monitoring the DNS name servers of a domain.
    #>
    [cmdletBinding()]
    param(
        [string] $DomainController,
        [string] $Domain
    )
    if ($DomainController) {
        $AllDomainControllers = (Get-ADDomainController -Server $Domain -Filter 'IsReadOnly -eq $false').HostName
        try {
            $Hosts = Get-DnsServerResourceRecord -ZoneName $Domain -ComputerName $DomainController -RRType NS -ErrorAction Stop
            $NameServers = (($Hosts | Where-Object { $_.HostName -eq '@' }).RecordData.NameServer) -replace ".$"
            $Compare = ((Compare-Object -ReferenceObject $AllDomainControllers -DifferenceObject $NameServers -IncludeEqual).SideIndicator -notin @('=>', '<='))

            [PSCustomObject] @{
                DomainControllers = $AllDomainControllers
                NameServers       = $NameServers
                Status            = $Compare
                Comment           = "Name servers found $($NameServers -join ', ')"
            }
        } catch {
            [PSCustomObject] @{
                DomainControllers = $AllDomainControllers
                NameServers       = $null
                Status            = $false
                Comment           = $_.Exception.Message
            }
        }

    }
}