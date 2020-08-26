function Get-WinADGroupMember {
    [cmdletBinding()]
    param(
        [alias('GroupName', 'Identity')][Parameter(ValuefromPipeline, Mandatory)][Array] $Group,
        [switch] $All,
        [switch] $ClearCache,
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][string] $InitialGroupName,
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
    }
    Process {
        foreach ($GroupName in $Group) {
            # lets initialize our variables
            if (-not $Nested.IsPresent) {
                $InitialGroupName = $GroupName
                $CollectedGroups = [System.Collections.Generic.List[object]]::new()
                $Nesting = -1
            }
            $Nesting++
            # lets get our object
            $ADGroupName = Get-WinADObject -Identity $GroupName
            # Lets cache our object
            $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName

            if ($Circular) {
                $NestedMembers = foreach ($Identity in $ADGroupName.Members) {
                    if ($Script:WinADGroupMemberCache[$Identity]) {
                        $Script:WinADGroupMemberCache[$Identity]
                    } else {
                        $ADObject = Get-WinADObject -Identity $Identity # -Properties SamAccountName, DisplayName, Enabled, userAccountControl, ObjectSID
                        $Script:WinADGroupMemberCache[$Identity] = $ADObject
                        $Script:WinADGroupMemberCache[$Identity]
                    }
                }
                $NestedMembers = foreach ($Member in $NestedMembers) {
                    if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                        $Member
                    }
                }
                $Circular = $null
            } else {
                $NestedMembers = foreach ($Identity in $ADGroupName.Members) {
                    if ($Script:WinADGroupMemberCache[$Identity]) {
                        $Script:WinADGroupMemberCache[$Identity]
                    } else {
                        $ADObject = Get-WinADObject -Identity $Identity
                        $Script:WinADGroupMemberCache[$Identity] = $ADObject
                        $Script:WinADGroupMemberCache[$Identity]
                    }
                }
            }
        }
        $Output = foreach ($NestedMember in $NestedMembers) {
            if ($Members) {
                if ($NestedMember.ObjectClass -eq "group") {
                    if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                        $Circular = $ADGroupName.DistinguishedName
                        $CreatedObject['Circular'] = $true
                    }
                    $CollectedGroups.Add($ADGroupName.DistinguishedName)
                    Get-WinADGroupMember -GroupName $NestedMember -Nesting $Nesting -Circular $Circular -InitialGroupName $InitialGroupName -CollectedGroups $CollectedGroups -Nested -All:$All.IsPresent
                } else {
                    $NestedMember
                }
            } else {
                $DomainParentGroup = ConvertFrom-DistinguishedName -DistinguishedName $ADGroupName.DistinguishedName -ToDomainCN
                $CreatedObject = [ordered] @{
                    GroupName         = $InitialGroupName
                    Type              = $NestedMember.ObjectClass
                    Name              = $NestedMember.name
                    SamAccountName    = $NestedMember.SamAccountName
                    DomainName        = ConvertFrom-DistinguishedName -DistinguishedName $NestedMember.DistinguishedName -ToDomainCN
                    DisplayName       = $NestedMember.DisplayName
                    ParentGroup       = $ADGroupName.name
                    ParentGroupDomain = $DomainParentGroup
                    Enabled           = $NestedMember.Enabled
                    Nesting           = $Nesting
                    Circular          = $false
                    TrustedDomain     = $false
                    DistinguishedName = $NestedMember.DistinguishedName
                    Sid               = $NestedMember.ObjectSID
                }
                if ($NestedMember.ObjectClass -eq "group") {
                    if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                        $Circular = $ADGroupName.DistinguishedName
                        $CreatedObject['Circular'] = $true
                    }
                    if ($All) {
                        [PSCustomObject] $CreatedObject
                    }
                    $CollectedGroups.Add($ADGroupName.DistinguishedName)
                    Get-WinADGroupMember -GroupName $NestedMember -Nesting $Nesting -Circular $Circular -InitialGroupName $InitialGroupName -CollectedGroups $CollectedGroups -Nested -All:$All.IsPresent
                } else {
                    [PSCustomObject] $CreatedObject
                }
            }
        }
    }
    End {
        if (-not $All) {
            # this is standard way where we want to mimic -Recursive
            $Output | Sort-Object -Unique -Property DistinguishedName
        } else {
            $Output
        }
    }
}