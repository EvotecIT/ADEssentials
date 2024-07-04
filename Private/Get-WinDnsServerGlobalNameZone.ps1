function Get-WinDnsServerGlobalNameZone {
    <#
    .SYNOPSIS
    Retrieves global name zone settings for specified DNS servers.

    .DESCRIPTION
    This function retrieves global name zone settings for the specified DNS servers. It provides details about various settings related to global name zones, including AlwaysQueryServer, BlockUpdates, Enable, EnableEDnsProbes, GlobalOverLocal, PreferAaaa, SendTimeout, ServerQueryInterval, and the computer from which the settings were gathered.

    .PARAMETER ComputerName
    Specifies an array of computer names from which to retrieve global name zone settings.

    .PARAMETER Domain
    Specifies the domain to use for retrieving global name zone settings. Defaults to the current user's DNS domain.

    .EXAMPLE
    Get-WinDnsServerGlobalNameZone -ComputerName "Server01", "Server02" -Domain "contoso.com"
    Retrieves global name zone settings from Server01 and Server02 in the contoso.com domain.

    .EXAMPLE
    Get-WinDnsServerGlobalNameZone -Domain "fabrikam.com"
    Retrieves global name zone settings from the default domain controller in the fabrikam.com domain.
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
        $DnsServerGlobalNameZone = Get-DnsServerGlobalNameZone -ComputerName $Computer
        foreach ($_ in $DnsServerGlobalNameZone) {
            [PSCustomObject] @{
                AlwaysQueryServer   = $_.AlwaysQueryServer
                BlockUpdates        = $_.BlockUpdates
                Enable              = $_.Enable
                EnableEDnsProbes    = $_.EnableEDnsProbes
                GlobalOverLocal     = $_.GlobalOverLocal
                PreferAaaa          = $_.PreferAaaa
                SendTimeout         = $_.SendTimeout
                ServerQueryInterval = $_.ServerQueryInterval
                GatheredFrom        = $Computer
            }
        }
    }
}

#Get-WinDnsServerGlobalNameZone -ComputerName 'AD1'