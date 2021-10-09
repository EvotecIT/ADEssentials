function Get-WinADGroupMember {
    <#
    .SYNOPSIS
    The Get-WinADGroupMember cmdlet gets the members of an Active Directory group. Members can be users, groups, and computers.

    .DESCRIPTION
    The Get-WinADGroupMember cmdlet gets the members of an Active Directory group. Members can be users, groups, and computers. The Identity parameter specifies the Active Directory group to access. You can identify a group by its distinguished name, GUID, security identifier, or Security Account Manager (SAM) account name. You can also specify the group by passing a group object through the pipeline. For example, you can use the Get-ADGroup cmdlet to get a group object and then pass the object through the pipeline to the Get-WinADGroupMember cmdlet.

    .PARAMETER Identity
    Specifies an Active Directory group object

    .PARAMETER AddSelf
    Adds details about initial group name to output

    .PARAMETER SelfOnly
    Returns only one object that's summary for the whole group

    .PARAMETER AdditionalStatistics
    Adds additional data to Self object (when AddSelf is used). This data is available always if SelfOnly is used. It includes count for NestingMax, NestingGroup, NestingGroupSecurity, NestingGroupDistribution. It allows for easy filtering where we expect security groups only when there are nested distribution groups.

    .PARAMETER All
    Adds details about groups, and their nesting. Without this parameter only unique users and computers are returned

    .EXAMPLE
    Get-WinADGroupMember -Identity 'EVOTECPL\Domain Admins' -All

    .EXAMPLE
    Get-WinADGroupMember -Group 'GDS-TestGroup9' -All -SelfOnly | Format-List *

    .EXAMPLE
    Get-WinADGroupMember -Group 'GDS-TestGroup9' | Format-Table *

    .EXAMPLE
    Get-WinADGroupMember -Group 'GDS-TestGroup9' -All -AddSelf | Format-Table *

    .EXAMPLE
    Get-WinADGroupMember -Group 'GDS-TestGroup9' -All -AddSelf -AdditionalStatistics | Format-Table *

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [alias('GroupName', 'Group')][Parameter(ValuefromPipeline, Mandatory)][Array] $Identity,
        #[switch] $CountMembers,
        [switch] $AddSelf,
        [switch] $All,
        [switch] $ClearCache,
        [switch] $AdditionalStatistics,
        [switch] $SelfOnly,
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][System.Collections.IDictionary] $InitialGroup,
        [Parameter(DontShow)][switch] $Nested
    )
    Begin {
        $Properties = 'GroupName', 'Name', 'SamAccountName', 'DisplayName', 'Enabled', 'Type', 'Nesting', 'CrossForest', 'ParentGroup', 'ParentGroupDomain', 'GroupDomainName', 'DistinguishedName', 'Sid'
        if (-not $Script:WinADGroupMemberCache -or $ClearCache) {
            #if ($ClearCache) {
            # This is to distinguish globally used cache and standard cache
            # As it's entirely possible user used standard approach without cache and then enabled cache so we need to track whether that is the case
            # $Script:WinADGroupMemberCacheGlobal = $false
            #}
            $Script:WinADGroupMemberCache = @{}
            $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $Script:WinADForestCache = @{
                Forest  = $Forest
                Domains = $Forest.Domains.Name
            }
        }
        if ($Nesting -eq -1) {
            $MembersCache = [ordered] @{}
        }
    }
    Process {
        [Array] $Output = foreach ($GroupName in $Identity) {
            # lets initialize our variables
            if (-not $Nested.IsPresent) {
                $InitialGroup = [ordered] @{
                    GroupName         = $GroupName
                    Name              = $null
                    SamAccountName    = $null
                    DomainName        = $null
                    DisplayName       = $null
                    Enabled           = $null
                    GroupType         = $null
                    GroupScope        = $null
                    Type              = 'group'
                    DirectMembers     = 0
                    DirectGroups      = 0
                    IndirectMembers   = 0
                    TotalMembers      = 0
                    Nesting           = $Nesting
                    CircularDirect    = $false
                    CircularIndirect  = $false
                    CrossForest       = $false
                    ParentGroup       = ''
                    ParentGroupDomain = ''
                    ParentGroupDN     = ''
                    GroupDomainName   = $null
                    DistinguishedName = $null
                    Sid               = $null
                }
                $CollectedGroups = [System.Collections.Generic.List[string]]::new()
                $Nesting = -1
            }
            $Nesting++
            # lets get our object
            $ADGroupName = Get-WinADObject -Identity $GroupName -IncludeGroupMembership
            if ($ADGroupName) {
                # we add DomainName to hashtable so we can easily find which group we're dealing with
                if (-not $Nested.IsPresent) {
                    $InitialGroup.GroupName = $ADGroupName.Name
                    $InitialGroup.DomainName = $ADGroupName.DomainName
                    if ($AddSelf -or $SelfOnly) {
                        # Since we want in final run add primary object to array we need to make sure we have it filled
                        $InitialGroup.Name = $ADGroupName.Name
                        $InitialGroup.SamAccountName = $ADGroupName.SamAccountName
                        $InitialGroup.DisplayName = $ADGroupName.DisplayName
                        $InitialGroup.GroupDomainName = $ADGroupName.DomainName
                        $InitialGroup.DistinguishedName = $ADGroupName.DistinguishedName
                        $InitialGroup.Sid = $ADGroupName.ObjectSID
                        $InitialGroup.GroupType = $ADGroupName.GroupType
                        $InitialGroup.GroupScope = $ADGroupName.GroupScope
                    }
                }
                # Lets cache our object
                $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
                if ($Circular -or $CollectedGroups -contains $ADGroupName.DistinguishedName) {
                    [Array] $NestedMembers = foreach ($MyIdentity in $ADGroupName.Members) {
                        if ($Script:WinADGroupMemberCache[$MyIdentity]) {
                            $Script:WinADGroupMemberCache[$MyIdentity]
                        } else {
                            $ADObject = Get-WinADObject -Identity $MyIdentity -IncludeGroupMembership # -Properties SamAccountName, DisplayName, Enabled, userAccountControl, ObjectSID
                            $Script:WinADGroupMemberCache[$MyIdentity] = $ADObject
                            $Script:WinADGroupMemberCache[$MyIdentity]
                        }
                    }
                    [Array] $NestedMembers = foreach ($Member in $NestedMembers) {
                        if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                            $Member
                        }
                    }
                    $Circular = $null
                } else {
                    [Array] $NestedMembers = foreach ($MyIdentity in $ADGroupName.Members) {
                        if ($Script:WinADGroupMemberCache[$MyIdentity]) {
                            $Script:WinADGroupMemberCache[$MyIdentity]
                        } else {
                            $ADObject = Get-WinADObject -Identity $MyIdentity -IncludeGroupMembership
                            $Script:WinADGroupMemberCache[$MyIdentity] = $ADObject
                            $Script:WinADGroupMemberCache[$MyIdentity]
                        }
                    }
                }

                #if ($CountMembers) {
                # This tracks amount of members for our groups
                if (-not $MembersCache[$ADGroupName.DistinguishedName]) {
                    $DirectMembers = $NestedMembers.Where( { $_.ObjectClass -ne 'group' }, 'split')
                    $MembersCache[$ADGroupName.DistinguishedName] = [ordered] @{
                        DirectMembers        = ($DirectMembers[0])
                        DirectMembersCount   = ($DirectMembers[0]).Count
                        DirectGroups         = ($DirectMembers[1])
                        DirectGroupsCount    = ($DirectMembers[1]).Count
                        IndirectMembers      = [System.Collections.Generic.List[PSCustomObject]]::new()
                        IndirectMembersCount = $null
                        IndirectGroups       = [System.Collections.Generic.List[PSCustomObject]]::new()
                        IndirectGroupsCount  = $null
                    }
                }
                #}
                $DomainParentGroup = ConvertFrom-DistinguishedName -DistinguishedName $ADGroupName.DistinguishedName -ToDomainCN
                foreach ($NestedMember in $NestedMembers) {
                    # for each member we either create new user or group, if group we will dive into nesting

                    $CreatedObject = [ordered] @{
                        GroupName         = $InitialGroup.GroupName
                        Name              = $NestedMember.name
                        SamAccountName    = $NestedMember.SamAccountName
                        DomainName        = $NestedMember.DomainName #ConvertFrom-DistinguishedName -DistinguishedName $NestedMember.DistinguishedName -ToDomainCN
                        DisplayName       = $NestedMember.DisplayName
                        Enabled           = $NestedMember.Enabled
                        GroupType         = $NestedMember.GroupType
                        GroupScope        = $NestedMember.GroupScope
                        Type              = $NestedMember.ObjectClass
                        DirectMembers     = 0
                        DirectGroups      = 0
                        IndirectMembers   = 0
                        TotalMembers      = 0
                        Nesting           = $Nesting
                        CircularDirect    = $false
                        CircularIndirect  = $false
                        CrossForest       = $false
                        ParentGroup       = $ADGroupName.name
                        ParentGroupDomain = $DomainParentGroup
                        ParentGroupDN     = $ADGroupName.DistinguishedName
                        GroupDomainName   = $InitialGroup.DomainName
                        DistinguishedName = $NestedMember.DistinguishedName
                        Sid               = $NestedMember.ObjectSID
                    }
                    if ($NestedMember.DomainName -notin $Script:WinADForestCache['Domains']) {
                        $CreatedObject['CrossForest'] = $true
                    }
                    if ($NestedMember.ObjectClass -eq "group") {

                        #if (-not $CircularGroups[$NestedMember.DistinguishedName]) {
                        #    $CircularGroups[$NestedMember.DistinguishedName] = $Nesting
                        #} else {
                        #    Write-Verbose "Shit... $($CircularGroups[$NestedMember.DistinguishedName])"
                        #}

                        if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                            $Circular = $ADGroupName.DistinguishedName
                            $CreatedObject['CircularDirect'] = $true
                        }

                        $CollectedGroups.Add($ADGroupName.DistinguishedName)

                        if ($CollectedGroups -contains $NestedMember.DistinguishedName) {
                            $CreatedObject['CircularIndirect'] = $true
                        }
                        if ($All) {
                            [PSCustomObject] $CreatedObject
                        }
                        Write-Verbose "Get-WinADGroupMember - Going into $($NestedMember.DistinguishedName) (Nesting: $Nesting) (Circular:$Circular)"
                        $OutputFromGroup = Get-WinADGroupMember -GroupName $NestedMember -Nesting $Nesting -Circular $Circular -InitialGroup $InitialGroup -CollectedGroups $CollectedGroups -Nested -All:$All.IsPresent #-CountMembers:$CountMembers.IsPresent
                        $OutputFromGroup
                        #if ($CountMembers) {
                        foreach ($Member in $OutputFromGroup) {
                            if ($Member.Type -eq 'group') {
                                $MembersCache[$ADGroupName.DistinguishedName]['IndirectGroups'].Add($Member)
                            } else {
                                $MembersCache[$ADGroupName.DistinguishedName]['IndirectMembers'].Add($Member)
                            }
                        }
                        #}
                    } else {
                        [PSCustomObject] $CreatedObject
                    }
                }
            }
        }
    }
    End {
        if ($Output.Count -gt 0) {
            if ($Nesting -eq 0) {
                # If nesting is 0 this means we are ending our run
                if (-not $All) {
                    # If not ALL it means User wants to receive only users. Basically Get-ADGroupMember -Recursive
                    $Output | Sort-Object -Unique -Property DistinguishedName | Select-Object -Property $Properties
                } else {
                    # User requested ALL
                    if ($AddSelf -or $SelfOnly) {
                        # User also wants summary object added
                        $InitialGroup.DirectMembers = $MembersCache[$InitialGroup.DistinguishedName].DirectMembersCount
                        $InitialGroup.DirectGroups = $MembersCache[$InitialGroup.DistinguishedName].DirectGroupsCount
                        foreach ($Group in $MembersCache[$InitialGroup.DistinguishedName].DirectGroups) {
                            $InitialGroup.IndirectMembers = $MembersCache[$Group.DistinguishedName].DirectMembersCount + $InitialGroup.IndirectMembers
                        }
                        # To get total memebers for given group we need to add all members from all groups + direct members of a group
                        $AllMembersForGivenGroup = @(
                            # Scan all groups for members
                            foreach ($DirectGroup in $MembersCache[$InitialGroup.DistinguishedName].DirectGroups) {
                                $MembersCache[$DirectGroup.DistinguishedName].DirectMembers
                            }
                            # Scan all direct members of this group
                            $MembersCache[$InitialGroup.DistinguishedName].DirectMembers
                            # Scan all indirect members of this group
                            $MembersCache[$InitialGroup.DistinguishedName].IndirectMembers
                        )
                        $InitialGroup['TotalMembers'] = @($AllMembersForGivenGroup | Sort-Object -Unique -Property DistinguishedName).Count

                        if ($AdditionalStatistics -or $SelfOnly) {
                            $InitialGroup['NestingMax'] = ($Output.Nesting | Sort-Object -Unique -Descending)[0]
                            $NestingObjectTypes = $Output.Where( { $_.Type -eq 'group' }, 'split')
                            $NestingGroupTypes = $NestingObjectTypes[0].Where( { $_.GroupType -eq 'Security' }, 'split')
                            #$InitialGroup['NestingOther'] = ($NestingObjectTypes[1]).Count
                            $InitialGroup['NestingGroup'] = ($NestingObjectTypes[0]).Count
                            $InitialGroup['NestingGroupSecurity'] = ($NestingGroupTypes[0]).Count
                            $InitialGroup['NestingGroupDistribution'] = ($NestingGroupTypes[1]).Count
                        }
                        # Finally returning object we just built
                        [PSCustomObject] $InitialGroup
                    }
                    if (-not $SelfOnly) {
                        foreach ($Object in $Output) {
                            if ($Object.Type -eq 'group') {
                                # Object is a group, we  add direct members, direct groups and other stuff
                                $Object.DirectMembers = $MembersCache[$Object.DistinguishedName].DirectMembersCount
                                $Object.DirectGroups = $MembersCache[$Object.DistinguishedName].DirectGroupsCount
                                foreach ($DirectGroup in $MembersCache[$Object.DistinguishedName].DirectGroups) {
                                    $Object.IndirectMembers = $MembersCache[$DirectGroup.DistinguishedName].DirectMembersCount + $Object.IndirectMembers
                                }
                                # To get total memebers for given group we need to add all members from all groups + direct members of a group
                                $AllMembersForGivenGroup = @(
                                    # Scan all groups for members
                                    foreach ($DirectGroup in $MembersCache[$Object.DistinguishedName].DirectGroups) {
                                        $MembersCache[$DirectGroup.DistinguishedName].DirectMembers
                                    }
                                    # Scan all direct members of this group
                                    $MembersCache[$Object.DistinguishedName].DirectMembers
                                    # Scan all indirect members of this group
                                    $MembersCache[$Object.DistinguishedName].IndirectMembers
                                )
                                $Object.TotalMembers = @($AllMembersForGivenGroup | Sort-Object -Unique -Property DistinguishedName).Count
                                # Finally returning object we just built
                                $Object
                            } else {
                                # Object is not a group we push it as is
                                $Object
                            }
                        }
                    }
                }
            } else {
                # this is nested call so we want to get whatever it gives us
                $Output
            }
        }
    }
}