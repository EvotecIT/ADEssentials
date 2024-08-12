function Set-WinADDomainControllerNetLogonSettings {
    <#
    .SYNOPSIS
    Helps settings SiteCoverage, GCSiteCoverage and RequireSeal on Domain Controllers

    .DESCRIPTION
    Helps settings SiteCoverage, GCSiteCoverage and RequireSeal on Domain Controllers

    .PARAMETER DomainController
    Specifies the Domain Controller to set information on

    .PARAMETER SiteCoverage
    Specifies the Site Coverage to set on the Domain Controller. If null, it will remove the Site Coverage

    .PARAMETER GCSiteCoverage
    Specifies the GC Site Coverage to set on the Domain Controller. If null, it will remove the GC Site Coverage

    .PARAMETER RequireSeal
    Specifies the RequireSeal to set on the Domain Controller. Possible values are Disabled, Compatibility, Enforcement

    .EXAMPLE
    An example

    .NOTES
    SiteCoverage:
    - https://www.oreilly.com/library/view/active-directory-cookbook/0596004648/ch11s20.html
    - https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.NetLogon::Netlogon_AutoSiteCoverage
    - https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.NetLogon::Netlogon_SiteCoverage
    - https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.NetLogon::Netlogon_GcSiteCoverage

    RequireSeal:
    - https://support.microsoft.com/en-us/topic/kb5021130-how-to-manage-the-netlogon-protocol-changes-related-to-cve-2022-38023-46ea3067-3989-4d40-963c-680fd9e8ee25
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Alias('ComputerName')][string] $DomainController,
        [string[]] $SiteCoverage,
        [string[]] $GCSiteCoverage,
        [ValidateSet('Disabled', 'Compatibility', 'Enforcement')] $RequireSeal,
        [switch] $DoNotSuppress
    )
    $RegistryNetLogon = Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -ComputerName $DomainController

    if ($RequireSeal) {
        $RequireSealTranslation = @{
            'Disabled'      = 0
            'Compatibility' = 1 # this shouldn't be used after 2023
            'Enforcement'   = 2
        }
        $RequireSealValue = $RequireSealTranslation[$RequireSeal]
        if ($RegistryNetLogon.'RequireSignOrSeal' -ne $RequireSealValue) {
            if ($PSCmdlet.ShouldProcess("Setting RequireSignOrSeal to $RequireSealValue")) {
                $Output = Set-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Key 'RequireSeal' -Value $RequireSealValue -Type REG_DWORD -ComputerName $DomainController
                if ($DoNotSuppress) {
                    $Output
                }
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('SiteCoverage')) {
        if ($null -eq $SiteCoverage) {
            if ($null -ne $RegistryNetLogon.'SiteCoverage') {
                if ($PSCmdlet.ShouldProcess($DomainController, "Removing SiteCoverage from Domain Controller")) {
                    $Output = Remove-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Key 'SiteCoverage' -ComputerName $DomainController
                    if ($DoNotSuppress) {
                        $Output
                    }
                }
            }
        } else {
            if ($SiteCoverage -isnot [string]) {
                $JoinedSiteCoverage = $SiteCoverage -join ','
            } else {
                $JoinedSiteCoverage = $SiteCoverage
            }
            if ($RegistryNetLogon.'SiteCoverage' -ne $JoinedSiteCoverage) {
                if ($PSCmdlet.ShouldProcess($DomainController, "Setting SiteCoverage to $JoinedSiteCoverage")) {
                    $Output = Set-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Type REG_SZ -Key 'SiteCoverage' -Value $JoinedSiteCoverage -ComputerName $DomainController
                    if ($DoNotSuppress) {
                        $Output
                    }
                }
            }
        }
    }
    if ($PSBoundParameters.ContainsKey('GCSiteCoverage')) {
        if ($null -eq $GCSiteCoverage) {
            if ($null -ne $RegistryNetLogon.'GCSiteCoverage') {
                if ($PSCmdlet.ShouldProcess($DomainController, "Removing GCSiteCoverage from Domain Controller")) {
                    $Output = Remove-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Key 'GcSiteCoverage' -ComputerName $DomainController
                    if ($DoNotSuppress) {
                        $Output
                    }
                }
            }
        } else {
            if ($GCSiteCoverage -isnot [string]) {
                $JoinedGCSiteCoverage = $GCSiteCoverage -join ','
            } else {
                $JoinedGCSiteCoverage = $GCSiteCoverage
            }
            if ($RegistryNetLogon.'GCSiteCoverage' -ne $JoinedGCSiteCoverage) {
                if ($PSCmdlet.ShouldProcess($DomainController, "Setting GCSiteCoverage to $JoinedGCSiteCoverage")) {
                    $Output = Set-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Type REG_SZ -Key 'GcSiteCoverage' -Value $JoinedGCSiteCoverage -ComputerName $DomainController
                    if ($DoNotSuppress) {
                        $Output
                    }
                }
            }
        }
    }
}