function Get-WinADDomainControllerNetLogonSettings {
    <#
    .SYNOPSIS
    Gathers information about NetLogon settings on a Domain Controller

    .DESCRIPTION
    Gathers information about NetLogon settings on a Domain Controller

    .PARAMETER DomainController
    Specifies the Domain Controller to retrieve information from

    .PARAMETER All
    Retrieves all information from registry as is without any processing

    .EXAMPLE
    Get-WinADDomainControllerNetLogonSettings -DomainController 'AD1'

    .EXAMPLE
    Get-WinADDomainControllerNetLogonSettings -DomainController 'AD1' -All

    .NOTES
    Useful links:
    - https://www.oreilly.com/library/view/active-directory-cookbook/0596004648/ch11s20.html
    - https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.NetLogon::Netlogon_AutoSiteCoverage
    - https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.NetLogon::Netlogon_SiteCoverage
    - https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.NetLogon::Netlogon_GcSiteCoverage

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Alias('ComputerName')][string] $DomainController,
        [switch] $All
    )

    $RegistryNetLogon = Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -ComputerName $DomainController
    if ($All) {
        $RegistryNetLogon
    } else {
        $GCSiteCoverage = $RegistryNetLogon.'GCSiteCoverage'
        if ($GCSiteCoverage) {
            $GCSiteCoverage = $GCSiteCoverage -split ','
        } else {
            $GCSiteCoverage = @()
        }
        $SiteCoverage = $RegistryNetLogon.'SiteCoverage'
        if ($SiteCoverage) {
            $SiteCoverage = $SiteCoverage -split ','
        } else {
            $SiteCoverage = @()
        }
        [PSCustomObject] @{
            'DomainController'  = $RegistryNetLogon.'PSComputerName'
            'DynamicSiteName'   = $RegistryNetLogon.'DynamicSiteName'
            'SiteCoverage'      = $SiteCoverage
            'GCSiteCoverage'    = $GCSiteCoverage
            'RequireSignOrSeal' = $RegistryNetLogon.'RequireSignOrSeal'
            'RequireSeal'       = $RegistryNetLogon.'RequireSeal'
            'Error'             = $RegistryNetLogon.'PSError'
            'ErrorMessage'      = $RegistryNetLogon.'PSErrorMessage'
        }
    }
}
