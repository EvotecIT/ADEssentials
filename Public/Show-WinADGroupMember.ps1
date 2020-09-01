function Show-WinADGroupMember {
    [alias('Show-ADGroupMember')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [parameter(Position = 0, Mandatory)][alias('GroupName', 'Group')][string[]] $Identity,
        [string] $FilePath,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $RemoveAppliesTo = 'Both',
        [switch] $RemoveComputers,
        [switch] $RemoveUsers,
        [switch] $RemoveOther,
        [Parameter(ParameterSetName = 'Default')][switch] $Summary,
        [Parameter(ParameterSetName = 'SummaryOnly')][switch] $SummaryOnly
    )
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    $GroupsList = [System.Collections.Generic.List[object]]::new()
    New-HTML -TitleText "Visual Group Membership" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
        foreach ($Group in $Identity) {
            try {
                Write-Verbose "Show-WinADGroupMember - requesting $Group group nested membership"
                $ADGroup = Get-WinADGroupMember -Group $Group -All -AddSelf
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
                                New-TableHeader -Names Name, SamAccountName, DomainName, DisplayName -Title 'Member'
                                New-TableHeader -Names DirectMembers, DirectGroups, IndirectMembers, TotalMembers -Title 'Statistics'
                                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $false -Name Enabled -Operator eq
                                New-TableCondition -BackgroundColor LightBlue -ComparisonType string -Value '' -Name ParentGroup -Operator eq -Row
                                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name CrossForest -Operator eq
                                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name Circular -Operator eq
                            }
                        }
                    }
                    New-HTMLTab -TabName 'Diagram Basic' {
                        New-HTMLSection -Title "Diagram for $GroupName" {
                            New-HTMLGroupDiagramDefault -ADGroup $ADGroup -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther -DataTableID $DataTableID -ColumnID 1
                        }
                    }
                    New-HTMLTab -TabName 'Diagram Hierarchy' {
                        New-HTMLSection -Title "Diagram for $GroupName" {
                            New-HTMLGroupDiagramHierachical -ADGroup $ADGroup -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther
                        }
                    }
                }
            }
        }
        if ($Summary -or $SummaryOnly) {
            New-HTMLTab -Name 'Summary' {
                New-HTMLTab -TabName 'Diagram Basic' {
                    New-HTMLSection -Title "Diagram for Summary" {
                        New-HTMLGroupDiagramSummary -ADGroup $GroupsList -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther -DataTableID $DataTableID -ColumnID 1
                    }
                }
                New-HTMLTab -TabName 'Diagram Hierarchy' {
                    New-HTMLSection -Title "Diagram for Summary" {
                        New-HTMLGroupDiagramSummaryHierarchical -ADGroup $GroupsList -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther
                    }
                }
            }
        }
    } -Online -FilePath $FilePath -ShowHTML
}