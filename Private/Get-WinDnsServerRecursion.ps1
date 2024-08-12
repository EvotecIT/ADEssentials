function Get-WinDnsServerRecursion {
    <#
    .SYNOPSIS
    Retrieves DNS server recursion settings from specified computers.

    .DESCRIPTION
    This function retrieves DNS server recursion settings from the specified computers. If no ComputerName is provided, it retrieves the settings from the domain controller associated with the specified domain.

    .PARAMETER ComputerName
    Specifies the names of the computers from which to retrieve DNS server recursion settings.

    .PARAMETER Domain
    Specifies the domain from which to retrieve DNS server recursion settings. Defaults to the current user's DNS domain.

    .EXAMPLE
    Get-WinDnsServerRecursion -ComputerName "Server01", "Server02" -Domain "contoso.com"
    Retrieves DNS server recursion settings from Server01 and Server02 in the contoso.com domain.

    .EXAMPLE
    Get-WinDnsServerRecursion -Domain "fabrikam.com"
    Retrieves DNS server recursion settings from the domain controller associated with the fabrikam.com domain.

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
        $DnsServerRecursion = Get-DnsServerRecursion -ComputerName $Computer
        foreach ($_ in $DnsServerRecursion) {
            [PSCustomObject] @{
                AdditionalTimeout = $_.AdditionalTimeout
                Enable            = $_.Enable
                RetryInterval     = $_.RetryInterval
                SecureResponse    = $_.SecureResponse
                Timeout           = $_.Timeout
                GatheredFrom      = $Computer
            }
        }
    }
}
