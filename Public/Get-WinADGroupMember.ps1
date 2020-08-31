function Get-WinADGroupMember {
    [cmdletBinding()]
    param(
        [alias('GroupName', 'Group')][Parameter(ValuefromPipeline, Mandatory)][Array] $Identity,
        #[switch] $CountMembers,
        [switch] $AddSelf,
        [switch] $All,
        [switch] $ClearCache,
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][System.Collections.IDictionary] $InitialGroup,
        [Parameter(DontShow)][switch] $Nested
    )
    Begin {
        $Properties = 'GroupName', 'Name', 'SamAccountName', 'DisplayName', 'Enabled', 'Type', 'Nesting', 'Circular', 'CrossForest', 'ParentGroup', 'ParentGroupDomain', 'GroupDomainName', 'DistinguishedName', 'Sid'
        if (-not $Script:WinADGroupMemberCache -or $ClearCache -or ($Cache -and -not $Script:WinADGroupMemberCacheGlobal)) {
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
                    Type              = 'group'
                    DirectMembers     = 0
                    DirectGroups      = 0
                    IndirectMembers   = 0
                    TotalMembers      = 0
                    Nesting           = $Nesting
                    Circular          = $false
                    CrossForest       = $false
                    ParentGroup       = ''
                    ParentGroupDomain = ''
                    GroupDomainName   = $null
                    DistinguishedName = $null
                    Sid               = $null
                }
                $CollectedGroups = [System.Collections.Generic.List[string]]::new()
                $Nesting = -1
            }
            $Nesting++
            # lets get our object
            $ADGroupName = Get-WinADObject -Identity $GroupName
            if ($ADGroupName) {
                # we add DomainName to hashtable so we can easily find which group we're dealing with
                if (-not $Nested.IsPresent) {
                    $InitialGroup.GroupName = $ADGroupName.Name
                    $InitialGroup.DomainName = $ADGroupName.DomainName
                    if ($AddSelf) {
                        # Since we want in final run add primary object to array we need to make sure we have it filled
                        $InitialGroup.Name = $ADGroupName.Name
                        $InitialGroup.SamAccountName = $ADGroupName.SamAccountName
                        $InitialGroup.DisplayName = $ADGroupName.DisplayName
                        $InitialGroup.GroupDomainName = $ADGroupName.DomainName
                        $InitialGroup.DistinguishedName = $ADGroupName.DistinguishedName
                        $InitialGroup.Sid = $ADGroupName.ObjectSID
                    }
                }
                # Lets cache our object
                $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
                if ($Circular) {
                    [Array] $NestedMembers = foreach ($MyIdentity in $ADGroupName.Members) {
                        if ($Script:WinADGroupMemberCache[$MyIdentity]) {
                            $Script:WinADGroupMemberCache[$MyIdentity]
                        } else {
                            $ADObject = Get-WinADObject -Identity $MyIdentity # -Properties SamAccountName, DisplayName, Enabled, userAccountControl, ObjectSID
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
                            $ADObject = Get-WinADObject -Identity $MyIdentity
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
                foreach ($NestedMember in $NestedMembers) {
                    # for each member we either create new user or group, if group we will dive into nesting
                    $DomainParentGroup = ConvertFrom-DistinguishedName -DistinguishedName $ADGroupName.DistinguishedName -ToDomainCN
                    $CreatedObject = [ordered] @{
                        GroupName         = $InitialGroup.GroupName
                        Name              = $NestedMember.name
                        SamAccountName    = $NestedMember.SamAccountName
                        DomainName        = $NestedMember.DomainName #ConvertFrom-DistinguishedName -DistinguishedName $NestedMember.DistinguishedName -ToDomainCN
                        DisplayName       = $NestedMember.DisplayName
                        Enabled           = $NestedMember.Enabled
                        Type              = $NestedMember.ObjectClass
                        DirectMembers     = 0
                        DirectGroups      = 0
                        IndirectMembers   = 0
                        TotalMembers      = 0
                        Nesting           = $Nesting
                        Circular          = $false
                        CrossForest       = $false
                        ParentGroup       = $ADGroupName.name
                        ParentGroupDomain = $DomainParentGroup
                        GroupDomainName   = $InitialGroup.DomainName
                        DistinguishedName = $NestedMember.DistinguishedName
                        Sid               = $NestedMember.ObjectSID
                    }
                    if ($NestedMember.DomainName -notin $Script:WinADForestCache['Domains']) {
                        $CreatedObject['CrossForest'] = $true
                    }
                    if ($NestedMember.ObjectClass -eq "group") {
                        if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                            $Circular = $ADGroupName.DistinguishedName
                            $CreatedObject['Circular'] = $true
                        }
                        $CollectedGroups.Add($ADGroupName.DistinguishedName)
                        if ($All) {
                            [PSCustomObject] $CreatedObject
                        }
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
                    if ($AddSelf) {
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
                        $InitialGroup.TotalMembers = @($AllMembersForGivenGroup | Sort-Object -Unique -Property DistinguishedName).Count
                        # Finally returning object we just built
                        [PSCustomObject] $InitialGroup
                    }
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
            } else {
                # this is nested call so we want to get whatever it gives us
                $Output
            }
        }
    }
}