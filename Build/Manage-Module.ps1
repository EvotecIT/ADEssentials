Clear-Host
Import-Module "C:\Support\GitHub\PSPublishModule\PSPublishModule.psd1" -Force

$Configuration = @{
    Information = @{
        ModuleName        = 'ADEssentials'
        DirectoryProjects = 'C:\Support\GitHub'

        Manifest          = @{
            # Version number of this module.
            ModuleVersion              = '0.0.X'
            # Supported PSEditions
            CompatiblePSEditions       = @('Desktop', 'Core')
            # ID used to uniquely identify this module
            GUID                       = '9fc9fd61-7f11-4f4b-a527-084086f1905f'
            # Author of this module
            Author                     = 'Przemyslaw Klys'
            # Company or vendor of this module
            CompanyName                = 'Evotec'
            # Copyright statement for this module
            Copyright                  = "(c) 2011 - $((Get-Date).Year) Przemyslaw Klys @ Evotec. All rights reserved."
            # Description of the functionality provided by this module
            Description                = 'Helper module for Active Directory with lots of useful functions that simplify supporting Active Directory.'
            # Minimum version of the Windows PowerShell engine required by this module
            PowerShellVersion          = '5.1'
            # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
            # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
            Tags                       = @('Windows', 'ActiveDirectory')

            #IconUri              = 'https://evotec.xyz/wp-content/uploads/2018/10/PSSharedGoods-Alternative.png'

            ProjectUri                 = 'https://github.com/EvotecIT/ADEssentials'

            RequiredModules            = @(
                @{ ModuleName = 'PSEventViewer'; ModuleVersion = 'Latest'; Guid = '5df72a79-cdf6-4add-b38d-bcacf26fb7bc' }
                @{ ModuleName = 'PSSharedGoods'; ModuleVersion = 'Latest'; Guid = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe' }
                @{ ModuleName = 'PSWriteHTML'; ModuleVersion = 'Latest'; Guid = 'a7bdf640-f5cb-4acf-9de0-365b322d245c' }
            )
            ExternalModuleDependencies = @(
                #"DnsServer"
                #"DnsClient"
                #"CimCmdlets"
                #"NetTCPIP"
                #"Microsoft.PowerShell.Management"
                #"Microsoft.PowerShell.Security"
            )
            #InternalModuleDependencies = @(
            #"ActiveDirectory"
            #"GroupPolicy"
            #)
            CommandModuleDependencies  = @{
                ActiveDirectory = @(
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
                )
                DHCPServer      = @(
                    'Get-WinADDHCP'
                )
                DNSServer       = @(
                    'Get-WinDNSRecords'
                )
            }
        }
    }
    Options     = @{
        Merge             = @{
            Sort           = 'None'
            FormatCodePSM1 = @{
                Enabled           = $true
                RemoveComments    = $false
                FormatterSettings = @{
                    IncludeRules = @(
                        'PSPlaceOpenBrace',
                        'PSPlaceCloseBrace',
                        'PSUseConsistentWhitespace',
                        'PSUseConsistentIndentation',
                        'PSAlignAssignmentStatement',
                        'PSUseCorrectCasing'
                    )

                    Rules        = @{
                        PSPlaceOpenBrace           = @{
                            Enable             = $true
                            OnSameLine         = $true
                            NewLineAfter       = $true
                            IgnoreOneLineBlock = $true
                        }

                        PSPlaceCloseBrace          = @{
                            Enable             = $true
                            NewLineAfter       = $false
                            IgnoreOneLineBlock = $true
                            NoEmptyLineBefore  = $false
                        }

                        PSUseConsistentIndentation = @{
                            Enable              = $true
                            Kind                = 'space'
                            PipelineIndentation = 'IncreaseIndentationAfterEveryPipeline'
                            IndentationSize     = 4
                        }

                        PSUseConsistentWhitespace  = @{
                            Enable          = $true
                            CheckInnerBrace = $true
                            CheckOpenBrace  = $true
                            CheckOpenParen  = $true
                            CheckOperator   = $true
                            CheckPipe       = $true
                            CheckSeparator  = $true
                        }

                        PSAlignAssignmentStatement = @{
                            Enable         = $true
                            CheckHashtable = $true
                        }

                        PSUseCorrectCasing         = @{
                            Enable = $true
                        }
                    }
                }
            }
            FormatCodePSD1 = @{
                Enabled        = $true
                RemoveComments = $false
            }
            Integrate      = @{
                ApprovedModules = @('PSSharedGoods', 'PSWriteColor', 'Connectimo', 'PSUnifi', 'PSWebToolbox', 'PSMyPassword', 'PSPublishModule')
            }
        }
        Standard          = @{
            FormatCodePSM1 = @{

            }
            FormatCodePSD1 = @{
                Enabled = $true
                #RemoveComments = $true
            }
        }
        ImportModules     = @{
            Self            = $true
            RequiredModules = $false
            Verbose         = $false
        }
        PowerShellGallery = @{
            ApiKey   = 'C:\Support\Important\PowerShellGalleryAPI.txt'
            FromFile = $true
        }
        GitHub            = @{
            ApiKey   = 'C:\Support\Important\GithubAPI.txt'
            FromFile = $true
            UserName = 'EvotecIT'
            #RepositoryName = 'PSWriteHTML'
        }
        Documentation     = @{
            Path       = 'Docs'
            PathReadme = 'Docs\Readme.md'
        }
        Signing           = @{
            CertificateThumbprint = '36A8A2D0E227D81A2D3B60DCE0CFCF23BEFC343B'
        }
    }
    Steps       = @{
        BuildModule        = @{  # requires Enable to be on to process all of that
            Enable           = $true
            DeleteBefore     = $false
            Merge            = $true
            MergeMissing     = $true
            SignMerged       = $true
            Releases         = $true
            ReleasesUnpacked = $false
            RefreshPSD1Only  = $false
        }
        BuildDocumentation = @{
            Enable        = $false # enables documentation processing
            StartClean    = $true # always starts clean
            UpdateWhenNew = $true # always updates right after new
        }
        ImportModules      = @{
            Self            = $true
            RequiredModules = $false
            Verbose         = $false
        }
        PublishModule      = @{  # requires Enable to be on to process all of that
            Enabled      = $false
            Prerelease   = ''
            RequireForce = $false
            GitHub       = $false
        }
    }
}

New-PrepareModule -Configuration $Configuration