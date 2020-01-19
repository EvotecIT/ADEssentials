function Set-WinADDiagnostics {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default')][alias('ForestName')][string] $Forest,
        [Parameter(ParameterSetName = 'Default')][string[]] $ExcludeDomains,
        [Parameter(ParameterSetName = 'Default')][string[]] $ExcludeDomainControllers,
        [Parameter(ParameterSetName = 'Default')][alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [Parameter(ParameterSetName = 'Default')][alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [Parameter(ParameterSetName = 'Default')][switch] $SkipRODC,
        [Parameter(ParameterSetName = 'Computer')][string[]] $ComputerName,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Computer')]
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

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Computer')]
        #[ValidateSet('None', 'Minimal', 'Basic', 'Extensive', 'Verbose', 'Internal')]
        [string] $Level
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
        'Knowledge Consistency Checker (KCC)' = '1 Knowledge Consistency Checker (KCC)'
        'Security Events'                     = '2 Security Events'
        'ExDS Interface Events'               = '3 ExDS Interface Events'
        'MAPI Interface Events'               = '4 MAPI Interface Events'
        'Replication Events'                  = '5 Replication Events'
        'Garbage Collection'                  = '6 Garbage Collection'
        'Internal Configuration'              = '7 Internal Configuration'
        'Directory Access'                    = '8 Directory Access'
        'Internal Processing'                 = '9 Internal Processing'
        'Performance Counters'                = '10 Performance Counters'
        'Initialization / Termination'        = '11 Initialization / Termination'
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

    if ($ComputerName) {
        [Array] $Computers = $ComputerName
    } else {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC
        [Array] $Computers = $ForestInformation.ForestDomainControllers.HostName
    }
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
                            Set-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -Type REG_DWORD -Key 'DbFlag' -Value 0 -ComputerName $Computer
                        } else {
                            # nltest /dbflag:0x0 # Disable
                            Write-Verbose "Set-WinADDiagnostics - Setting Netlogon Diagnostics to Disabled on $Computer"
                            Set-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -Type REG_DWORD -Key 'DbFlag' -Value 545325055 -ComputerName $Computer
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