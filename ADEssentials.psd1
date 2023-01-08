@{
    AliasesToExport      = @('Get-WinDNSServerIP', 'Get-WinADForestObjectsConflict', 'Get-WinADRoles', 'Get-WinADDomainRoles', 'Get-WinADSubnet', 'Get-WinADPriviligedObjects', 'Get-WinADForestTomebstoneLifetime', 'Get-WinADTrusts', 'Get-WinADUsersFP', 'Set-WinDNSServerIP', 'Show-WinADCriticalGroups', 'Show-ADGroupMember', 'Show-ADGroupMemberOf', 'Show-ADTrust', 'Show-ADTrusts', 'Show-WinADTrusts')
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2023 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'Helper module for Active Directory with lots of useful functions that simplify supporting Active Directory.'
    FunctionsToExport    = @('Add-ADACL', 'Copy-ADOUSecurity', 'Disable-ADACLInheritance', 'Enable-ADACLInheritance', 'Export-ADACLObject', 'Get-ADACL', 'Get-ADACLOwner', 'Get-DNSServerIP', 'Get-WinADACLConfiguration', 'Get-WinADACLForest', 'Get-WinADBitlockerLapsSummary', 'Get-WinADComputerACLLAPS', 'Get-WinADComputers', 'Get-WinADDelegatedAccounts', 'Get-WinADDFSHealth', 'Get-WinADDHCP', 'Get-WinADDiagnostics', 'Get-WinADDomain', 'Get-WinADDuplicateObject', 'Get-WinADDuplicateSPN', 'Get-WinADForest', 'Get-WinADForestControllerInformation', 'Get-WinADForestOptionalFeatures', 'Get-WinADForestReplication', 'Get-WinADForestRoles', 'Get-WinADForestSchemaProperties', 'Get-WinADForestSites', 'Get-WinADForestSubnet', 'Get-WinADGroupMember', 'Get-WinADGroupMemberOf', 'Get-WinADGroups', 'Get-WinADLastBackup', 'Get-WinADLDAPBindingsSummary', 'Get-WinADLMSettings', 'Get-WinADObject', 'Get-WinADPrivilegedObjects', 'Get-WinADProtocol', 'Get-WinADProxyAddresses', 'Get-WinADServiceAccount', 'Get-WinADSharePermission', 'Get-WinADSiteConnections', 'Get-WinADSiteLinks', 'Get-WinADTomebstoneLifetime', 'Get-WinADTrust', 'Get-WinADTrustLegacy', 'Get-WinADUserPrincipalName', 'Get-WinADUsers', 'Get-WinADUsersForeignSecurityPrincipalList', 'Get-WinADWellKnownFolders', 'Get-WinDNSIPAddresses', 'Get-WinDNSRecords', 'Invoke-ADEssentials', 'New-ADACLObject', 'New-ADSite', 'Remove-ADACL', 'Remove-WinADDuplicateObject', 'Remove-WinADSharePermission', 'Rename-WinADUserPrincipalName', 'Repair-WinADACLConfigurationOwner', 'Repair-WinADEmailAddress', 'Repair-WinADForestControllerInformation', 'Set-ADACL', 'Set-ADACLInheritance', 'Set-ADACLOwner', 'Set-DnsServerIP', 'Set-WinADDiagnostics', 'Set-WinADForestACLOwner', 'Set-WinADReplication', 'Set-WinADReplicationConnections', 'Set-WinADShare', 'Set-WinADTombstoneLifetime', 'Show-WinADDNSRecords', 'Show-WinADGroupCritical', 'Show-WinADGroupMember', 'Show-WinADGroupMemberOf', 'Show-WinADOrganization', 'Show-WinADSites', 'Show-WinADTrust', 'Show-WinADUserSecurity', 'Sync-DomainController', 'Test-ADDomainController', 'Test-ADRolesAvailability', 'Test-ADSiteLinks', 'Test-DNSNameServers', 'Test-FSMORolesAvailability', 'Test-LDAP', 'Test-WinADVulnerableSchemaClass')
    GUID                 = '9fc9fd61-7f11-4f4b-a527-084086f1905f'
    ModuleVersion        = '0.0.150'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags       = @('Windows', 'ActiveDirectory')
            ProjectUri = 'https://github.com/EvotecIT/ADEssentials'
        }
    }
    RequiredModules      = @(@{
            ModuleVersion = '1.0.22'
            ModuleName    = 'PSEventViewer'
            Guid          = '5df72a79-cdf6-4add-b38d-bcacf26fb7bc'
        }, @{
            ModuleVersion = '0.0.254'
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        }, @{
            ModuleVersion = '0.0.180'
            ModuleName    = 'PSWriteHTML'
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
        })
    RootModule           = 'ADEssentials.psm1'
}