function Get-WinADGroupMember {
    [cmdletBinding()]
    param(
        [alias('GroupName', 'Identity')][Parameter(ValuefromPipeline, Mandatory)][Array] $Group,
        [switch] $CountMembers,
        [switch] $AddSelf,
        [switch] $All,
        [switch] $ClearCache,
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][System.Collections.IDictionary] $InitialGroupName,
        [Parameter(DontShow)][switch] $Nested
    )
    Begin {
        if (-not $Script:WinADGroupMemberCache -or $ClearCache -or ($Cache -and -not $Script:WinADGroupMemberCacheGlobal)) {
            if ($ClearCache) {
                # This is to distinguish globally used cache and standard cache
                # As it's entirely possible user used standard approach without cache and then enabled cache so we need to track whether that is the case
                $Script:WinADGroupMemberCacheGlobal = $false
            }
            $Script:WinADGroupMemberCache = @{}
        }
        if ($Nesting -eq -1) {
            $MembersCache = [ordered] @{}
        }
    }
    Process {
        $Output = foreach ($GroupName in $Group) {
            # lets initialize our variables
            if (-not $Nested.IsPresent) {
                $InitialGroupName = [ordered] @{
                    GroupName         = $GroupName
                    Type              = 'group'
                    Name              = $null
                    SamAccountName    = $null
                    DomainName        = $null
                    DisplayName       = $null
                    Enabled           = $null
                    DirectMembers     = 0
                    DirectGroups      = 0
                    IndirectMembers   = 0
                    Nesting           = $Nesting
                    Circular          = $false
                    TrustedDomain     = $false
                    ParentGroup       = ''
                    ParentGroupDomain = ''
                    GroupDomainName   = $null
                    DistinguishedName = $null
                    Sid               = $null
                }
                $CollectedGroups = [System.Collections.Generic.List[string]]::new()
                #$Nesting = -1
            }
            $Nesting++
            # lets get our object
            $ADGroupName = Get-WinADObject -Identity $GroupName
            # we add DomainName to hashtable so we can easily find which group we're dealing with
            if (-not $Nested.IsPresent) {
                $InitialGroupName.GroupName = $ADGroupName.Name
                $InitialGroupName.DomainName = $ADGroupName.DomainName
                if ($AddSelf) {
                    # Since we want in final run add primary object to array we need to make sure we have it filled
                    $InitialGroupName.Name = $ADGroupName.Name
                    $InitialGroupName.SamAccountName = $ADGroupName.SamAccountName
                    $InitialGroupName.DisplayName = $ADGroupName.DisplayName
                    $InitialGroupName.GroupDomainName = $ADGroupName.DomainName
                    $InitialGroupName.DistinguishedName = $ADGroupName.DistinguishedName
                    $InitialGroupName.Sid = $ADGroupName.ObjectSID
                }
            }
            # Lets cache our object
            $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
            if ($Circular) {
                [Array] $NestedMembers = foreach ($Identity in $ADGroupName.Members) {
                    if ($Script:WinADGroupMemberCache[$Identity]) {
                        $Script:WinADGroupMemberCache[$Identity]
                    } else {
                        $ADObject = Get-WinADObject -Identity $Identity # -Properties SamAccountName, DisplayName, Enabled, userAccountControl, ObjectSID
                        $Script:WinADGroupMemberCache[$Identity] = $ADObject
                        $Script:WinADGroupMemberCache[$Identity]
                    }
                }
                [Array] $NestedMembers = foreach ($Member in $NestedMembers) {
                    if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                        $Member
                    }
                }
                $Circular = $null
            } else {
                [Array] $NestedMembers = foreach ($Identity in $ADGroupName.Members) {
                    if ($Script:WinADGroupMemberCache[$Identity]) {
                        $Script:WinADGroupMemberCache[$Identity]
                    } else {
                        $ADObject = Get-WinADObject -Identity $Identity
                        $Script:WinADGroupMemberCache[$Identity] = $ADObject
                        $Script:WinADGroupMemberCache[$Identity]
                    }
                }
            }

            if ($CountMembers) {
                # This tracks amount of members for our groups
                if (-not $MembersCache[$ADGroupName.DistinguishedName]) {
                    $DirectMembers = $NestedMembers.Where( { $_.ObjectClass -ne 'group' }, 'split')
                    $MembersCache[$ADGroupName.DistinguishedName] = [ordered] @{
                        InDirectMembers    = $null
                        DirectMembers      = $DirectMembers[0]
                        DirectMembersCount = ($DirectMembers[0]).Count
                        DirectGroups       = $DirectMembers[1]
                        DirectGroupsCount  = ($DirectMembers[1]).Count
                    }
                }
            }
            foreach ($NestedMember in $NestedMembers) {
                # for each member we either create new user or group, if group we will dive into nesting
                $DomainParentGroup = ConvertFrom-DistinguishedName -DistinguishedName $ADGroupName.DistinguishedName -ToDomainCN
                $CreatedObject = [ordered] @{
                    GroupName         = $InitialGroupName.GroupName
                    Type              = $NestedMember.ObjectClass
                    Name              = $NestedMember.name
                    SamAccountName    = $NestedMember.SamAccountName
                    DomainName        = $NestedMember.DomainName #ConvertFrom-DistinguishedName -DistinguishedName $NestedMember.DistinguishedName -ToDomainCN
                    DisplayName       = $NestedMember.DisplayName
                    Enabled           = $NestedMember.Enabled
                    DirectMembers     = 0
                    DirectGroups      = 0
                    IndirectMembers   = 0
                    #TotalMembers      = 0
                    Nesting           = $Nesting
                    Circular          = $false
                    TrustedDomain     = $false
                    ParentGroup       = $ADGroupName.name
                    ParentGroupDomain = $DomainParentGroup
                    GroupDomainName   = $InitialGroupName.DomainName
                    DistinguishedName = $NestedMember.DistinguishedName
                    Sid               = $NestedMember.ObjectSID
                }
                if ($NestedMember.ObjectClass -eq "group") {
                    if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                        $Circular = $ADGroupName.DistinguishedName
                        $CreatedObject['Circular'] = $true
                    }
                    $CollectedGroups.Add($ADGroupName.DistinguishedName)
                    $OutputFromGroup = Get-WinADGroupMember -GroupName $NestedMember -Nesting $Nesting -Circular $Circular -InitialGroupName $InitialGroupName -CollectedGroups $CollectedGroups -Nested -All:$All.IsPresent -CountMembers:$CountMembers.IsPresent
                    if ($All) {
                        [PSCustomObject] $CreatedObject
                    }
                    $OutputFromGroup
                } else {
                    [PSCustomObject] $CreatedObject
                }
            }
        }
    }
    End {
        if ($Nesting -eq 0) {
            # If nesting is 0 this means we are ending our run
            if (-not $All) {
                # If not ALL it means User wants to receive only users. Basically Get-ADGroupMember -Recursive
                $Output | Sort-Object -Unique -Property DistinguishedName
            } else {
                if ($AddSelf) {
                    $InitialGroupName.DirectMembers = $MembersCache[$InitialGroupName.DistinguishedName].DirectMembersCount
                    $InitialGroupName.DirectGroups = $MembersCache[$InitialGroupName.DistinguishedName].DirectGroupsCount
                    foreach ($Group in $MembersCache[$InitialGroupName.DistinguishedName].DirectGroups) {
                        $InitialGroupName.IndirectMembers = $MembersCache[$InitialGroupName.DistinguishedName].DirectMembersCount + $InitialGroupName.IndirectMembers
                    }
                    [PSCustomObject] $InitialGroupName
                }
                foreach ($Object in $Output) {
                    if ($Object.Type -eq 'group') {
                        # Object is a group, we  add direct members, direct groups and other stuff
                        $Object.DirectMembers = $MembersCache[$Object.DistinguishedName].DirectMembersCount
                        $Object.DirectGroups = $MembersCache[$Object.DistinguishedName].DirectGroupsCount
                        foreach ($Group in $MembersCache[$Object.DistinguishedName].DirectGroups) {
                            $Object.IndirectMembers = $MembersCache[$Group.DistinguishedName].DirectMembersCount + $Object.IndirectMembers
                        }
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