function Set-WinADDiagnostics {
    <#
    .SYNOPSIS
    Sets the diagnostics level for various Active Directory components on specified domain controllers.

    .DESCRIPTION
    This cmdlet sets the diagnostics level for various Active Directory components on specified domain controllers. It allows you to specify the forest name, domains, domain controllers, and diagnostics components to target. Additionally, it provides options to exclude certain domains and domain controllers, as well as skip read-only domain controllers.

    .PARAMETER Forest
    Specifies the name of the forest for which to set the diagnostics.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the operation.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controller names to exclude from the operation.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the operation.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controller names to include in the operation.

    .PARAMETER SkipRODC
    Specifies whether to skip read-only domain controllers.

    .PARAMETER Diagnostics
    Specifies an array of diagnostics components to set. Valid values include:
    - Knowledge Consistency Checker (KCC)
    - Security Events
    - ExDS Interface Events
    - MAPI Interface Events
    - Replication Events
    - Garbage Collection
    - Internal Configuration
    - Directory Access
    - Internal Processing
    - Performance Counters
    - Initialization / Termination
    - Service Control
    - Name Resolution
    - Backup
    - Field Engineering
    - LDAP Interface Events
    - Setup
    - Global Catalog
    - Inter-site Messaging
    - Group Caching
    - Linked-Value Replication
    - DS RPC Client
    - DS RPC Server
    - DS Schema
    - Transformation Engine
    - Claims-Based Access Control
    - Netlogon

    .PARAMETER Level
    Specifies the level of diagnostics to set. Valid values include:
    - None: Only critical events and error events are logged.
    - Minimal: Very high-level events are recorded.
    - Basic: More detailed information is recorded.
    - Extensive: Detailed information, including steps performed to complete tasks, is recorded.
    - Verbose: All events, including debug strings and configuration changes, are logged.
    - Internal: A complete log of the service is recorded.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest.

    .EXAMPLE
    Set-WinADDiagnostics -Forest 'example.local' -Diagnostics 'Security Events', 'Replication Events' -Level 'Basic'
    Sets the diagnostics level for Security Events and Replication Events to Basic on all domain controllers in the example.local forest.

    .EXAMPLE
    Set-WinADDiagnostics -Forest 'example.local' -IncludeDomainControllers 'dc1.example.local', 'dc2.example.local' -Diagnostics 'Netlogon' -Level 'Verbose'
    Sets the diagnostics level for Netlogon to Verbose on the specified domain controllers in the example.local forest.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [ValidateSet(
            'Knowledge Consistency Checker (KCC)',
            'Security Events',
            'ExDS Interface Events',
            'MAPI Interface Events',
            'Replication Events',
            'Garbage Collection',
            'Internal Configuration',
            'Directory Access',
            'Internal Processing',
            'Performance Counters',
            'Initialization / Termination',
            'Service Control',
            'Name Resolution',
            'Backup',
            'Field Engineering',
            'LDAP Interface Events',
            'Setup',
            'Global Catalog',
            'Inter-site Messaging',

            #New to Windows Server 2003:
            'Group Caching',
            'Linked-Value Replication',
            'DS RPC Client',
            'DS RPC Server',
            'DS Schema',

            #New to Windows Server 2012 and Windows 8:
            'Transformation Engine',
            'Claims-Based Access Control',
            # Added, but not setting in same place
            'Netlogon'
        )][string[]] $Diagnostics,
        #[ValidateSet('None', 'Minimal', 'Basic', 'Extensive', 'Verbose', 'Internal')]
        [string] $Level,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    <# Levels
    0 (None): Only critical events and error events are logged at this level. This is the default setting for all entries, and it should be modified only if a problem occurs that you want to investigate.
    1 (Minimal): Very high-level events are recorded in the event log at this setting. Events may include one message for each major task that is performed by the service. Use this setting to start an investigation when you do not know the location of the problem.
    2 (Basic)
    3 (Extensive): This level records more detailed information than the lower levels, such as steps that are performed to complete a task. Use this setting when you have narrowed the problem to a service or a group of categories.
    4 (Verbose)
    5 (Internal): This level logs all events, including debug strings and configuration changes. A complete log of the service is recorded. Use this setting when you have traced the problem to a particular category of a small set of categories.
    #>
    $LevelsDictionary = @{
        'None'      = 0
        'Minimal'   = 1
        'Basic'     = 2
        'Extensive' = 3
        'Verbose'   = 4
        'Internal'  = 5
    }
    $Type = @{
        'Knowledge Consistency Checker (KCC)' = '1 Knowledge Consistency Checker'
        'Security Events'                     = '2 Security Events'
        'ExDS Interface Events'               = '3 ExDS Interface Events'
        'MAPI Interface Events'               = '4 MAPI Interface Events'
        'Replication Events'                  = '5 Replication Events'
        'Garbage Collection'                  = '6 Garbage Collection'
        'Internal Configuration'              = '7 Internal Configuration'
        'Directory Access'                    = '8 Directory Access'
        'Internal Processing'                 = '9 Internal Processing'
        'Performance Counters'                = '10 Performance Counters'
        'Initialization / Termination'        = '11 Initialization/Termination'
        'Service Control'                     = '12 Service Control'
        'Name Resolution'                     = '13 Name Resolution'
        'Backup'                              = '14 Backup'
        'Field Engineering'                   = '15 Field Engineering'
        'LDAP Interface Events'               = '16 LDAP Interface Events'
        'Setup'                               = '17 Setup'
        'Global Catalog'                      = '18 Global Catalog'
        'Inter-site Messaging'                = '19 Inter-site Messaging'
        #New to Windows Server 2003: =        #New to Windows Server 2003:
        'Group Caching'                       = '20 Group Caching'
        'Linked-Value Replication'            = '21 Linked-Value Replication'
        'DS RPC Client'                       = '22 DS RPC Client'
        'DS RPC Server'                       = '23 DS RPC Server'
        'DS Schema'                           = '24 DS Schema'
        #New to Windows Server 2012 and Windows 8: =        #New to Windows Server 2012 and Windows 8:
        'Transformation Engine'               = '25 Transformation Engine'
        'Claims-Based Access Control'         = '26 Claims-Based Access Control'
    }
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    [Array] $Computers = $ForestInformation.ForestDomainControllers.HostName
    foreach ($Computer in $Computers) {
        foreach ($D in $Diagnostics) {
            if ($D) {
                $DiagnosticsType = $Type[$D]
                $DiagnosticsLevel = $LevelsDictionary[$Level]
                if ($null -ne $DiagnosticsType -and $null -ne $DiagnosticsLevel) {
                    Write-Verbose "Set-WinADDiagnostics - Setting $DiagnosticsType to $DiagnosticsLevel on $Computer"
                    Set-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics' -Type REG_DWORD -Key $DiagnosticsType -Value $DiagnosticsLevel -ComputerName $Computer
                } else {
                    if ($D -eq 'Netlogon') {
                        # https://support.microsoft.com/en-us/help/109626/enabling-debug-logging-for-the-netlogon-service
                        # Weirdly enough nltest sets it as REG_SZ and article above says REG_DWORD
                        if ($Level -eq 'None') {
                            # nltest /dbflag:0x2080ffff # Enable
                            Write-Verbose "Set-WinADDiagnostics - Setting Netlogon Diagnostics to Enabled on $Computer"
                            Set-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -Type REG_DWORD -Key 'DbFlag' -Value 0 -ComputerName $Computer -Verbose:$false
                        } else {
                            # nltest /dbflag:0x0 # Disable
                            Write-Verbose "Set-WinADDiagnostics - Setting Netlogon Diagnostics to Disabled on $Computer"
                            Set-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -Type REG_DWORD -Key 'DbFlag' -Value 545325055 -ComputerName $Computer -Verbose:$false
                        }
                        # Retart of NetLogon service is not required.
                    }
                }

            }
        }
    }
}

[scriptblock] $LevelAutoCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    @('None', 'Minimal', 'Basic', 'Extensive', 'Verbose', 'Internal')
}

Register-ArgumentCompleter -CommandName Set-WinADDiagnostics -ParameterName Level -ScriptBlock $LevelAutoCompleter