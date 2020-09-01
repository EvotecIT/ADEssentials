function Show-WinADObjectMember {
    [alias('Show-ADObjectMember')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [string[]] $Identity,
        [string] $FilePath,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $RemoveAppliesTo = 'Both',
        [switch] $RemoveComputers,
        [switch] $RemoveUsers,
        [switch] $RemoveOther
        #[Parameter(ParameterSetName = 'Default')][switch] $Summary,
        #[Parameter(ParameterSetName = 'SummaryOnly')][switch] $SummaryOnly
    )
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    #$GroupsList = [System.Collections.Generic.List[object]]::new()
    New-HTML -TitleText "Visual Object MemberOf" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
        foreach ($ADObject in $Identity) {
            try {
                Write-Verbose "Show-WinADObjectMember - requesting $Identity member of property"
                $MyObject = Get-WinADObjectMember -Identity $ADObject -AddSelf
                # if ($Summary -or $SummaryOnly) {
                #     foreach ($Object in $MyObject) {
                #         $GroupsList.Add($Object)
                #    }
                # }
            } catch {
                Write-Warning "Show-WinADObjectMember - Error processing group $Group. Skipping. Needs investigation why it failed. Error: $($_.Exception.Message)"
                continue
            }
            if ($MyObject -and -not $SummaryOnly) {
                $ObjectName = $MyObject[0].ObjectName
                $DataStoreID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                $DataTableID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                New-HTMLTab -TabName $ObjectName {
                    New-HTMLTab -TabName 'Information' {
                        New-HTMLSection -Title "Information for $ObjectName" {
                            New-HTMLTable -DataTable $MyObject -Filtering -DataStoreID $DataStoreID {
                                New-TableHeader -Names Name, SamAccountName, DomainName, DisplayName -Title 'Member'
                                # New-TableHeader -Names DirectMembers, DirectGroups, IndirectMembers, TotalMembers -Title 'Statistics'
                                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $false -Name Enabled -Operator eq
                                New-TableCondition -BackgroundColor LightBlue -ComparisonType string -Value '' -Name ParentGroup -Operator eq -Row
                                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name CrossForest -Operator eq
                                New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name Circular -Operator eq
                            }
                        }
                    }
                    New-HTMLTab -TabName 'Diagram Basic' {
                        New-HTMLSection -Title "Diagram for $ObjectName" {
                            New-HTMLObjectDiagramDefault -Identity $MyObject -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther -DataTableID $DataTableID -ColumnID 1
                        }
                        #New-HTMLSection -Title "Group membership table $GroupName" {
                        #    New-HTMLTable -DataTable $ADGroup -Filtering -DataStoreID $DataStoreID -DataTableID $DataTableID
                        #}
                    }
                    New-HTMLTab -TabName 'Diagram Hierarchy' {
                        New-HTMLSection -Title "Diagram for $ObjectName" {
                            New-HTMLObjectDiagramHierachical -Identity $MyObject -RemoveAppliesTo $RemoveAppliesTo -RemoveUsers:$RemoveUsers -RemoveComputers:$RemoveComputeres -RemoveOther:$RemoveOther
                        }
                        #New-HTMLSection -Title "Group membership table $GroupName" {
                        #    New-HTMLTable -DataTable $ADGroup -Filtering -DataStoreID $DataStoreID
                        #}
                    }
                }
            }
        }
        <#
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
        #>
    } -Online -FilePath $FilePath -ShowHTML
}