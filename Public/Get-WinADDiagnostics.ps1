﻿function Get-WinADDiagnostics {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers, by default there are no exclusions, as long as VerifyDomainControllers switch is enabled. Otherwise this parameter is ignored.

    .PARAMETER IncludeDomainControllers
    Include only specific domain controllers, by default all domain controllers are included, as long as VerifyDomainControllers switch is enabled. Otherwise this parameter is ignored.

    .PARAMETER SkipRODC
    Skip Read-Only Domain Controllers. By default all domain controllers are included.

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
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
        '0' = 'None'
        '1' = 'Minimal'
        '2' = 'Basic'
        '3' = 'Extensive'
        '4' = 'Verbose'
        '5' = 'Internal'
        ''  = 'Unknown'
    }

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    [Array] $Computers = $ForestInformation.ForestDomainControllers.HostName

    foreach ($Computer in $Computers) {
        try {
            $Output = Get-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics' -ComputerName $Computer -Verbose:$false -ErrorAction Stop
        } catch {
            $ErrorMessage1 = $_.Exception.Message
            $Output = $null
        }
        try {
            $Output1 = Get-PSRegistry -RegistryPath 'HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'  -ComputerName $Computer -Verbose:$false -ErrorAction Stop
            if ($Output1.DbFlag -eq 545325055) {
                $Netlogon = $true
            } else {
                $Netlogon = $false
            }
        } catch {
            $ErrorMessage2 = $_.Exception.Message
            $Netlogon = 'Unknown'
        }


        if (-not $ErrorMessage1 -and -not $ErrorMessage2) {
            $Comment = 'OK'
            [PSCustomObject] @{
                'ComputerName'                        = $Computer
                'Knowledge Consistency Checker (KCC)' = $LevelsDictionary["$($Output.'1 Knowledge Consistency Checker')"]
                'Security Events'                     = $LevelsDictionary["$($Output.'2 Security Events')"]
                'ExDS Interface Events'               = $LevelsDictionary["$($Output.'3 ExDS Interface Events')"]
                'MAPI Interface Events'               = $LevelsDictionary["$($Output.'4 MAPI Interface Events')"]
                'Replication Events'                  = $LevelsDictionary["$($Output.'5 Replication Events')"]
                'Garbage Collection'                  = $LevelsDictionary["$($Output.'6 Garbage Collection')"]
                'Internal Configuration'              = $LevelsDictionary["$($Output.'7 Internal Configuration')"]
                'Directory Access'                    = $LevelsDictionary["$($Output.'8 Directory Access')"]
                'Internal Processing'                 = $LevelsDictionary["$($Output.'9 Internal Processing')"]
                'Performance Counters'                = $LevelsDictionary["$($Output.'10 Performance Counters')"]
                'Initialization / Termination'        = $LevelsDictionary["$($Output.'11 Initialization/Termination')"]
                'Service Control'                     = $LevelsDictionary["$($Output.'12 Service Control')"]
                'Name Resolution'                     = $LevelsDictionary["$($Output.'13 Name Resolution')"]
                'Backup'                              = $LevelsDictionary["$($Output.'14 Backup')"]
                'Field Engineering'                   = $LevelsDictionary["$($Output.'15 Field Engineering')"]
                'LDAP Interface Events'               = $LevelsDictionary["$($Output.'16 LDAP Interface Events')"]
                'Setup'                               = $LevelsDictionary["$($Output.'17 Setup')"]
                'Global Catalog'                      = $LevelsDictionary["$($Output.'18 Global Catalog')"]
                'Inter-site Messaging'                = $LevelsDictionary["$($Output.'19 Inter-site Messaging')"]
                'Group Caching'                       = $LevelsDictionary["$($Output.'20 Group Caching')"]
                'Linked-Value Replication'            = $LevelsDictionary["$($Output.'21 Linked-Value Replication')"]
                'DS RPC Client'                       = $LevelsDictionary["$($Output.'22 DS RPC Client')"]
                'DS RPC Server'                       = $LevelsDictionary["$($Output.'23 DS RPC Server')"]
                'DS Schema'                           = $LevelsDictionary["$($Output.'24 DS Schema')"]
                'Transformation Engine'               = $LevelsDictionary["$($Output.'25 Transformation Engine')"]
                'Claims-Based Access Control'         = $LevelsDictionary["$($Output.'26 Claims-Based Access Control')"]
                'Netlogon'                            = $Netlogon
                'Comment'                             = $Comment
            }
        } else {
            $Comment = $ErrorMessage1 + ' ' + $ErrorMessage2
            [PSCustomObject] @{
                'ComputerName'                        = $Computer
                'Knowledge Consistency Checker (KCC)' = $LevelsDictionary["$($Output.'1 Knowledge Consistency Checker')"]
                'Security Events'                     = $LevelsDictionary["$($Output.'2 Security Events')"]
                'ExDS Interface Events'               = $LevelsDictionary["$($Output.'3 ExDS Interface Events')"]
                'MAPI Interface Events'               = $LevelsDictionary["$($Output.'4 MAPI Interface Events')"]
                'Replication Events'                  = $LevelsDictionary["$($Output.'5 Replication Events')"]
                'Garbage Collection'                  = $LevelsDictionary["$($Output.'6 Garbage Collection')"]
                'Internal Configuration'              = $LevelsDictionary["$($Output.'7 Internal Configuration')"]
                'Directory Access'                    = $LevelsDictionary["$($Output.'8 Directory Access')"]
                'Internal Processing'                 = $LevelsDictionary["$($Output.'9 Internal Processing')"]
                'Performance Counters'                = $LevelsDictionary["$($Output.'10 Performance Counters')"]
                'Initialization / Termination'        = $LevelsDictionary["$($Output.'11 Initialization/Termination')"]
                'Service Control'                     = $LevelsDictionary["$($Output.'12 Service Control')"]
                'Name Resolution'                     = $LevelsDictionary["$($Output.'13 Name Resolution')"]
                'Backup'                              = $LevelsDictionary["$($Output.'14 Backup')"]
                'Field Engineering'                   = $LevelsDictionary["$($Output.'15 Field Engineering')"]
                'LDAP Interface Events'               = $LevelsDictionary["$($Output.'16 LDAP Interface Events')"]
                'Setup'                               = $LevelsDictionary["$($Output.'17 Setup')"]
                'Global Catalog'                      = $LevelsDictionary["$($Output.'18 Global Catalog')"]
                'Inter-site Messaging'                = $LevelsDictionary["$($Output.'19 Inter-site Messaging')"]
                'Group Caching'                       = $LevelsDictionary["$($Output.'20 Group Caching')"]
                'Linked-Value Replication'            = $LevelsDictionary["$($Output.'21 Linked-Value Replication')"]
                'DS RPC Client'                       = $LevelsDictionary["$($Output.'22 DS RPC Client')"]
                'DS RPC Server'                       = $LevelsDictionary["$($Output.'23 DS RPC Server')"]
                'DS Schema'                           = $LevelsDictionary["$($Output.'24 DS Schema')"]
                'Transformation Engine'               = $LevelsDictionary["$($Output.'25 Transformation Engine')"]
                'Claims-Based Access Control'         = $LevelsDictionary["$($Output.'26 Claims-Based Access Control')"]
                'Netlogon'                            = $Netlogon
                'Comment'                             = $Comment
            }
        }
    }
}