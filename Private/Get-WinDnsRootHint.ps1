function Get-WinDnsRootHint {
    <#
    .SYNOPSIS
    Retrieves DNS root hints from specified computers.

    .DESCRIPTION
    This function retrieves DNS root hints from the specified computers. If no ComputerName is provided, it uses the default domain controller.

    .PARAMETER ComputerName
    Specifies an array of computer names from which to retrieve DNS root hints.

    .PARAMETER Domain
    Specifies the domain to use for retrieving DNS root hints. Defaults to the current user's DNS domain.

    .EXAMPLE
    Get-WinDnsRootHint -ComputerName "Server01", "Server02" -Domain "contoso.com"
    Retrieves DNS root hints from Server01 and Server02 in the contoso.com domain.

    .EXAMPLE
    Get-WinDnsRootHint -Domain "fabrikam.com"
    Retrieves DNS root hints from the default domain controller in the fabrikam.com domain.
    #>
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $ServerRootHints = Get-DnsServerRootHint -ComputerName $Computer
        foreach ($_ in $ServerRootHints.IPAddress) {
            [PSCustomObject] @{
                DistinguishedName = $_.DistinguishedName
                HostName          = $_.HostName
                RecordClass       = $_.RecordClass
                IPv4Address       = $_.RecordData.IPv4Address.IPAddressToString
                IPv6Address       = $_.RecordData.IPv6Address.IPAddressToString
                #RecordData        = $_.RecordData.IPv4Address -join ', '
                #RecordData1        = $_.RecordData
                RecordType        = $_.RecordType
                Timestamp         = $_.Timestamp
                TimeToLive        = $_.TimeToLive
                Type              = $_.Type
                GatheredFrom      = $Computer
            }
        }
    }
}