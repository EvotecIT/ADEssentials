function Get-WinDnsServerCache {
    <#
    .SYNOPSIS
    Retrieves DNS server cache information for specified computers.

    .DESCRIPTION
    This function retrieves DNS server cache information for the specified computers. If no ComputerName is provided, it retrieves cache information from the default domain controller.

    .PARAMETER ComputerName
    Specifies an array of computer names from which to retrieve DNS server cache information.

    .PARAMETER Domain
    Specifies the domain to use for retrieving DNS server cache information. Defaults to the current user's DNS domain.

    .EXAMPLE
    Get-WinDnsServerCache -ComputerName "Server01", "Server02" -Domain "contoso.com"
    Retrieves DNS server cache information from Server01 and Server02 in the contoso.com domain.

    .EXAMPLE
    Get-WinDnsServerCache -Domain "fabrikam.com"
    Retrieves DNS server cache information from the default domain controller in the fabrikam.com domain.
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
        $DnsServerCache = Get-DnsServerCache -ComputerName $Computer
        foreach ($_ in $DnsServerCache) {
            [PSCustomObject] @{
                DistinguishedName         = $_.DistinguishedName
                IsAutoCreated             = $_.IsAutoCreated
                IsDsIntegrated            = $_.IsDsIntegrated
                IsPaused                  = $_.IsPaused
                IsReadOnly                = $_.IsReadOnly
                IsReverseLookupZone       = $_.IsReverseLookupZone
                IsShutdown                = $_.IsShutdown
                ZoneName                  = $_.ZoneName
                ZoneType                  = $_.ZoneType
                EnablePollutionProtection = $_.EnablePollutionProtection
                IgnorePolicies            = $_.IgnorePolicies
                LockingPercent            = $_.LockingPercent
                MaxKBSize                 = $_.MaxKBSize
                MaxNegativeTtl            = $_.MaxNegativeTtl
                MaxTtl                    = $_.MaxTtl
                GatheredFrom              = $Computer
            }
        }
    }
}