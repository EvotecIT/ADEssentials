Clear-Host
Import-Module "C:\Support\GitHub\PSPublishModule\PSPublishModule.psd1" -Force

Invoke-ModuleBuild -ModuleName 'ADEssentials' {
    # Usual defaults as per standard module
    $Manifest = [ordered] @{
        ModuleVersion        = '0.0.X'
        # Supported PSEditions
        CompatiblePSEditions = @('Desktop', 'Core')
        # ID used to uniquely identify this module
        GUID                 = '9fc9fd61-7f11-4f4b-a527-084086f1905f'
        # Author of this module
        Author               = 'Przemyslaw Klys'
        # Company or vendor of this module
        CompanyName          = 'Evotec'
        # Copyright statement for this module
        Copyright            = "(c) 2011 - $((Get-Date).Year) Przemyslaw Klys @ Evotec. All rights reserved."
        # Description of the functionality provided by this module
        Description          = 'Helper module for Active Directory with lots of useful functions that simplify supporting Active Directory.'
        # Minimum version of the Windows PowerShell engine required by this module
        PowerShellVersion    = '5.1'
        # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
        Tags                 = @('Windows', 'ActiveDirectory')
        #IconUri              = 'https://evotec.xyz/wp-content/uploads/2018/10/PSSharedGoods-Alternative.png'
        ProjectUri           = 'https://github.com/EvotecIT/ADEssentials'
    }
    New-ConfigurationManifest @Manifest

    New-ConfigurationModule -Type RequiredModule -Name 'PSSharedGoods' -Version Latest -Guid Auto
    New-ConfigurationModule -Type RequiredModule -Name 'PSWriteHTML' -Version 1.27.0 -Guid Auto
    New-ConfigurationModule -Type RequiredModule -Name 'PSEventViewer' -Version 1.0.22 -Guid Auto
    New-ConfigurationModule -Type ApprovedModule -Name @('PSSharedGoods', 'PSWriteColor', 'Connectimo', 'PSUnifi', 'PSWebToolbox', 'PSMyPassword')

    New-ConfigurationModuleSkip -IgnoreFunctionName @(
        'ConvertTo-Excel'
    ) -IgnoreModuleName @(
        'PSWriteExcel', 'ActiveDirectory', 'Microsoft.PowerShell.Security',
        'Microsoft.WSMan.Management', 'NetTCPIP', 'PowerShellGet', 'CimCmdlets'
        'DnsServer', 'DnsClient', 'DhcpServer'
    )

    $ConfigurationFormat = [ordered] @{
        RemoveComments                              = $false

        PlaceOpenBraceEnable                        = $true
        PlaceOpenBraceOnSameLine                    = $true
        PlaceOpenBraceNewLineAfter                  = $true
        PlaceOpenBraceIgnoreOneLineBlock            = $false

        PlaceCloseBraceEnable                       = $true
        PlaceCloseBraceNewLineAfter                 = $false
        PlaceCloseBraceIgnoreOneLineBlock           = $false
        PlaceCloseBraceNoEmptyLineBefore            = $true

        UseConsistentIndentationEnable              = $true
        UseConsistentIndentationKind                = 'space'
        UseConsistentIndentationPipelineIndentation = 'IncreaseIndentationAfterEveryPipeline'
        UseConsistentIndentationIndentationSize     = 4

        UseConsistentWhitespaceEnable               = $true
        UseConsistentWhitespaceCheckInnerBrace      = $true
        UseConsistentWhitespaceCheckOpenBrace       = $true
        UseConsistentWhitespaceCheckOpenParen       = $true
        UseConsistentWhitespaceCheckOperator        = $true
        UseConsistentWhitespaceCheckPipe            = $true
        UseConsistentWhitespaceCheckSeparator       = $true

        AlignAssignmentStatementEnable              = $true
        AlignAssignmentStatementCheckHashtable      = $true

        UseCorrectCasingEnable                      = $true
    }
    # format PSD1 and PSM1 files when merging into a single file
    # enable formatting is not required as Configuration is provided
    New-ConfigurationFormat -ApplyTo 'OnMergePSM1', 'OnMergePSD1' -Sort None @ConfigurationFormat
    # format PSD1 and PSM1 files within the module
    # enable formatting is required to make sure that formatting is applied (with default settings)
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1', 'DefaultPSM1' -EnableFormatting -Sort None
    # when creating PSD1 use special style without comments and with only required parameters
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1', 'OnMergePSD1' -PSD1Style 'Minimal'
    # configuration for documentation, at the same time it enables documentation processing
    New-ConfigurationDocumentation -Enable:$false -StartClean -UpdateWhenNew -PathReadme 'Docs\Readme.md' -Path 'Docs'

    New-ConfigurationImportModule -ImportSelf

    # exposes specific commands only if following modules are available
    New-ConfigurationCommand -ModuleName 'ActiveDirectory' -CommandName @(
        'Add-ADACL'
        'Copy-ADOUSecurity'
        'New-ADACLObject'
        'Enable-ADACLInheritance'
        'Disable-ADACLInheritance'
        'Export-ADACLObject'
        'Get-ADACL'
        'Get-ADACLOwner'
        'Get-WinADACLConfiguration'
        'Get-WinADACLForest'
        'Get-WinADBitlockerLapsSummary'
        'Get-WinADComputerACLLAPS'
        'Get-WinADComputers'
        'Get-WinADDelegatedAccounts'
        'Get-WinADDFSHealth'
        'Get-WinADDHCP'
        'Get-WinADDiagnostics'
        'Get-WinADDuplicateObject'
        'Get-WinADDuplicateSPN'
        'Get-WinADForestControllerInformation'
        'Get-WinADForestOptionalFeatures'
        'Get-WinADForestReplication'
        'Get-WinADForestRoles'
        'Get-WinADForestSchemaProperties'
        'Get-WinADForestSites'
        'Get-WinADForestSubnet'
        'Get-WinADLastBackup'
        'Get-WinADLDAPBindingsSummary'
        'Get-WinADLMSettings'
        'Get-WinADPrivilegedObjects'
        'Get-WinADProtocol'
        'Get-WinADProxyAddresses'
        'Get-WinADServiceAccount'
        'Get-WinADSharePermission'
        'Get-WinADSiteConnections'
        'Get-WinADSiteLinks'
        'Get-WinADTomebstoneLifetime'
        'Get-WinADTrustLegacy'
        'Get-WinADUserPrincipalName'
        'Get-WinADUsers'
        'Get-WinADUsersForeignSecurityPrincipalList'
        'Get-WinADWellKnownFolders'
        'Get-WinADPasswordPolicy'
        'Invoke-ADEssentials'
        'Remove-ADACL'
        'Remove-WinADDuplicateObject'
        'Remove-WinADSharePermission'
        'Rename-WinADUserPrincipalName'
        'Repair-WinADACLConfigurationOwner'
        'Repair-WinADEmailAddress'
        'Repair-WinADForestControllerInformation'
        'Set-ADACLOwner'
        'Set-DnsServerIP'
        'Set-WinADDiagnostics'
        'Set-WinADReplication'
        'Set-WinADReplicationConnections'
        'Set-WinADShare'
        'Set-WinADTombstoneLifetime'
        'Show-WinADGroupCritical'
        'Show-WinADOrganization'
        'Show-WinADSites'
        'Show-WinADUserSecurity'
        'Sync-DomainController'
        'Test-ADDomainController'
        'Test-ADRolesAvailability'
        'Test-ADSiteLinks'
        'Test-DNSNameServers'
        'Test-FSMORolesAvailability'
        'Test-LDAP'
        'Get-WinDNSZones'
        'Get-WinDNSIPAddresses'
        'Find-WinADObjectDifference'
        'Show-WinADObjectDifference'
        'Test-WinADDNSResolving'
        'Get-WinADDomainControllerGenerationId'
        'Compare-WinADGlobalCatalogObjects'
        'Test-WinADObjectReplicationStatus'
        'Get-WinADSiteCoverage'
        'Get-WinADLDAPSummary'
        'Get-WinADForestReplicationSummary'
        'Show-WinADLdapSummary'
        'Show-WinADReplicationSummary'
    )
    New-ConfigurationCommand -ModuleName 'DHCPServer' -CommandName @(
        'Get-WinADDHCP'
    )
    New-ConfigurationCommand -ModuleName 'DNSServer' -CommandName @(
        'Get-WinADDnsInformation'
        'Get-WinADDNSIPAddresses'
        'Get-WinADDNSRecords'
        'Get-WinADDnsServerForwarder'
        'Get-WinADDnsServerScavenging'
        'Get-WinADDnsServerZones'
        'Get-WinADDnsZones'
        'Remove-WinADDnsRecord'
    )

    New-ConfigurationBuild -Enable:$true -SignModule -MergeModuleOnBuild -MergeFunctionsFromApprovedModules -CertificateThumbprint '483292C9E317AA13B07BB7A96AE9D1A5ED9E7703'

    $newConfigurationArtefactSplat = @{
        Type                = 'Unpacked'
        Enable              = $true
        Path                = "$PSScriptRoot\..\Artefacts\Unpacked"
        ModulesPath         = "$PSScriptRoot\..\Artefacts\Unpacked\Modules"
        RequiredModulesPath = "$PSScriptRoot\..\Artefacts\Unpacked\Modules"
        AddRequiredModules  = $true
        CopyFiles           = @{
            #"Examples\PublishingExample\Example-ExchangeEssentials.ps1" = "RunMe.ps1"
        }
    }
    New-ConfigurationArtefact @newConfigurationArtefactSplat -CopyFilesRelative
    $newConfigurationArtefactSplat = @{
        Type                = 'Packed'
        Enable              = $true
        Path                = "$PSScriptRoot\..\Artefacts\Packed"
        ModulesPath         = "$PSScriptRoot\..\Artefacts\Packed\Modules"
        RequiredModulesPath = "$PSScriptRoot\..\Artefacts\Packed\Modules"
        AddRequiredModules  = $true
        CopyFiles           = @{
            #"Examples\PublishingExample\Example-ExchangeEssentials.ps1" = "RunMe.ps1"
        }
        ArtefactName        = '<ModuleName>.v<ModuleVersion>.zip'
    }
    New-ConfigurationArtefact @newConfigurationArtefactSplat

    # global options for publishing to github/psgallery
    #New-ConfigurationPublish -Type PowerShellGallery -FilePath 'C:\Support\Important\PowerShellGalleryAPI.txt' -Enabled:$true
    #New-ConfigurationPublish -Type GitHub -FilePath 'C:\Support\Important\GitHubAPI.txt' -UserName 'EvotecIT' -Enabled:$true
}