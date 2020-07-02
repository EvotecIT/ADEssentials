function Get-WinADGroupMember {
    <#
    .SYNOPSIS
    Get nested group membership from a given group or a number of groups.

    .DESCRIPTION
    Function enumerates members of a given AD group recursively along with Nesting level and parent group information. It also displays if each user account is enabled.

    .PARAMETER Group
    Group Name as string or DistinguishedName or AD Group Object

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
        [Parameter(DontShow)][switch] $Nested,
        [switch] $Cache,
        [switch] $ClearCache
    )
    Begin {
        if (-not $Script:WinADGroupMemberCache -or $ClearCache) {
            $Script:WinADGroupMemberCache = @{}
            if ($Cache) {
                $ADObjects = @(
                    Get-ADGroup -Filter * -Properties MemberOf, Members
                    Get-ADComputer -Filter * -Properties Enabled, DisplayName
                    Get-ADUser -Filter * -Properties Enabled, DisplayName
                )
                foreach ($Object in $ADObjects) {
                    $Script:WinADGroupMemberCache[$Object.DistinguishedName] = $Object
                }
            }
        }
        #if (-not $Script:GlobalCatalog) {
        #    $Script:GlobalCatalog = (Get-ADDomainController -Discover -Service GlobalCatalog).HostName[0]
        #}
        # $PSDefaultParameterValues = @{
        #     "Get-ADObject:Server"   = "$($Script:GlobalCatalog):3268"
        #     "Get-ADUser:Server"     = "$($Script:GlobalCatalog):3268"
        #     "Get-ADComputer:Server" = "$($Script:GlobalCatalog):3268"
        #     "Get-ADGroup:Server"    = "$($Script:GlobalCatalog):3268"
        # }
    }
    Process {
        foreach ($GroupName in $Group) {
            if (-not $Nested.IsPresent) {
                $InitialGroupName = $GroupName
                $CollectedGroups = [System.Collections.Generic.List[object]]::new()
                $Nesting = -1
            }
            $Nesting++
            if ($GroupName -is [string]) {
                $ADGroupName = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members
                $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
            } elseif ($GroupName -is [Microsoft.ActiveDirectory.Management.ADPrincipal]) {
                if ($Script:WinADGroupMemberCache[$GroupName.DistinguishedName]) {
                    $ADGroupName = $Script:WinADGroupMemberCache[$GroupName.DistinguishedName]
                } else {
                    $ADGroupName = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members
                    $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
                }
            } else {
                # shouldn't happen, but maybe...
                $ADGroupName = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members
                $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
            }
            if ($ADGroupName) {
                if ($Circular) {
                    $NestedMembers = Get-ADGroupMember -Identity $ADGroupName
                    $NestedMembers = foreach ($Member in $NestedMembers) {
                        if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                            $Member
                        }
                    }
                    $Circular = $null
                } else {
                    $NestedMembers = Get-ADGroupMember -Identity $ADGroupName
                }
                foreach ($FoundMember in $NestedMembers) {
                    if ($FoundMember -is [string]) {
                        $NestedMember = Get-ADObject -Identity $FoundMember
                    } else {
                        $NestedMember = $FoundMember
                    }

                    $CreatedObject = [ordered] @{
                        GroupName         = $InitialGroupName
                        Type              = $NestedMember.objectclass
                        Name              = $NestedMember.name
                        SamAccountName    = $NestedMember.SamAccountName
                        DomainName        = ConvertFrom-DistinguishedName -DistinguishedName $NestedMember.DistinguishedName -ToDomainCN
                        DisplayName       = $NestedMember.DisplayName
                        ParentGroup       = $ADGroupName.name
                        Enabled           = $null
                        Nesting           = $Nesting
                        DistinguishedName = $NestedMember.DistinguishedName
                        Circular          = $false
                    }
                    <#
                    $CreatedObject = [ordered] @{
                        GroupName      = $InitialGroupName
                        Type           = $null
                        Name           = $null
                        SamAccountName = $null
                        DisplayName    = $null
                        ParentGroup    = $ADGroupName.name
                        Enabled        = $null
                        Nesting        = $Nesting
                        DistinguishedName             = $null
                        Circular       = $false
                    }
                    #>
                    if ($NestedMember.objectclass -eq "user") {
                        if ($Script:WinADGroupMemberCache[$NestedMember.DistinguishedName]) {
                            $NestedADMember = $Script:WinADGroupMemberCache[$NestedMember.DistinguishedName]
                        } else {
                            $NestedADMember = Get-ADUser -Identity $NestedMember -Properties Enabled, DisplayName
                            $Script:WinADGroupMemberCache[$NestedADMember.DistinguishedName] = $NestedADMember
                        }
                        #$CreatedObject['Type'] = $NestedADMember.objectclass
                        #$CreatedObject['Name'] = $NestedADMember.name
                        #$CreatedObject['SamAccountName'] = $NestedADMember.SamAccountName
                        #$CreatedObject['DisplayName'] = $NestedADMember.DisplayName
                        #$CreatedObject['DistinguishedName'] = $NestedADMember.DistinguishedName
                        $CreatedObject['Enabled'] = $NestedADMember.Enabled
                        $CreatedObject['Name'] = $NestedADMember.Name
                        $CreatedObject['DisplayName'] = $NestedADMember.DisplayName
                        [PSCustomObject] $CreatedObject
                    } elseif ($NestedMember.objectclass -eq "computer") {
                        if ($Script:WinADGroupMemberCache[$NestedMember.DistinguishedName]) {
                            $NestedADMember = $Script:WinADGroupMemberCache[$NestedMember.DistinguishedName]
                        } else {
                            $NestedADMember = Get-ADComputer -Identity $NestedMember -Properties Enabled, DisplayName
                            $Script:WinADGroupMemberCache[$NestedADMember.DistinguishedName] = $NestedADMember
                        }
                        #$CreatedObject['Type'] = $NestedADMember.objectclass
                        #$CreatedObject['Name'] = $NestedADMember.name
                        #$CreatedObject['SamAccountName'] = $NestedADMember.SamAccountName
                        #$CreatedObject['DisplayName'] = $NestedADMember.DisplayName
                        #$CreatedObject['DistinguishedName'] = $NestedADMember.DistinguishedName
                        $CreatedObject['Enabled'] = $NestedADMember.Enabled
                        $CreatedObject['Name'] = $NestedADMember.Name
                        $CreatedObject['DisplayName'] = $NestedADMember.DisplayName
                        [PSCustomObject] $CreatedObject

                    } elseif ($NestedMember.objectclass -eq "group") {
                        if ($ADGroupName.memberof -contains $NestedMember.DistinguishedName) {
                            $Circular = $ADGroupName.DistinguishedName
                            $CreatedObject['Circular'] = $true
                        }
                        #$CreatedObject['Type'] = $NestedMember.objectclass
                        #$CreatedObject['Name'] = $NestedMember.name
                        #$CreatedObject['SamAccountName'] = $NestedMember.SamAccountName
                        #$CreatedObject['DisplayName'] = $NestedMember.DisplayName
                        #$CreatedObject['DistinguishedName'] = $NestedMember.DistinguishedName
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


#    Get-WinADGroupMember -Group 'Test Local Group', 'GDS-TestGroup5' -Cache #| Format-Table

#Get-WinADGroupMember -Group 'Test Local Group', 'GDS-TestGroup5' -Cache | Out-HtmlView
#}

<# 'Test Local Group', 'GDS-TestGroup5'
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 2
Milliseconds      : 120
Ticks             : 21206866
TotalDays         : 2,45449837962963E-05
TotalHours        : 0,000589079611111111
TotalMinutes      : 0,0353447766666667
TotalSeconds      : 2,1206866
TotalMilliseconds : 2120,6866

Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 1
Milliseconds      : 442
Ticks             : 14425890
TotalDays         : 1,66966319444444E-05
TotalHours        : 0,000400719166666667
TotalMinutes      : 0,02404315
TotalSeconds      : 1,442589
TotalMilliseconds : 1442,589
#>

<# ITR01_AD Admins
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 3
Milliseconds      : 196
Ticks             : 31967993
TotalDays         : 3,69999918981481E-05
TotalHours        : 0,000887999805555556
TotalMinutes      : 0,0532799883333333
TotalSeconds      : 3,1967993
TotalMilliseconds : 3196,7993
#>

<# ITR01_AD Operators

Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 11
Milliseconds      : 639
Ticks             : 116397083
TotalDays         : 0,000134718846064815
TotalHours        : 0,00323325230555556
TotalMinutes      : 0,193995138333333
TotalSeconds      : 11,6397083
TotalMilliseconds : 11639,7083
#>