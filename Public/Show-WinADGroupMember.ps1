function Show-ADGroupMember {
    [alias('Show-WinADGroupMember')]
    [cmdletBinding()]
    param(
        [string[]] $GroupName,
        [string] $FilePath,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $Show = 'Both',
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $RemoveAppliesTo = 'Both',
        [switch] $RemoveComputers,
        [switch] $RemoveUsers,
        [switch] $RemoveOther
    )
    New-HTML -TitleText "Group Membership for $GroupName" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
        foreach ($Group in $GroupName) {
            try {
                $ADGroup = Get-WinADGroupMember -Group $Group -All -AddSelf -CountMembers
            } catch {
                Write-Warning "Show-GroupMember - Error processing group $Group. Skipping. Needs investigation why it failed."
                continue
            }
            if ($ADGroup) {
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
                        #New-HTMLSection -Title "Group membership table $GroupName" {
                        #    New-HTMLTable -DataTable $ADGroup -Filtering -DataStoreID $DataStoreID -DataTableID $DataTableID
                        #}
                    }
                    New-HTMLTab -TabName 'Diagram Hierarchy' {
                        New-HTMLSection -Title "Diagram for $GroupName" {
                            New-HTMLGroupDiagramHierachical -ADGroup $ADGroup -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther
                        }
                        #New-HTMLSection -Title "Group membership table $GroupName" {
                        #    New-HTMLTable -DataTable $ADGroup -Filtering -DataStoreID $DataStoreID
                        #}
                    }
                }
            }
        }
    } -Online -FilePath $FilePath -ShowHTML
}