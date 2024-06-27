function Get-WinDnsRootHint {
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