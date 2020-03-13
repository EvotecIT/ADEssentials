function Get-WinADDFSHealth {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [int] $EventDays = 1,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Today = (Get-Date)
    $Yesterday = (Get-Date -Hour 0 -Second 0 -Minute 0 -Millisecond 0).AddDays(-$EventDays)

    if (-not $ExtendedForestInformation) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC
    } else {
        $ForestInformation = $ExtendedForestInformation
    }
    #if (-not $Domains) {
    #    $Forest = Get-ADForest
    #    $Domains = $Forest.Domains
    #}
    [Array] $Table = foreach ($Domain in $ForestInformation.Domains) {
        Write-Verbose "Get-WinADDFSHealth - Processing $Domain"
        <#
        if (-not $DomainControllers) {
            $DomainControllersFull = Get-ADDomainController -Filter * -Server $Domain
        } else {
            $DomainControllersFull = foreach ($_ in $DomainControllers) {
                Get-ADDomainController -Identity $_ -Server $Domain
            }
        }
        #>
        $DomainControllersFull = $ForestInformation['DomainDomainControllers']["$Domain"]
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        try {
            [Array]$GPOs = @(Get-GPO -All -Domain $Domain -Server $QueryServer)
        } catch {
            $GPOs = $null
        }
        try {
            $CentralRepository = Get-ChildItem -Path "\\$Domain\SYSVOL\$Domain\policies\PolicyDefinitions" -ErrorAction Stop
            $CentralRepositoryDomain = if ($CentralRepository) { $true } else { $false }
        } catch {
            $CentralRepositoryDomain = $false
        }


        foreach ($DC in $DomainControllersFull) {
            Write-Verbose "Get-WinADDFSHealth - Processing $DC for $Domain"
            $DCName = $DC.Name
            $Hostname = $DC.Hostname
            $DN = $DC.DistinguishedName

            $LocalSettings = "CN=DFSR-LocalSettings,$DN"
            $Subscriber = "CN=Domain System Volume,$LocalSettings"
            $Subscription = "CN=SYSVOL Subscription,$Subscriber"

            $ReplicationStatus = @{
                '0' = 'Uninitialized'
                '1' = 'Initialized'
                '2' = 'Initial synchronization'
                '3' = 'Auto recovery'
                '4' = 'Normal'
                '5' = 'In error state'
                '6' = 'Disabled'
                '7' = 'Unknown'
            }

            $DomainSummary = [ordered] @{
                "DomainController"              = $DCName
                "Domain"                        = $Domain
                "Status"                        = $false
                "ReplicationState"              = 'Unknown'
                "IsPDC"                         = $DC.IsPDC
                'GroupPolicyOutput'             = $null -ne $GPOs # This shows whether output was on Get-GPO
                "GroupPolicyCount"              = if ($GPOs) { $GPOs.Count } else { 0 };
                "SYSVOLCount"                   = 0
                'CentralRepository'             = $CentralRepositoryDomain
                'CentralRepositoryDC'           = $false
                'IdenticalCount'                = $false
                "Availability"                  = $false
                "MemberReference"               = $false
                "DFSErrors"                     = 0
                "DFSEvents"                     = $null
                "DFSLocalSetting"               = $false
                "DomainSystemVolume"            = $false
                "SYSVOLSubscription"            = $false
                "StopReplicationOnAutoRecovery" = $false
            }

            <# NameSpace "root\microsoftdfs" Class 'dfsrreplicatedfolderinfo'
            CurrentConflictSizeInMb  : 0
            CurrentStageSizeInMb     : 0
            LastConflictCleanupTime  : 13.09.2019 07:59:38
            LastErrorCode            : 0
            LastErrorMessageId       : 0
            LastTombstoneCleanupTime : 13.09.2019 07:59:38
            MemberGuid               : A8930B63-1405-4E0B-AE43-840DAAC64DCE
            MemberName               : AD1
            ReplicatedFolderGuid     : 58836C0B-1AB9-49A9-BE64-57689A5A6350
            ReplicatedFolderName     : SYSVOL Share
            ReplicationGroupGuid     : 7DA3CD45-CF61-4D95-AB46-6DC859DD689B
            ReplicationGroupName     : Domain System Volume
            State                    : 2
            PSComputerName           : AD1
            #>
            $WarningVar = $null
            $DFSReplicatedFolderInfo = Get-CimData -NameSpace "root\microsoftdfs" -Class 'dfsrreplicatedfolderinfo' -ComputerName $Hostname -WarningAction SilentlyContinue -WarningVariable WarningVar
            if ($WarningVar) {
                $DomainSummary['ReplicationState'] = 'Unknown'
                #$DomainSummary['ReplicationState'] = $WarningVar -join ', '
            } else {
                $DomainSummary['ReplicationState'] = $ReplicationStatus["$($DFSReplicatedFolderInfo.State)"]
            }
            try {
                $CentralRepositoryDC = Get-ChildItem -Path "\\$Hostname\SYSVOL\$Domain\policies\PolicyDefinitions" -ErrorAction Stop
                $DomainSummary['CentralRepositoryDC'] = if ($CentralRepositoryDC) { $true } else { $false }
            } catch {
                $DomainSummary['CentralRepositoryDC'] = $false
            }
            try {
                $MemberReference = (Get-ADObject $Subscriber -Properties msDFSR-MemberReference -Server $QueryServer -ErrorAction Stop).'msDFSR-MemberReference' -like "CN=$DCName,*"
                $DomainSummary['MemberReference'] = if ($MemberReference) { $true } else { $false }
            } catch {
                $DomainSummary['MemberReference'] = $false
            }
            try {
                $DFSLocalSetting = Get-ADObject $LocalSettings -Server $QueryServer -ErrorAction Stop
                $DomainSummary['DFSLocalSetting'] = if ($DFSLocalSetting) { $true } else { $false }
            } catch {
                $DomainSummary['DFSLocalSetting'] = $false
            }

            try {
                $DomainSystemVolume = Get-ADObject $Subscriber -Server $QueryServer -ErrorAction Stop
                $DomainSummary['DomainSystemVolume'] = if ($DomainSystemVolume) { $true } else { $false }
            } catch {
                $DomainSummary['DomainSystemVolume'] = $false
            }
            try {
                $SysVolSubscription = Get-ADObject $Subscription -Server $QueryServer -ErrorAction Stop
                $DomainSummary['SYSVOLSubscription'] = if ($SysVolSubscription) { $true } else { $false }
            } catch {
                $DomainSummary['SYSVOLSubscription'] = $false
            }

            try {
                [Array] $SYSVOL = Get-ChildItem -Path "\\$Hostname\SYSVOL\$Domain\Policies" -Exclude "PolicyDefinitions*" -ErrorAction Stop
                $DomainSummary['SysvolCount'] = $SYSVOL.Count
            } catch {
                $DomainSummary['SysvolCount'] = 0
            }

            if (Test-Connection $Hostname -ErrorAction SilentlyContinue) {
                $DomainSummary['Availability'] = $true
            } else {
                $DomainSummary['Availability'] = $false
            }
            try {
                [Array] $Events = Get-Events -LogName "DFS Replication" -Level Error -ComputerName $Hostname -DateFrom $Yesterday -DateTo $Today
                $DomainSummary['DFSErrors'] = $Events.Count
                $DomainSummary['DFSEvents'] = $Events
            } catch {
                $DomainSummary['DFSErrors'] = $null
            }
            $DomainSummary['IdenticalCount'] = $DomainSummary['GroupPolicyCount'] -eq $DomainSummary['SYSVOLCount']

            try {
                $Registry = Get-PSRegistry -RegistryPath "HKLM\SYSTEM\CurrentControlSet\Services\DFSR\Parameters" -ComputerName $Hostname -ErrorAction Stop
            } catch {
                #$ErrorMessage = $_.Exception.Message
                $Registry = $null
            }
            if ($null -ne $Registry.StopReplicationOnAutoRecovery) {
                $DomainSummary['StopReplicationOnAutoRecovery'] = [bool] $Registry.StopReplicationOnAutoRecovery
            } else {
                $DomainSummary['StopReplicationOnAutoRecovery'] = $null
                # $DomainSummary['StopReplicationOnAutoRecovery'] = $ErrorMessage
            }

            $All = @(
                $DomainSummary['GroupPolicyOutput']
                $DomainSummary['SYSVOLSubscription']
                $DomainSummary['ReplicationState'] -eq 'Normal'
                $DomainSummary['DomainSystemVolume']
                $DomainSummary['DFSLocalSetting']
                $DomainSummary['MemberReference']
                $DomainSummary['Availability']
                $DomainSummary['IdenticalCount']
                $DomainSummary['DFSErrors'] -eq 0
            )
            $DomainSummary['Status'] = $All -notcontains $false
            [PSCustomObject] $DomainSummary
        }
    }
    $Table
}


#Get-WinADDFSHealth -Domains 'ad.evotec.xyz' #-DomainControllers 'ad3.ad.evotec.xyz' -EventDays 1


#$T.DFSEvents
<#
$EventDays = 2
$Today = (Get-Date)
$Yesterday = (Get-Date).AddDays(-$EventDays)

$Yesterday
$Today


Get-Events -LogName "DFS Replication" -Level Error -ComputerName 'ad1.ad.evotec.xyz' -DateFrom $Yesterday -DateTo $Today

#>
