function Get-WinADLMSettings {
    <#
    .SYNOPSIS
    Retrieves and displays Active Directory LM settings for Windows Clients and Servers.

    .DESCRIPTION
    Retrieves and displays Active Directory LM settings for Windows Clients and Servers. By default, it scans all Domain Controllers in a forest.

    .PARAMETER ForestName
    Specifies the target forest to retrieve LM settings from.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in the search.

    .PARAMETER SkipRODC
    Skips Read-Only Domain Controllers. By default, all domain controllers are included.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .EXAMPLE
    Get-WinADLMSettings -ForestName "example.com" -IncludeDomains "example.com" -Days 7
    This example retrieves LM settings for the "example.com" forest, including only the specified domains and considering the last 7 days.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'DomainController')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($ComputerName in $ForestInformation.ForestDomainControllers.HostName) {
        $LSA = Get-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa' -ComputerName $ComputerName

        <#
        auditbasedirectories      : 0
        auditbaseobjects          : 0
        Bounds                    : {0, 48, 0, 0...}
        crashonauditfail          : 0
        fullprivilegeauditing     : {0}
        LimitBlankPasswordUse     : 1
        NoLmHash                  : 1
        disabledomaincreds        : 0
        everyoneincludesanonymous : 0
        forceguest                : 0
        LsaCfgFlagsDefault        : 0
        LsaPid                    : 1232
        ProductType               : 4
        restrictanonymous         : 0
        restrictanonymoussam      : 1
        SecureBoot                : 1
        ComputerName              :
        #>


        if ($Lsa -and $Lsa.PSError -eq $false) {
            if ($LSA.lmcompatibilitylevel) {
                $LMCompatibilityLevel = $LSA.lmcompatibilitylevel
            } else {
                $LMCompatibilityLevel = 3
            }

            $LM = @{
                0 = 'Server sends LM and NTLM response and never uses extended session security. Clients use LM and NTLM authentication, and never use extended session security. DCs accept LM, NTLM, and NTLM v2 authentication.'
                1 = 'Servers use NTLM v2 session security if it is negotiated. Clients use LM and NTLM authentication and use extended session security if the server supports it. DCs accept LM, NTLM, and NTLM v2 authentication.'
                2 = 'Server sends NTLM response only. Clients use only NTLM authentication and use extended session security if the server supports it. DCs accept LM, NTLM, and NTLM v2 authentication.'
                3 = 'Server sends NTLM v2 response only. Clients use NTLM v2 authentication and use extended session security if the server supports it. DCs accept LM, NTLM, and NTLM v2 authentication.'
                4 = 'DCs refuse LM responses. Clients use NTLM authentication and use extended session security if the server supports it. DCs refuse LM authentication but accept NTLM and NTLM v2 authentication.'
                5 = 'DCs refuse LM and NTLM responses, and accept only NTLM v2. Clients use NTLM v2 authentication and use extended session security if the server supports it. DCs refuse NTLM and LM authentication, and accept only NTLM v2 authentication.'
            }
            [PSCustomObject] @{
                ComputerName              = $ComputerName
                LSAProtectionCredentials  = [bool] $LSA.RunAsPPL # https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection
                Level                     = $LMCompatibilityLevel
                LevelDescription          = $LM[$LMCompatibilityLevel]
                EveryoneIncludesAnonymous = [bool] $LSA.everyoneincludesanonymous
                LimitBlankPasswordUse     = [bool] $LSA.LimitBlankPasswordUse
                NoLmHash                  = [bool] $LSA.NoLmHash
                DisableDomainCreds        = [bool] $LSA.disabledomaincreds # https://www.stigviewer.com/stig/windows_8/2014-01-07/finding/V-3376
                ForceGuest                = [bool] $LSA.forceguest
                RestrictAnonymous         = [bool] $LSA.restrictanonymous
                RestrictAnonymousSAM      = [bool] $LSA.restrictanonymoussam
                SecureBoot                = [bool] $LSA.SecureBoot
                LsaCfgFlagsDefault        = $LSA.LsaCfgFlagsDefault
                LSAPid                    = $LSA.LSAPid
                AuditBaseDirectories      = [bool] $LSA.auditbasedirectories
                AuditBaseObjects          = [bool] $LSA.auditbaseobjects # https://www.stigviewer.com/stig/windows_server_2012_member_server/2014-01-07/finding/V-14228 | Should be false
                CrashOnAuditFail          = $LSA.CrashOnAuditFail # http://systemmanager.ru/win2k_regestry.en/46686.htm | Should be 0
                DsrmAdminLogonBehavior    = $LSA.DsrmAdminLogonBehavior # Should be empty or 0. # https://www.sentinelone.com/blog/detecting-dsrm-account-misconfigurations/
            }
        } else {
            [PSCustomObject] @{
                ComputerName              = $ComputerName
                LSAProtectionCredentials  = $null
                Level                     = $null
                LevelDescription          = $null
                EveryoneIncludesAnonymous = $null
                LimitBlankPasswordUse     = $null
                NoLmHash                  = $null
                DisableDomainCreds        = $null
                ForceGuest                = $null
                RestrictAnonymous         = $null
                RestrictAnonymousSAM      = $null
                SecureBoot                = $null
                LsaCfgFlagsDefault        = $null
                LSAPid                    = $null
                AuditBaseDirectories      = $null
                AuditBaseObjects          = $null
                CrashOnAuditFail          = $null
                DsrmAdminLogonBehavior    = $null
            }
        }
    }
}