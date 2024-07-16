function New-HTMLGroupOfDiagramSummary {
    <#
    .SYNOPSIS
    Creates an HTML group diagram summary based on the provided Active Directory group information.

    .DESCRIPTION
    The New-HTMLGroupOfDiagramSummary function generates an HTML diagram summary representing the relationships between Active Directory groups and their members. It allows customization of the diagram layout and appearance based on the input parameters.

    .PARAMETER ADGroup
    Specifies an array of Active Directory group objects to be included in the diagram.

    .PARAMETER HideAppliesTo
    Specifies whether to hide specific types of objects in the diagram. Valid values are 'Default', 'Hierarchical', and 'Both'. Default value is 'Both'.

    .PARAMETER HideComputers
    Indicates whether to hide computer objects in the diagram.

    .PARAMETER HideUsers
    Indicates whether to hide user objects in the diagram.

    .PARAMETER HideOther
    Indicates whether to hide other types of objects in the diagram.

    .PARAMETER DataTableID
    Specifies the ID of the data table associated with the diagram.

    .PARAMETER ColumnID
    Specifies the ID of the column associated with the data table.

    .PARAMETER Online
    Indicates whether to display online status information in the diagram.

    .EXAMPLE
    New-HTMLGroupOfDiagramSummary -ADGroup $ADGroupArray -HideAppliesTo 'Default' -HideComputers -Online
    Generates an HTML group diagram summary for the specified AD groups, hiding computers and displaying only default objects with online status.

    .EXAMPLE
    New-HTMLGroupOfDiagramSummary -ADGroup $ADGroupArray -HideComputers -HideUsers -HideOther -DataTableID "DataTable1" -ColumnID 1 -Online
    Generates an HTML group diagram summary for the specified AD groups, hiding computers, users, and other objects, associating it with DataTable1, and displaying online status.

    #>
    [cmdletBinding()]
    param(
        [Array] $ADGroup,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [string] $DataTableID,
        [int] $ColumnID,
        [switch] $Online,
        [switch] $EnableDiagramFiltering,
        [switch] $EnableDiagramFilteringButton,
        [int] $DiagramFilteringMinimumCharacters = 3
    )
    $ConnectionsTracker = @{}
    New-HTMLDiagram -Height 'calc(100vh - 200px)' {
        #if ($DataTableID) {
        #    New-DiagramEvent -ID $DataTableID -ColumnID $ColumnID
        #}
        #New-DiagramOptionsLayout -HierarchicalEnabled $true -HierarchicalDirection FromLeftToRight #-HierarchicalSortMethod directed
        #New-DiagramOptionsPhysics -Enabled $true -HierarchicalRepulsionAvoidOverlap 1 -HierarchicalRepulsionNodeDistance 50
        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
        if ($ADGroup) {
            # Add it's members to diagram
            foreach ($ADObject in $ADGroup) {
                # Lets build our diagram
                # This diagram of Summary doesn't use level checking because it's a summary of a groups, and the level will be different per group
                # This means that it will look a bit different than what is there when comparing 1 to 1 with the other diagrams
                #[int] $Level = $($ADObject.Nesting) + 1
                $ID = "$($ADObject.DomainName)$($ADObject.DistinguishedName)"
                #[int] $LevelParent = $($ADObject.Nesting)
                $IDParent = "$($ADObject.ParentGroupDomain)$($ADObject.ParentGroupDN)"
                # We track connection for ID to make sure that only once the conenction is added
                if (-not $ConnectionsTracker[$ID]) {
                    $ConnectionsTracker[$ID] = @{}
                }
                if (-not $ConnectionsTracker[$ID][$IDParent]) {
                    if ($ADObject.Type -eq 'User') {
                        if (-not $HideUsers -or $HideAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            if ($Online) {
                                New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageUser
                            } else {
                                New-DiagramNode -Id $ID -Label $Label -IconSolid user -IconColor LightSteelBlue
                            }
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Blue -ArrowsFromEnabled -Dashes
                        }
                    } elseif ($ADObject.Type -eq 'Group') {
                        if ($ADObject.Nesting -eq -1) {
                            $BorderColor = 'Red'
                            $Image = $Script:ConfigurationIcons.ImageGroup
                        } else {
                            $BorderColor = 'Blue'
                            $Image = $Script:ConfigurationIcons.ImageGroupNested
                        }
                        #$SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine #+ $SummaryMembers
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Image -ColorBorder $BorderColor
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -IconSolid user-friends -IconColor VeryLightGrey
                        }
                        New-DiagramLink -ColorOpacity 0.5 -From $ID -To $IDParent -Color Orange -ArrowsFromEnabled
                    } elseif ($ADObject.Type -eq 'Computer') {
                        if (-not $HideComputers -or $HideAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            if ($Online) {
                                New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageComputer
                            } else {
                                New-DiagramNode -Id $ID -Label $Label -IconSolid desktop -IconColor LightGray
                            }
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Arsenic -ArrowsFromEnabled -Dashes
                        }
                    } else {
                        if (-not $HideOther -or $HideAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            if ($Online) {
                                New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageOther
                            } else {
                                New-DiagramNode -Id $ID -Label $Label -IconSolid robot -IconColor LightSalmon
                            }
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Boulder -ArrowsFromEnabled -Dashes
                        }
                    }
                    $ConnectionsTracker[$ID][$IDParent] = $true
                }
            }
        }
    } -EnableFiltering:$EnableDiagramFiltering.IsPresent -MinimumFilteringChars $DiagramFilteringMinimumCharacters -EnableFilteringButton:$EnableDiagramFilteringButton.IsPresent
}