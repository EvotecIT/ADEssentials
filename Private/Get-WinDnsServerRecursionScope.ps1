function Get-WinDnsServerRecursionScope {
    <#
    .SYNOPSIS
    Retrieves DNS server recursion scope settings from specified computers.

    .DESCRIPTION
    This function retrieves DNS server recursion scope settings from the specified computers. If no ComputerName is provided, it retrieves the settings from the domain controller associated with the specified domain.

    .PARAMETER ComputerName
    Specifies the names of the computers from which to retrieve DNS server recursion scope settings.

    .PARAMETER Domain
    Specifies the domain from which to retrieve DNS server recursion scope settings. Defaults to the current user's DNS domain.

    .EXAMPLE
    Get-WinDnsServerRecursionScope -ComputerName "Server01", "Server02" -Domain "contoso.com"
    Retrieves DNS server recursion scope settings from Server01 and Server02 in the contoso.com domain.

    .EXAMPLE
    Get-WinDnsServerRecursionScope -Domain "fabrikam.com"
    Retrieves DNS server recursion scope settings from the domain controller associated with the fabrikam.com domain.

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
        $DnsServerRecursionScope = Get-DnsServerRecursionScope -ComputerName $Computer
        foreach ($_ in $DnsServerRecursionScope) {
            [PSCustomObject] @{
                Name            = $_.Name
                Forwarder       = $_.Forwarder
                EnableRecursion = $_.EnableRecursion
                GatheredFrom    = $Computer
            }
        }
    }
}
