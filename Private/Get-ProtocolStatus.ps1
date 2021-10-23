function Get-ProtocolStatus {
    <#
    .SYNOPSIS
    Translates registry of protocol to status

    .DESCRIPTION
    Translates registry of protocol to status

    .PARAMETER RegistryEntry
    Accepts registry entry from Get-PSRegistry

    .EXAMPLE
    $Client = Get-PSRegistry -ComputerName 'AD1' -RegistryPath 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client'
    Get-ProtocolStatus -RegistryEntry $Client

    .NOTES
    When DisabledByDefault flag is set to 1, SSL / TLS version X is not used by default. If an SSPI app requests to use this version of SSL / TLS, it will be negotiated. In a nutshell, SSL is not disabled when you use DisabledByDefault flag.
    When Enabled flag is set to 0, SSL / TLS version X is disabled and cannot be nagotiated by any SSPI app (even if DisabledByDefault flag is set to 0).
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject] $RegistryEntry,
        [string] $WindowsVersion
    )



    if ($RegistryEntry.PSConnection -eq $true) {
        if ($RegistryEntry.PSError -eq $true) {
            #$Status = 'Not set, enabled'
            $Status = 'Enabled'
        } else {
            if ($RegistryEntry.DisabledByDefault -eq 0 -and $RegistryEntry.Enabled -eq 1) {
                $Status = 'Enabled'
            } elseif ($RegistryEntry.DisabledByDefault -eq 1 -and $RegistryEntry.Enabled -eq 0) {
                $Status = 'Disabled'
            } elseif ($RegistryEntry.DisabledByDefault -eq 1 -and $RegistryEntry.Enabled -eq 1) {
                $Status = 'Enabled'
            } elseif ($RegistryEntry.DisabledByDefault -eq 0 -and $RegistryEntry.Enabled -eq 0) {
                $Status = 'Disabled'
            } elseif ($RegistryEntry.DisabledByDefault -eq 0) {
                $Status = 'Enabled'
            } elseif ($RegistryEntry.DisabledByDefault -eq 1) {
                $Status = 'DisabledDefault'
            } elseif ($RegistryEntry.Enabled -eq 1) {
                $Status = 'Enabled'
            } elseif ($RegistryEntry.Enabled -eq 0) {
                $Status = 'Disabled'
            } else {
                $Status = 'Wont happen'
            }
        }
    } else {
        $Status = 'No connection'
    }
    $Status
}