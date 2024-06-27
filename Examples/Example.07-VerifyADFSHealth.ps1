Import-Module .\ADEssentials.psd1 -Force

# Option with autodetection
$T = Get-WinADDFSHealth -Verbose -Domains 'ad.evotec.xyz'
$T | Format-Table -AutoSize *

# Option without autodetection, with skip of gpo
$Output = Get-WinADDFSHealth -Verbose -Domains 'ad.evotec.xyz' -DomainControllers 'AD1.AD.EVOTEC.XYZ', 'AD2.AD.EVOTEC.XYZ' -SkipGPO:$true -SkipAutodetection
$Output | Format-Table -AutoSize *

<#
DomainController              : AD2
Domain                        : ad.evotec.xyz
Status                        : True
ReplicationState              : Normal
IsPDC                         : {}
GroupPolicyOutput             : False
GroupPolicyCount              : 0
SYSVOLCount                   : 0
CentralRepository             : True
CentralRepositoryDC           : True
IdenticalCount                : True
Availability                  : True
MemberReference               : True
DFSErrors                     : 0
DFSEvents                     :
DFSLocalSetting               : True
DomainSystemVolume            : True
SYSVOLSubscription            : True
StopReplicationOnAutoRecovery : False
DFSReplicatedFolderInfo       : @{PSShowComputerName=True; CurrentConflictSizeInMb=0; CurrentStageSizeInMb=15; LastConflictCleanupTime=09.09.2020 10:05:15; LastErrorC
                                ode=0; LastErrorMessageId=0; LastTombstoneCleanupTime=09.09.2020 10:05:15; MemberGuid=E01C6D44-2641-426E-923A-F5C7D9D90817; MemberName
                                =AD2; ReplicatedFolderGuid=58836C0B-1AB9-49A9-BE64-57689A5A6350; ReplicatedFolderName=SYSVOL Share; ReplicationGroupGuid=7DA3CD45-CF61
                                -4D95-AB46-6DC859DD689B; ReplicationGroupName=Domain System Volume; State=4; PSComputerName=AD2.ad.evotec.xyz}
#>