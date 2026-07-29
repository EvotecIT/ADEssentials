function Show-WinADGroupMemberOf {
    <#
    .SYNOPSIS
    Command to gather group membership that the user is member of displaying information in table and diagrams.

    .DESCRIPTION
    Command to gather group membership that the user is member of displaying information in table and diagrams.

    .PARAMETER Identity
    User or Computer object to get group membership for.

    .PARAMETER Conditions
    Provides ability to control look and feel of tables across HTML

    .PARAMETER FilePath
    Path to HTML file where it's saved. If not given temporary path is used

    .PARAMETER Summary
    Adds additional tab with all groups together on two diagrams

    .PARAMETER SummaryOnly
    Adds one tab with all groups together on two diagrams

    .PARAMETER Online
    Forces use of online CDN for JavaScript/CSS which makes the file smaller. Default - use offline.

    .PARAMETER HideHTML
    Prevents HTML output from being displayed in browser after generation is done

    .PARAMETER DisableBuiltinConditions
    Disables table coloring allowing user to define it's own conditions

    .PARAMETER SkipDiagram
    Skips diagram generation and only displays table. Useful if the diagram can't handle amount of data or if the diagrams are not nessecary.

    .PARAMETER EnableDiagramFiltering
    Enables search in diagrams. It's useful when there are many groups and it's hard to find the one you are looking for.

    .PARAMETER DiagramFilteringMinimumCharacters
    Minimum characters to start search in diagrams. Default is 3.

    .PARAMETER EnableDiagramFilteringButton
    Adds button to enable/disable filtering in diagrams. It's extension to EnableDiagramFiltering, when you prefer button over automatic filtering.

    .PARAMETER CustomIcons
    Dictionary of wildcard patterns matched against object names to override diagram node icons.
    Each key is a wildcard pattern (compared with -like) and each value is either a string with an image URL,
    or a dictionary with Image, or IconSolid/IconRegular/IconBrands (Font Awesome icon name) plus optional IconColor.
    The first matching pattern wins - provide an [ordered] dictionary to control precedence. Objects without a match keep default icons.
    Patterns use -like semantics, so a literal [ or ] in an object name must be escaped with a backtick in the pattern.
    URL-backed images still require network access when the generated report is opened; Font Awesome overrides are self-contained and the right choice for offline reports.

    .EXAMPLE
    Show-WinADGroupMemberOf -Identity 'przemyslaw.klys' -Verbose -Summary

    .EXAMPLE
    Show-WinADGroupMemberOf -Identity 'przemyslaw.klys', 'adm.pklys' -Summary

    .EXAMPLE
    Show-WinADGroupMemberOf -Identity 'adm.pklys' -Online -CustomIcons ([ordered] @{
        '*-RBAC-*'          = 'https://cdn-icons-png.flaticon.com/512/1687/1687242.png'
        'Enterprise Admins' = @{ IconSolid = 'user-shield'; IconColor = 'Red' }
    })

    .NOTES
    General notes
    #>
    [alias('Show-ADGroupMemberOf')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Position = 1)][scriptblock] $Conditions,
        [parameter(Position = 0, Mandatory)][string[]] $Identity,
        [string] $FilePath,
        [Parameter(ParameterSetName = 'Default')][switch] $Summary,
        [Parameter(ParameterSetName = 'SummaryOnly')][switch] $SummaryOnly,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $DisableBuiltinConditions,
        [switch] $SkipDiagram,
        [switch] $EnableDiagramFiltering,
        [switch] $EnableDiagramFilteringButton,
        [int] $DiagramFilteringMinimumCharacters = 3,
        [System.Collections.IDictionary] $CustomIcons
    )
    $HideAppliesTo = 'Both'
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Show-WinADGroupMemberOf' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    $GroupsList = [System.Collections.Generic.List[object]]::new()
    New-HTML -TitleText "Visual Object MemberOf" {
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
        foreach ($ADObject in $Identity) {
            if ($null -eq $ADObject) {
                continue
            }
            try {
                Write-Verbose "Show-WinADObjectMember - requesting $ADObject memberof property"
                $MyObject = Get-WinADGroupMemberOf -Identity $ADObject -AddSelf
                if ($Summary -or $SummaryOnly) {
                    foreach ($Object in $MyObject) {
                        $GroupsList.Add($Object)
                    }
                }
            } catch {
                Write-Warning "Show-WinADGroupMemberOf - Error processing group $Group. Skipping. Needs investigation why it failed. Error: $($_.Exception.Message)"
                continue
            }
            Write-Verbose -Message "Show-WinADGroupMemberOf - Processing HTML generation for $ADObject"
            if ($MyObject -and -not $SummaryOnly) {
                $ObjectName = $MyObject[0].ObjectName
                $DataStoreID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                $DataTableID = -join ('table', (Get-RandomStringName -Size 10 -ToLower))
                New-HTMLTab -TabName $ObjectName {
                    Write-Verbose -Message "Show-WinADGroupMemberOf - Processing HTML generation for $ObjectName - Table"
                    $DataSection = New-HTMLSection -Title "Information for $ObjectName" {
                        New-HTMLTable -DataTable $MyObject -Filtering -DataStoreID $DataStoreID {
                            if (-not $DisableBuiltinConditions) {
                                New-TableHeader -Names Name, SamAccountName, DomainName, DisplayName, Mail -Title 'Member'
                                New-TableHeader -Names GroupType, GroupScope -Title 'Group Details'
                                New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $false -Name Enabled -Operator eq
                                New-TableCondition -BackgroundColor LightBlue -ComparisonType string -Value '' -Name ParentGroup -Operator eq -Row
                                New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $true -Name CircularDirect -Operator eq -Row
                                New-TableCondition -BackgroundColor CoralRed -Color White -ComparisonType bool -Value $true -Name CircularIndirect -Operator eq -Row
                            }
                            if ($Conditions) {
                                & $Conditions
                            }
                        }
                    }
                    if ($SkipDiagram.IsPresent) {
                        $DataSection
                    } else {
                        New-HTMLTab -TabName 'Information' {
                            $DataSection
                        }
                        Write-Verbose -Message "Show-WinADGroupMemberOf - Processing HTML generation for $ObjectName - Diagram"
                        New-HTMLTab -TabName 'Diagram Basic' {
                            New-HTMLSection -Title "Diagram for $ObjectName" {
                                New-HTMLGroupOfDiagramDefault -Identity $MyObject -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -DataTableID $DataTableID -ColumnID 1 -Online:$Online -EnableDiagramFiltering:$EnableDiagramFiltering.IsPresent -DiagramFilteringMinimumCharacters $DiagramFilteringMinimumCharacters -EnableDiagramFilteringButton:$EnableDiagramFilteringButton.IsPresent -CustomIcons $CustomIcons
                            }
                        }
                        Write-Verbose -Message "Show-WinADGroupMemberOf - Processing HTML generation for $ObjectName - Diagram Hierarchy"
                        New-HTMLTab -TabName 'Diagram Hierarchy' {
                            New-HTMLSection -Title "Diagram for $ObjectName" {
                                New-HTMLGroupOfDiagramHierarchical -Identity $MyObject -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -Online:$Online -EnableDiagramFiltering:$EnableDiagramFiltering.IsPresent -DiagramFilteringMinimumCharacters $DiagramFilteringMinimumCharacters -EnableDiagramFilteringButton:$EnableDiagramFilteringButton.IsPresent -CustomIcons $CustomIcons
                            }
                        }
                    }
                }
            }
        }
        if (-not $SkipDiagram.IsPresent -and ($Summary -or $SummaryOnly)) {
            Write-Verbose -Message "Show-WinADGroupMemberOf - Processing HTML generation for Summary"
            New-HTMLTab -Name 'Summary' {
                New-HTMLTab -TabName 'Diagram Basic' {
                    New-HTMLSection -Title "Diagram for Summary" {
                        New-HTMLGroupOfDiagramSummary -ADGroup $GroupsList -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -DataTableID $DataTableID -ColumnID 1 -Online:$Online -EnableDiagramFiltering:$EnableDiagramFiltering.IsPresent -DiagramFilteringMinimumCharacters $DiagramFilteringMinimumCharacters -EnableDiagramFilteringButton:$EnableDiagramFilteringButton.IsPresent -CustomIcons $CustomIcons
                    }
                }
                New-HTMLTab -TabName 'Diagram Hierarchy' {
                    New-HTMLSection -Title "Diagram for Summary" {
                        New-HTMLGroupOfDiagramSummaryHierarchical -ADGroup $GroupsList -HideAppliesTo $HideAppliesTo -HideUsers:$HideUsers -HideComputers:$HideComputers -HideOther:$HideOther -Online:$Online -EnableDiagramFiltering:$EnableDiagramFiltering.IsPresent -DiagramFilteringMinimumCharacters $DiagramFilteringMinimumCharacters -EnableDiagramFilteringButton:$EnableDiagramFilteringButton.IsPresent -CustomIcons $CustomIcons
                    }
                }
            }
        }
        Write-Verbose -Message "Show-WinADGroupMemberOf - saving HTML report"
    } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
}