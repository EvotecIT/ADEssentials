function Get-WinADGroupMember {
    <#
    .SYNOPSIS
    Get nested group membership from a given group or a number of groups.

    .DESCRIPTION
    Function enumerates members of a given AD group recursively along with Nesting level and parent group information. It also displays if each user account is enabled.

    .PARAMETER Group
    Parameter description

    .PARAMETER Nesting
    Internal use parameter. DO NOT USE

    .PARAMETER CollectedGroups
    Internal use parameter. DO NOT USE

    .PARAMETER Circular
    Internal use parameter. DO NOT USE

    .PARAMETER InitialGroupName
    Internal use parameter. DO NOT USE

    .PARAMETER Nested
    Internal use parameter. DO NOT USE

    .EXAMPLE
    Get-WinADGroupMember "Test Local Group" | Out-HtmlView -ScrollX -DisablePaging

    .EXAMPLE
    Get-ADGroup 'Test Local Group' | Get-WinADGroupMember | Format-Table *

    .EXAMPLE
    Get-WinADGroupMember -Group 'Test Local Group' | Format-Table *

    .EXAMPLE
    'GDS-TestGroup5' | Get-WinADGroupMember | Format-Table *

    .EXAMPLE
    'GDS-TestGroup5', 'Test Local Group' | Get-WinADGroupMember | Format-Table *

    .EXAMPLE
    Get-WinADGroupMember -Group 'Test Local Group', 'Domain Admins' | Format-Table

    .EXAMPLE
    Get-WinADGroupMember -Group 'Test Local Group' | Format-Table

    .NOTES

    #>
    param (
        [alias('GroupName')][Parameter(ValuefromPipeline, Mandatory)][Object[]] $Group,
        # All other parameters below are support parameters and shouldn't be used by users
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][string] $InitialGroupName,
        [Parameter(DontShow)][switch] $Nested
    )
    Process {
        foreach ($GroupName in $Group) {
            $Nesting++
            if (-not $Nested.IsPresent) {
                $InitialGroupName = $GroupName
                $CollectedGroups = [System.Collections.Generic.List[object]]::new()
            }
            $ADGroupName = Get-ADGroup $GroupName -Properties MemberOf, Members
            if ($ADGroupName) {
                if ($Circular) {
                    $NestedMembers = Get-ADGroupMember -Identity $GroupName
                    $NestedMembers = foreach ($Member in $NestedMembers) {
                        if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                            $Member
                        }
                    }
                    $Circular = $null
                } else {
                    $NestedMembers = Get-ADGroupMember -Identity $GroupName
                    if (-not $NestedMembers) {
                        if ($ADGroupName.Members) {
                            $NestedMembers = foreach ($Member in $ADGroupName.Members) {
                                Get-ADObject -Identity $Member
                            }
                        }

                    }
                }
                foreach ($NestedMember in $NestedMembers) {
                    $CreatedObject = [ordered] @{
                        GroupName      = $InitialGroupName
                        Type           = $NestedMember.objectclass
                        Name           = $NestedMember.name
                        SamAccountName = $NestedMember.SamAccountName
                        DisplayName    = $NestedMember.DisplayName
                        ParentGroup    = $ADGroupName.name
                        Enabled        = $null
                        Nesting        = $Nesting
                        DN             = $NestedMember.DistinguishedName
                        Circular       = $false
                    }
                    if ($NestedMember.objectclass -eq "user") {
                        $NestedADMember = Get-ADUser -Identity $NestedMember -Properties Enabled, DisplayName
                        $CreatedObject['Enabled'] = $NestedADMember.Enabled
                        $CreatedObject['Name'] = $NestedADMember.Name
                        $CreatedObject['DisplayName'] = $NestedADMember.DisplayName
                        [PSCustomObject] $CreatedObject
                    } elseif ($NestedMember.objectclass -eq "computer") {
                        $NestedADMember = Get-ADComputer -Identity $NestedMember -Properties Enabled, DisplayName
                        $CreatedObject['Enabled'] = $NestedADMember.Enabled
                        $CreatedObject['Name'] = $NestedADMember.Name
                        $CreatedObject['DisplayName'] = $NestedADMember.DisplayName
                        [PSCustomObject] $CreatedObject

                    } elseif ($NestedMember.objectclass -eq "group") {
                        if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                            $Circular = $ADGroupName.DistinguishedName
                            $CreatedObject['Circular'] = $true
                        }
                        [PSCustomObject] $CreatedObject
                        $CollectedGroups.Add($ADGroupName.DistinguishedName)
                        Get-WinADGroupMember -GroupName $NestedMember -Nesting $Nesting -Circular $Circular -InitialGroupName $InitialGroupName -CollectedGroups $CollectedGroups -Nested
                    } else {
                        [PSCustomObject] $CreatedObject
                    }
                }
            }
        }
    }
}

#Get-WinADGroupMember -Group 'Test Local Group', 'GDS-TestGroup5' | Format-Table *