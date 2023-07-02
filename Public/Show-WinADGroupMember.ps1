﻿function Show-WinADGroupMember {
    <#
    .SYNOPSIS
    Command to gather nested group membership from one or more groups and display in table with two diagrams

    .DESCRIPTION
    Command to gather nested group membership from one or more groups and display in table with two diagrams
    This command will show data in table and diagrams in HTML format.

    .PARAMETER Identity
    Group Name or Names to search for

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
    Prevents HTML output from being displayed in browser after generation is done

    .PARAMETER DisableBuiltinConditions
    Disables table coloring allowing user to define it's own conditions

    .PARAMETER AdditionalStatistics
    Adds additional data to Self object. It includes count for NestingMax, NestingGroup, NestingGroupSecurity, NestingGroupDistribution. It allows for easy filtering where we expect security groups only when there are nested distribution groups.

    .PARAMETER SkipDiagram
    Skips diagram generation and only displays table. Useful if the diagram can't handle amount of data or if the diagrams are not nessecary.

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
        [switch] $SkipDiagram,
        [Parameter(ParameterSetName = 'Default')][switch] $Summary,
        [Parameter(ParameterSetName = 'SummaryOnly')][switch] $SummaryOnly
    )
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Show-WinADGroupMember' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    $VisualizeOnly = $false
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    $GroupsList = [System.Collections.Generic.List[object]]::new()
    if ($Identity.Count -gt 0) {
        New-HTML -TitleText "Visual Group Membership" {
            New-HTMLHeader {
                New-HTMLSection -Invisible {
                    New-HTMLSection {
                        New-HTMLText -Text "Report generated on $(Get-Date)" -Color Blue
                    } -JustifyContent flex-start -Invisible
                    New-HTMLSection {
                        New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                    } -JustifyContent flex-end -Invisible
                }
            }
            New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
            New-HTMLTableOption -DataStore JavaScript -BoolAsString
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
                if ($null -eq $Group) {
                    continue
                }
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
                Write-Verbose "Show-WinADGroupMember - processing HTML generation for $Group group"
                if (-not $SummaryOnly) {
                    if ($ADGroup) {
                        # Means group returned something
                        $GroupName = $ADGroup[0].GroupName
                        $NetBIOSName = Convert-DomainFqdnToNetBIOS -DomainName $ADGroup[0].DomainName
                        $FullName = "$NetBIOSName\$GroupName"
                    } else {
                        # Means group returned nothing, probably wrong request, but we still need to show something
                        $GroupName = $Group
                        $FullName = $Group
                    }
                    $DataStoreID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                    $DataTableID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                    New-HTMLTab -TabName $FullName {
                        Write-Verbose -Message "Show-WinADGroupMember - processing HTML generation for $Group group - Table"
                        $SectionInformation = New-HTMLSection -Title "Information for $GroupName" {
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
                        if (-not $SkipDiagram.IsPresent) {
                            New-HTMLTab -TabName 'Information' {
                                $SectionInformation
                            }
                        } else {
                            $SectionInformation
                        }
                        if (-not $SkipDiagram.IsPresent) {
                            Write-Verbose -Message "Show-WinADGroupMember - processing HTML generation for $Group group - Diagram"
                            New-HTMLTab -TabName 'Diagram Basic' {
                                New-HTMLSection -Title "Diagram for $GroupName" {
                                    New-HTMLGroupDiagramDefault -ADGroup $ADGroup -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -DataTableID $DataTableID -ColumnID 1 -Online:$Online
                                }
                            }
                            Write-Verbose -Message "Show-WinADGroupMember - processing HTML generation for $Group group - Diagram Hierarchy"
                            New-HTMLTab -TabName 'Diagram Hierarchy' {
                                New-HTMLSection -Title "Diagram for $GroupName" {
                                    New-HTMLGroupDiagramHierachical -ADGroup $ADGroup -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -Online:$Online
                                }
                            }
                        }
                    }
                }
            }
            if (-not $SkipDiagram.IsPresent -and ($Summary -or $SummaryOnly)) {
                Write-Verbose "Show-WinADGroupMember - processing HTML generation for Summary"
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
            Write-Verbose -Message "Show-WinADGroupMember - saving HTML report"
        } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
        Write-Verbose -Message "Show-WinADGroupMember - HTML report saved to $FilePath"
    } else {
        Write-Warning -Message "Show-WinADGroupMember - Error processing Identity, as it's empty."
    }
}