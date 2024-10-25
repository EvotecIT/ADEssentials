@{
    AliasesToExport      = @('Get-WinDNSServerIP', 'Get-WinDnsIPAddresses', 'Get-WinDNSRecords', 'Get-WinDnsServerZones', 'Get-WinDNSZones', 'Get-WinADForestObjectsConflict', 'Get-WinADRoles', 'Get-WinADDomainRoles', 'Get-WinADSubnet', 'Get-WinADPriviligedObjects', 'Get-WinADForestTombstoneLifetime', 'Get-WinADTrusts', 'Get-WinADUsersFP', 'Set-WinDNSServerIP', 'Show-WinADCriticalGroups', 'Show-ADGroupMember', 'Show-ADGroupMemberOf', 'Show-WinADSiteCoverage', 'Show-ADTrust', 'Show-ADTrusts', 'Show-WinADTrusts', 'Sync-DomainController')
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2024 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'Helper module for Active Directory with lots of useful functions that simplify supporting Active Directory.'
    FunctionsToExport    = @('Add-ADACL', 'Compare-PingCastleReport', 'Compare-WinADGlobalCatalogObjects', 'Convert-ADSecurityDescriptor', 'Copy-ADOUSecurity', 'Disable-ADACLInheritance', 'Enable-ADACLInheritance', 'Export-ADACLObject', 'Find-WinADObjectDifference', 'Get-ADACL', 'Get-ADACLOwner', 'Get-DNSServerIP', 'Get-PingCastleReport', 'Get-WinADACLConfiguration', 'Get-WinADACLForest', 'Get-WinADBitlockerLapsSummary', 'Get-WinADComputerACLLAPS', 'Get-WinADComputers', 'Get-WinADDelegatedAccounts', 'Get-WinADDFSHealth', 'Get-WinADDFSTopology', 'Get-WinADDHCP', 'Get-WinADDiagnostics', 'Get-WinADDnsInformation', 'Get-WinADDnsIPAddresses', 'Get-WinADDnsRecords', 'Get-WinADDnsServerForwarder', 'Get-WinADDnsServerScavenging', 'Get-ADWinDnsServerZones', 'Get-WinADDNSZones', 'Get-WinADDomain', 'Get-WinADDomainControllerGenerationId', 'Get-WinADDomainControllerNetLogonSettings', 'Get-WinADDomainControllerNTDSSettings', 'Get-WinADDomainControllerOption', 'Get-WinADDuplicateObject', 'Get-WinADDuplicateSPN', 'Get-WinADForest', 'Get-WinADForestControllerInformation', 'Get-WinADForestOptionalFeatures', 'Get-WinADForestReplication', 'Get-WinADForestReplicationSummary', 'Get-WinADForestRoles', 'Get-WinADForestSchemaProperties', 'Get-WinADForestSites', 'Get-WinADForestSubnet', 'Get-WinADGroupMember', 'Get-WinADGroupMemberOf', 'Get-WinADGroups', 'Get-WinADKerberosAccount', 'Get-WinADLastBackup', 'Get-WinADLDAPBindingsSummary', 'Get-WinADLMSettings', 'Get-WinADObject', 'Get-WinADPasswordPolicy', 'Get-WinADPrivilegedObjects', 'Get-WinADProtocol', 'Get-WinADProxyAddresses', 'Get-WinADSchemaDefaultPermission', 'Get-WinADServiceAccount', 'Get-WinADSharePermission', 'Get-WinADSiteConnections', 'Get-WinADSiteCoverage', 'Get-WinADSiteLinks', 'Get-WinADSiteOptions', 'Get-WinADTombstoneLifetime', 'Get-WinADTrust', 'Get-WinADTrustLegacy', 'Get-WinADUserPrincipalName', 'Get-WinADUsers', 'Get-WinADUsersForeignSecurityPrincipalList', 'Get-WinADWellKnownFolders', 'Invoke-ADEssentials', 'Invoke-PingCastle', 'New-ADACLObject', 'New-ADSite', 'Remove-ADACL', 'Remove-WinADDFSTopology', 'Remove-WinADDuplicateObject', 'Remove-WinADSharePermission', 'Rename-WinADUserPrincipalName', 'Repair-WinADACLConfigurationOwner', 'Repair-WinADEmailAddress', 'Repair-WinADForestControllerInformation', 'Request-ChangePasswordAtLogon', 'Request-DisableOnAccountExpiration', 'Restore-ADACLDefault', 'Set-ADACL', 'Set-ADACLInheritance', 'Set-ADACLOwner', 'Set-DnsServerIP', 'Set-WinADDiagnostics', 'Set-WinADDomainControllerNetLogonSettings', 'Set-WinADDomainControllerOption', 'Set-WinADForestACLOwner', 'Set-WinADReplication', 'Set-WinADReplicationConnections', 'Set-WinADShare', 'Set-WinADTombstoneLifetime', 'Show-WinADDNSRecords', 'Show-WinADGroupCritical', 'Show-WinADGroupMember', 'Show-WinADGroupMemberOf', 'Show-WinADKerberosAccount', 'Show-WinADObjectDifference', 'Show-WinADOrganization', 'Show-WinADSites', 'Show-WinADSitesCoverage', 'Show-WinADTrust', 'Show-WinADUserSecurity', 'Sync-WinADDomainController', 'Test-ADDomainController', 'Test-ADRolesAvailability', 'Test-ADSiteLinks', 'Test-DNSNameServers', 'Test-FSMORolesAvailability', 'Test-LDAP', 'Test-WinADDNSResolving', 'Test-WinADObjectReplicationStatus', 'Test-WinADVulnerableSchemaClass', 'Update-LastLogonTimestamp')
    GUID                 = '9fc9fd61-7f11-4f4b-a527-084086f1905f'
    ModuleVersion        = '0.0.221'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            ProjectUri = 'https://github.com/EvotecIT/ADEssentials'
            Tags       = @('Windows', 'ActiveDirectory')
        }
    }
    RequiredModules      = @(@{
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
            ModuleName    = 'PSSharedGoods'
            ModuleVersion = '0.0.297'
        }, @{
            Guid          = 'a7bdf640-f5cb-4acf-9de0-365b322d245c'
            ModuleName    = 'PSWriteHTML'
            ModuleVersion = '1.27.0'
        }, @{
            Guid          = '5df72a79-cdf6-4add-b38d-bcacf26fb7bc'
            ModuleName    = 'PSEventViewer'
            ModuleVersion = '1.0.22'
        })
    RootModule           = 'ADEssentials.psm1'
}