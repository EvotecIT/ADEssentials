function Show-WinADGroupMember {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Identity
    Group Name to search for

    .PARAMETER Conditions
    Provides ability to control look and feel of tables across HTML

    .PARAMETER FilePath
    Path to HTML file where it's saved. If not given temporary path is used

    .PARAMETER HideAppliesTo
    Allows to define to which diagram HideComputers,HideUsers,HideOther applies to

    .PARAMETER HideComputers
    Hide computers from diagrams - useful for performance reasons

    .PARAMETER HideUsers
    Hide users from diagrams - useful for performance reasons

    .PARAMETER HideOther
    Hide other objects from diagrams - useful for performance reasons

    .PARAMETER Online
    Forces use of online CDN for JavaScript/CSS which makes the file smaller. Default - use offline.

    .PARAMETER HideHTML
    Prevents HTML from opening up after command is done. Useful for automation

    .PARAMETER DisableBuiltinConditions
    Disables table coloring allowing user to define it's own conditions

    .PARAMETER AdditionalStatistics
    Adds additional data to Self object. It includes count for NestingMax, NestingGroup, NestingGroupSecurity, NestingGroupDistribution. It allows for easy filtering where we expect security groups only when there are nested distribution groups.

    .PARAMETER Summary
    Adds additional tab with all groups together on two diagrams

    .PARAMETER SummaryOnly
    Adds one tab with all groups together on two diagrams

    .EXAMPLE
   Show-WinADGroupMember -GroupName 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership1.html -Online -Verbose

   .EXAMPLE
   Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins' -FilePath $PSScriptRoot\Reports\GroupMembership2.html -Online -Verbose

   .EXAMPLE
   Show-WinADGroupMember -GroupName 'GDS-TestGroup4' -FilePath $PSScriptRoot\Reports\GroupMembership3.html -Summary -Online -Verbose

   .EXAMPLE
   Show-WinADGroupMember -GroupName 'Group1' -Verbose -Online

    .NOTES
    General notes
    #>
    [alias('Show-ADGroupMember')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Position = 0)][alias('GroupName', 'Group')][Array] $Identity,
        [Parameter(Position = 1)][scriptblock] $Conditions,
        [string] $FilePath,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $DisableBuiltinConditions,
        [switch] $AdditionalStatistics,
        [Parameter(ParameterSetName = 'Default')][switch] $Summary,
        [Parameter(ParameterSetName = 'SummaryOnly')][switch] $SummaryOnly
    )
    $VisualizeOnly = $false
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    $GroupsList = [System.Collections.Generic.List[object]]::new()
    New-HTML -TitleText "Visual Group Membership" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        if ($Identity[0].GroupName) {
            $GroupMembersCache = [ordered] @{}
            $VisualizeOnly = $true
            foreach ($Entry in $Identity) {
                $IdentityGroupName = "($($Entry.GroupName) / $($Entry.GroupDomainName))"
                if (-not $GroupMembersCache[$IdentityGroupName]) {
                    $GroupMembersCache[$IdentityGroupName] = [System.Collections.Generic.List[PSCustomObject]]::new()
                }
                $GroupMembersCache[$IdentityGroupName].Add($Entry)
            }
            [Array] $IdentityList = $GroupMembersCache.Keys
        } else {
            [Array] $IdentityList = $Identity
        }
        foreach ($Group in $IdentityList) {
            try {
                Write-Verbose "Show-WinADGroupMember - requesting $Group group nested membership"
                if ($VisualizeOnly) {
                    $ADGroup = $GroupMembersCache[$Group]
                } else {
                    $ADGroup = Get-WinADGroupMember -Group $Group -All -AddSelf -AdditionalStatistics:$AdditionalStatistics
                }
                if ($Summary -or $SummaryOnly) {
                    foreach ($Object in $ADGroup) {
                        $GroupsList.Add($Object)
                    }
                }
            } catch {
                Write-Warning "Show-WinADGroupMember - Error processing group $Group. Skipping. Needs investigation why it failed. Error: $($_.Exception.Message)"
                continue
            }
            if ($ADGroup -and -not $SummaryOnly) {
                $GroupName = $ADGroup[0].GroupName
                $NetBIOSName = Convert-DomainFqdnToNetBIOS -DomainName $ADGroup[0].DomainName
                $FullName = "$NetBIOSName\$GroupName"
                $DataStoreID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                $DataTableID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                New-HTMLTab -TabName $FullName {
                    New-HTMLTab -TabName 'Information' {
                        New-HTMLSection -Title "Information for $GroupName" {
                            New-HTMLTable -DataTable $ADGroup -Filtering -DataStoreID $DataStoreID {
                                if (-not $DisableBuiltinConditions) {
                                    New-TableHeader -Names Name, SamAccountName, DomainName, DisplayName -Title 'Member'
                                    New-TableHeader -Names DirectMembers, DirectGroups, IndirectMembers, TotalMembers -Title 'Statistics'
                                    New-TableHeader -Names GroupType, GroupScope -Title 'Group Details'
                                    New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $false -Name Enabled -Operator eq
                                    New-TableCondition -BackgroundColor LightBlue -ComparisonType string -Value '' -Name ParentGroup -Operator eq -Row
                                    New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $true -Name CrossForest -Operator eq
                                    New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $true -Name CircularIndirect -Operator eq -Row
                                    New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $true -Name CircularDirect -Operator eq -Row
                                }
                                if ($Conditions) {
                                    & $Conditions
                                }
                            }
                        }
                    }
                    New-HTMLTab -TabName 'Diagram Basic' {
                        New-HTMLSection -Title "Diagram for $GroupName" {
                            New-HTMLGroupDiagramDefault -ADGroup $ADGroup -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -DataTableID $DataTableID -ColumnID 1 -Online:$Online
                        }
                    }
                    New-HTMLTab -TabName 'Diagram Hierarchy' {
                        New-HTMLSection -Title "Diagram for $GroupName" {
                            New-HTMLGroupDiagramHierachical -ADGroup $ADGroup -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -Online:$Online
                        }
                    }
                }
            }
        }
        if ($Summary -or $SummaryOnly) {
            New-HTMLTab -Name 'Summary' {
                New-HTMLTab -TabName 'Diagram Basic' {
                    New-HTMLSection -Title "Diagram for Summary" {
                        New-HTMLGroupDiagramSummary -ADGroup $GroupsList -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -DataTableID $DataTableID -ColumnID 1 -Online:$Online
                    }
                }
                New-HTMLTab -TabName 'Diagram Hierarchy' {
                    New-HTMLSection -Title "Diagram for Summary" {
                        New-HTMLGroupDiagramSummaryHierarchical -ADGroup $GroupsList -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -Online:$Online
                    }
                }
            }
        }
    } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
}