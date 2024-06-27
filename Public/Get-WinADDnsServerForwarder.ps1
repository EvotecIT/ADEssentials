function Get-WinADDnsServerForwarder {
    [CmdLetBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $Formatted,
        [string] $Splitter = ', ',
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Computer in $ForestInformation.ForestDomainControllers) {
        try {
            $DnsServerForwarder = Get-DnsServerForwarder -ComputerName $Computer.HostName -ErrorAction Stop
        } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            Write-Warning "Get-WinDnsServerForwarder - Error $ErrorMessage"
            continue
        }
        foreach ($_ in $DnsServerForwarder) {
            if ($Formatted) {
                [PSCustomObject] @{
                    IPAddress          = $_.IPAddress.IPAddressToString -join $Splitter
                    ReorderedIPAddress = $_.ReorderedIPAddress.IPAddressToString -join $Splitter
                    EnableReordering   = $_.EnableReordering
                    Timeout            = $_.Timeout
                    UseRootHint        = $_.UseRootHint
                    ForwardersCount    = ($_.IPAddress.IPAddressToString).Count
                    GatheredFrom       = $Computer.HostName
                    GatheredDomain     = $Computer.Domain
                }
            } else {
                [PSCustomObject] @{
                    IPAddress          = $_.IPAddress.IPAddressToString
                    ReorderedIPAddress = $_.ReorderedIPAddress.IPAddressToString
                    EnableReordering   = $_.EnableReordering
                    Timeout            = $_.Timeout
                    UseRootHint        = $_.UseRootHint
                    ForwardersCount    = ($_.IPAddress.IPAddressToString).Count
                    GatheredFrom       = $Computer.HostName
                    GatheredDomain     = $Computer.Domain
                }
            }
        }
    }
}