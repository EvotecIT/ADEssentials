function Get-WinADProtocol {
    <#
    .SYNOPSIS
    Gets current SCHANNEL settings for Windows Clients and Servers.

    .DESCRIPTION
    Gets current SCHANNEL settings for Windows Clients and Servers. By default scans all Domain Controllers in a forest

    .PARAMETER ComputerName
    Provides ability to query specific servers or computers.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers, by default there are no exclusions, as long as VerifyDomainControllers switch is enabled. Otherwise this parameter is ignored.

    .PARAMETER IncludeDomainControllers
    Include only specific domain controllers, by default all domain controllers are included, as long as VerifyDomainControllers switch is enabled. Otherwise this parameter is ignored.

    .PARAMETER SkipRODC
    Skip Read-Only Domain Controllers. By default all domain controllers are included.

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .EXAMPLE
    An example

    .NOTES
    Based on:
    - https://stackoverflow.com/questions/51405489/what-is-the-difference-between-the-disabledbydefault-and-enabled-ssl-tls-registr
    - https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/manage-ssl-protocols-in-ad-fs
    - https://docs.microsoft.com/en-us/windows-server/security/tls/tls-registry-settings
    - https://docs.microsoft.com/en-us/security/engineering/solving-tls1-problem
    - https://docs.microsoft.com/en-us/windows/win32/secauthn/protocols-in-tls-ssl--schannel-ssp-
    #>
    [CmdletBinding()]
    param(
        [alias('Server')][string[]] $ComputerName,

        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Computers = @(
        if ($ComputerName) {
            foreach ($Computer in $ComputerName) {
                [PSCustomObject] @{
                    HostName = $Computer
                    Domain   = 'Not provided'
                }
            }
        } else {
            $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
            foreach ($DC in $ForestInformation.ForestDomainControllers) {
                [PSCustomObject] @{
                    HostName = $DC.HostName
                    Domain   = $DC.Domain
                }
            }
        }
    )
    foreach ($DC in $Computers) {
        #$Connectivity = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'
        $Version = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        if ($Version.PSConnection -eq $true) {

            $WindowsVersion = ConvertTo-OperatingSystem -OperatingSystem $Version.ProductName -OperatingSystemVersion $Version.CurrentBuildNumber
            # According to this https://github.com/MicrosoftDocs/windowsserverdocs/issues/2783 SCHANNEL service requires direct enablement
            $ProtocolDefaults = Get-ProtocolDefaults -WindowsVersion $WindowsVersion

            $Client = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client'
            $Server = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server'
            $Client30 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client'
            $Server30 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server'
            $ClientTLS10 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client'
            $ServerTLS10 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server'
            $ClientTLS11 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client'
            $ServerTLS11 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server'
            $ClientTLS12 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
            $ServerTLS12 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
            #$ClientTLS13 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client'
            #$ServerTLS13 = Get-PSRegistry -ComputerName $DC.HostName -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server'

            [PSCustomObject] @{
                ComputerName  = $DC.HostName
                DomainName    = $DC.Domain
                Version       = $WindowsVersion
                SSL_2_Client  = Get-ProtocolStatus -RegistryEntry $Client -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'SSL2Client'
                SSL_2_Server  = Get-ProtocolStatus -RegistryEntry $Server -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'SSL2Server'
                SSL_3_Client  = Get-ProtocolStatus -RegistryEntry $Client30 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'SSL3Client'
                SSL_3_Server  = Get-ProtocolStatus -RegistryEntry $Server30 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'SSL3Server'
                TLS_10_Client = Get-ProtocolStatus -RegistryEntry $ClientTLS10 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS10Client'
                TLS_10_Server = Get-ProtocolStatus -RegistryEntry $ServerTLS10 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS10Server'
                TLS_11_Client = Get-ProtocolStatus -RegistryEntry $ClientTLS11 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS11Client'
                TLS_11_Server = Get-ProtocolStatus -RegistryEntry $ServerTLS11 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS11Server'
                TLS_12_Client = Get-ProtocolStatus -RegistryEntry $ClientTLS12 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS12Client'
                TLS_12_Server = Get-ProtocolStatus -RegistryEntry $ServerTLS12 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS12Server'
                TLS_13_Client = Get-ProtocolStatus -RegistryEntry $ClientTLS13 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS13Client'
                TLS_13_Server = Get-ProtocolStatus -RegistryEntry $ServerTLS13 -WindowsVersion $WindowsVersion -ProtocolDefaults $ProtocolDefaults -Protocol 'TLS13Server'
            }
        } else {
            [PSCustomObject] @{
                ComputerName  = $DC.HostName
                DomainName    = $DC.Domain
                Version       = 'Unknown'
                SSL_2_Client  = 'No connection'
                SSL_2_Server  = 'No connection'
                SSL_3_Client  = 'No connection'
                SSL_3_Server  = 'No connection'
                TLS_10_Client = 'No connection'
                TLS_10_Server = 'No connection'
                TLS_11_Client = 'No connection'
                TLS_11_Server = 'No connection'
                TLS_12_Client = 'No connection'
                TLS_12_Server = 'No connection'
                #TLS_13_Client = Get-ProtocolStatus -RegistryEntry $ClientTLS13
                #TLS_13_Server = Get-ProtocolStatus -RegistryEntry $ServerTLS13
            }
        }
    }
}