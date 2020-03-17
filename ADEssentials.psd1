@{
    AliasesToExport      = 'Get-WinADRoles', 'Get-WinADDomainRoles', 'Get-WinADGPOSysvol', 'Get-WinADUsersFP'
    Author               = 'Przemyslaw Klys'
    CompanyName          = 'Evotec'
    CompatiblePSEditions = 'Desktop', 'Core'
    Copyright            = '(c) 2011 - 2020 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'Helper module for Active Directory'
    FunctionsToExport    = 'Get-ADACL', 'Get-WinADBitlockerLapsSummary', 'Get-WinADDFSHealth', 'Get-WinADDiagnostics', 'Get-WinADForestObjectsConflict', 'Get-WinADForestOptionalFeatures', 'Get-WinADForestReplication', 'Get-WinADForestRoles', 'Get-WinADForestSchemaProperties', 'Get-WinADForestSites', 'Get-WinADForestTomebstoneLifetime', 'Get-WinADGPOMissingPermissions', 'Get-WinADGPOSysvolFolders', 'Get-WinADLastBackup', 'Get-WinADLDAPBindingsSummary', 'Get-WinADLMSettings', 'Get-WinADPriviligedObjects', 'Get-WinADProxyAddresses', 'Get-WinADSiteConnections', 'Get-WinADSiteLinks', 'Get-WinADTombstoneLifetime', 'Get-WinADTrusts', 'Get-WinADUserPrincipalName', 'Get-WinADUsersForeignSecurityPrincipalList', 'Rename-WinADUserPrincipalName', 'Repair-WinADEmailAddress', 'Set-WinADDiagnostics', 'Set-WinADReplication', 'Set-WinADReplicationConnections', 'Set-WinADTombstoneLifetime', 'Sync-DomainController', 'Test-ADDomainController', 'Test-ADRolesAvailability', 'Test-ADSiteLinks', 'Test-DNSNameServers', 'Test-FSMORolesAvailability', 'Test-LDAP'
    GUID                 = '9fc9fd61-7f11-4f4b-a527-084086f1905f'
    ModuleVersion        = '0.0.46'
    PowerShellVersion    = '5.1'
<<<<<<< HEAD
=======

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @(@{ModuleName = 'PSEventViewer'; GUID = '5df72a79-cdf6-4add-b38d-bcacf26fb7bc'; ModuleVersion = '1.0.13'; }, 
        @{ModuleName = 'PSSharedGoods'; GUID = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'; ModuleVersion = '0.0.129'; })

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = 'Get-ADACL', 'Get-WinADBitlockerLapsSummary', 'Get-WinADDFSHealth', 
    'Get-WinADDiagnostics', 'Get-WinADForestObjectsConflict', 
    'Get-WinADForestReplication', 'Get-WinADForestRoles', 
    'Get-WinADGPOMissingPermissions', 'Get-WinADGPOSysvolFolders', 
    'Get-WinADLastBackup', 'Get-WinADLDAPBindingsSummary', 
    'Get-WinADLMSettings', 'Get-WinADPrivilegedObjects', 
    'Get-WinADProxyAddresses', 'Get-WinADSiteConnections', 
    'Get-WinADSiteLinks', 'Get-WinADTombstoneLifetime', 'Get-WinADTrusts', 
    'Get-WinADUserPrincipalName', 
    'Get-WinADUsersForeignSecurityPrincipalList', 
    'Rename-WinADUserPrincipalName', 'Repair-WinADEmailAddress', 
    'Set-WinADDiagnostics', 'Set-WinADReplication', 
    'Set-WinADReplicationConnections', 'Set-WinADTombstoneLifetime', 
    'Sync-DomainController', 'Test-ADDomainController', 
    'Test-ADRolesAvailability', 'Test-ADSiteLinks', 'Test-DNSNameServers', 
    'Test-FSMORolesAvailability', 'Test-LDAP'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    # VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = 'Get-WinADRoles', 'Get-WinADDomainRoles', 'Get-WinADGPOSysvol', 
    'Get-WinADUsersFP'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
>>>>>>> 13c23bf5481675ddaf21ff496df4423e8b6ad6cd
    PrivateData          = @{
        PSData = @{
            Tags                       = 'Windows', 'ActiveDirectory'
            ProjectUri                 = 'https://github.com/EvotecIT/ADEssentials'
            ExternalModuleDependencies = 'ActiveDirectory', 'GroupPolicy', 'DnsServer', 'NetTCPIP'
        }
    }
    RequiredModules      = @{
        ModuleVersion = '1.0.13'
        ModuleName    = 'PSEventViewer'
        Guid          = '5df72a79-cdf6-4add-b38d-bcacf26fb7bc'
    }, @{
        ModuleVersion = '0.0.130'
        ModuleName    = 'PSSharedGoods'
        Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
    }, 'ActiveDirectory', 'GroupPolicy', 'DnsServer', 'NetTCPIP'
    RootModule           = 'ADEssentials.psm1'
}