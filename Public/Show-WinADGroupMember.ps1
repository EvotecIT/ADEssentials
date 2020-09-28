function Show-WinADGroupMember {
    [alias('Show-ADGroupMember')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default', Position = 1)]
        [Parameter(ParameterSetName = 'SummaryOnly', Position = 1)]
        [Parameter(ParameterSetName = 'MemberInput', Position = 1)]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly', Position = 1)]
        [scriptblock] $Conditions,

        [Parameter(ParameterSetName = 'Default', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'SummaryOnly', Position = 0, Mandatory)]
        [alias('GroupName', 'Group')][string[]] $Identity,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [string] $FilePath,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [switch] $HideComputers,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [switch] $HideUsers,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [switch] $HideOther,

        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'Default')][switch] $Summary,

        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [Parameter(ParameterSetName = 'SummaryOnly')][switch] $SummaryOnly,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [switch] $Online,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [switch] $HideHTML,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'SummaryOnly')]
        [Parameter(ParameterSetName = 'MemberInput')]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly')]
        [switch] $DisableBuiltinConditions,

        [Parameter(ParameterSetName = 'MemberInput', Position = 0, Mandatory)]
        [Parameter(ParameterSetName = 'MemberInputSummaryOnly', Position = 0, Mandatory)]
        [System.Collections.IDictionary] $GroupMemberInput
    )
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    $GroupsList = [System.Collections.Generic.List[object]]::new()
    New-HTML -TitleText "Visual Group Membership" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        if ($GroupMemberInput) {
            [Arrqy] $Identity = $GroupMemberInput.Keys
        }
        foreach ($Group in $Identity) {
            try {
                Write-Verbose "Show-WinADGroupMember - requesting $Group group nested membership"
                if ($GroupMemberInput) {
                    $ADGroup = $GroupMemberInput[$Group]
                } else {
                    $ADGroup = Get-WinADGroupMember -Group $Group -All -AddSelf
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
                $DataStoreID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                $DataTableID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                New-HTMLTab -TabName $GroupName {
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