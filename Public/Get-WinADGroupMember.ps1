function Get-WinADGroupMember {
    <#
    .SYNOPSIS
    Get nested group membership from a given group or a number of groups.

    .DESCRIPTION
    Function enumerates members of a given AD group recursively along with Nesting level and parent group information. It also displays if each user account is enabled.

    .PARAMETER Group
    Group Name as string or DistinguishedName or AD Group Object

    .PARAMETER Cache
    Gets all users, comptuers and groups before expanding group membership. Useful for multi group queries.

    .PARAMETER ClearCache
    Clears the cache. By default anything that is queried is saved into cache. If you want always fresh data use this parameter. Otherwise queries will be cached speeding up subsequent queries.

    .PARAMETER Native
    Use Get-ADGroupMember cmdlet instead of internal function.

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
        [switch] $Cache,
        [switch] $ClearCache,
        [switch] $Native,
        # All other parameters below are support parameters and shouldn't be used by users
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.Generic.List[object]] $CollectedGroups,
        [Parameter(DontShow)][System.Object] $Circular,
        [Parameter(DontShow)][string] $InitialGroupName,
        [Parameter(DontShow)][switch] $Nested
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
        if (-not $Native) {
            if (-not $Script:GlobalCatalog) {
                $Script:GlobalCatalog = (Get-ADDomainController -Discover -Service GlobalCatalog).HostName[0]
            }
            $AdditionalParameters = @{ Server = "$($Script:GlobalCatalog):3268" }
        } else {
            $AdditionalParameters = @{ }
        }
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
                $ADGroupName = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members @AdditionalParameters
                $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
            } elseif ($GroupName -is [Microsoft.ActiveDirectory.Management.ADPrincipal]) {
                if ($Script:WinADGroupMemberCache[$GroupName.DistinguishedName]) {
                    $ADGroupName = $Script:WinADGroupMemberCache[$GroupName.DistinguishedName]
                } else {
                    $ADGroupName = Get-ADGroup @AdditionalParameters -Identity $GroupName -Properties MemberOf, Members
                    $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
                }
            } else {
                # shouldn't happen, but maybe...
                $ADGroupName = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members @AdditionalParameters
                $Script:WinADGroupMemberCache[$ADGroupName.DistinguishedName] = $ADGroupName
            }
            if ($ADGroupName) {
                if ($Circular) {
                    if ($Native) {
                        $NestedMembers = Get-ADGroupMember -Identity $ADGroupName
                    } else {
                        $NestedMembers = foreach ($Identity in $ADGroupName.Members) {
                            if ($Script:WinADGroupMemberCache[$Identity]) {
                                $Script:WinADGroupMemberCache[$Identity]
                            } else {
                                $ADObject = Get-ADObject -Identity $Identity -Properties SamAccountName, DisplayName, Enabled, userAccountControl @AdditionalParameters
                                $ADObject.Enabled = (Convert-UAC -UAC $ADObject.userAccountControl) -notcontains 'ACCOUNTDISABLE'
                                $Script:WinADGroupMemberCache[$Identity] = $ADObject
                                $Script:WinADGroupMemberCache[$Identity]
                            }
                        }
                    }
                    $NestedMembers = foreach ($Member in $NestedMembers) {
                        if ($CollectedGroups -notcontains $Member.DistinguishedName) {
                            $Member
                        }
                    }
                    $Circular = $null
                } else {
                    # There is a bug Get-ADGroupMember: https://www.reddit.com/r/PowerShell/comments/6pocuu/getadgroupmember_issue/
                    # Or: https://stackoverflow.com/questions/58221736/powershell-5-1-16299-1146-get-adgroupmember-an-operations-error-occurred
                    <# It works on
                    Name                           Value
                    ----                           -----
                    PSVersion                      5.1.19041.1
                    PSEdition                      Desktop
                    PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
                    BuildVersion                   10.0.19041.1
                    CLRVersion                     4.0.30319.42000
                    WSManStackVersion              3.0
                    PSRemotingProtocolVersion      2.3
                    SerializationVersion           1.1.0.1
                    #>

                    <# It doesn't work
                    Name                           Value
                    ----                           -----
                    PSVersion                      5.1.14409.1018
                    PSEdition                      Desktop
                    PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
                    BuildVersion                   10.0.14409.1018
                    CLRVersion                     4.0.30319.42000
                    WSManStackVersion              3.0
                    PSRemotingProtocolVersion      2.3
                    SerializationVersion           1.1.0.1
                    #>
                    if ($Native) {
                        $NestedMembers = Get-ADGroupMember -Identity $ADGroupName
                    } else {
                        $NestedMembers = foreach ($Identity in $ADGroupName.Members) {
                            if ($Script:WinADGroupMemberCache[$Identity]) {
                                $Script:WinADGroupMemberCache[$Identity]
                            } else {
                                $ADObject = Get-ADObject -Identity $Identity -Properties SamAccountName, DisplayName, Enabled, userAccountControl @AdditionalParameters
                                $ADObject.Enabled = (Convert-UAC -UAC $ADObject.userAccountControl) -notcontains 'ACCOUNTDISABLE'
                                $Script:WinADGroupMemberCache[$Identity] = $ADObject
                                $Script:WinADGroupMemberCache[$Identity]
                            }
                        }
                    }
                }
                foreach ($NestedMember in $NestedMembers) {
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
                            $NestedADMember = Get-ADUser -Identity $NestedMember -Properties Enabled, DisplayName @AdditionalParameters
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
                            $NestedADMember = Get-ADComputer -Identity $NestedMember -Properties Enabled, DisplayName @AdditionalParameters
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

                        Get-WinADGroupMember -GroupName $NestedMember -Nesting $Nesting -Circular $Circular -InitialGroupName $InitialGroupName -CollectedGroups $CollectedGroups -Nested -Native:$Native.IsPresent
                    } else {
                        [PSCustomObject] $CreatedObject
                    }
                }
            }
        }
    }
}

#Get-WinADGroupMember -Group 'Test Local Group' -ClearCache -Native | Out-HtmlView -DisablePaging -ScrollX

#| Out-HtmlView -ScrollX -DisablePaging

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