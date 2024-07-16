function Get-WinDnsServerResponseRateLimiting {
    <#
    .SYNOPSIS
    Retrieves DNS server response rate limiting settings from specified computers.

    .DESCRIPTION
    This function retrieves DNS server response rate limiting settings from the specified computers. If no ComputerName is provided, it retrieves the settings from the domain controller associated with the specified domain.

    .PARAMETER ComputerName
    Specifies the names of the computers from which to retrieve DNS server response rate limiting settings.

    .PARAMETER Domain
    Specifies the domain from which to retrieve DNS server response rate limiting settings. Defaults to the current user's DNS domain.

    .EXAMPLE
    Get-WinDnsServerResponseRateLimiting -ComputerName "Server01", "Server02" -Domain "contoso.com"
    Retrieves DNS server response rate limiting settings from Server01 and Server02 in the contoso.com domain.

    .EXAMPLE
    Get-WinDnsServerResponseRateLimiting -Domain "fabrikam.com"
    Retrieves DNS server response rate limiting settings from the domain controller associated with the fabrikam.com domain.
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
        $DnsServerResponseRateLimiting = Get-DnsServerResponseRateLimiting -ComputerName $Computer
        foreach ($_ in $DnsServerResponseRateLimiting) {
            [PSCustomObject] @{
                ResponsesPerSec           = $_.ResponsesPerSec
                ErrorsPerSec              = $_.ErrorsPerSec
                WindowInSec               = $_.WindowInSec
                IPv4PrefixLength          = $_.IPv4PrefixLength
                IPv6PrefixLength          = $_.IPv6PrefixLength
                LeakRate                  = $_.LeakRate
                TruncateRate              = $_.TruncateRate
                MaximumResponsesPerWindow = $_.MaximumResponsesPerWindow
                Mode                      = $_.Mode
                GatheredFrom              = $Computer
            }
        }
    }
}