function New-HTMLGroupDiagramSummaryHierarchical {
    <#
    .SYNOPSIS
    Creates an HTML group diagram summary in a hierarchical layout based on the provided Active Directory group information.

    .DESCRIPTION
    The New-HTMLGroupDiagramSummaryHierarchical function generates an HTML diagram summary representing the relationships between Active Directory groups and their members in a hierarchical structure. It allows customization of the diagram layout and appearance based on the input parameters.

    .PARAMETER ADGroup
    Specifies an array of Active Directory group objects to be included in the diagram.

    .PARAMETER HideAppliesTo
    Specifies whether to hide specific types of objects in the diagram. Valid values are 'Default', 'Hierarchical', and 'Both'.

    .PARAMETER HideComputers
    Indicates whether to hide computer objects in the diagram.

    .PARAMETER HideUsers
    Indicates whether to hide user objects in the diagram.

    .PARAMETER HideOther
    Indicates whether to hide other types of objects in the diagram.

    .PARAMETER Online
    Indicates whether to display online status information in the diagram.

    .EXAMPLE
    New-HTMLGroupDiagramSummaryHierarchical -ADGroup $ADGroupArray -HideAppliesTo 'Default' -HideComputers -Online
    Generates an HTML group diagram summary for the specified AD groups, hiding computers and displaying only default objects with online status in a hierarchical layout.

    #>
    [cmdletBinding()]
    param(
        [Array] $ADGroup,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [switch] $Online
    )
    New-HTMLDiagram -Height 'calc(100vh - 200px)' {
        New-DiagramOptionsLayout -HierarchicalEnabled $true #-HierarchicalDirection FromLeftToRight #-HierarchicalSortMethod directed
        New-DiagramOptionsPhysics -Enabled $true -HierarchicalRepulsionAvoidOverlap 1 -HierarchicalRepulsionNodeDistance 200
        #New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
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

                [int] $Level = $($ADObject.Nesting) + 1
                if ($ADObject.Type -eq 'User') {
                    if (-not $HideUsers -or $HideAppliesTo -notin 'Both', 'Hierarchical') {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageUser -Level $Level
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -Level $Level -IconSolid user -IconColor LightSteelBlue
                        }
                        New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Blue -ArrowsToEnabled -Dashes
                    }
                } elseif ($ADObject.Type -eq 'Group') {
                    if ($ADObject.Nesting -eq -1) {
                        $BorderColor = 'Red'
                        $Image = $Script:ConfigurationIcons.ImageGroup
                    } else {
                        $BorderColor = 'Blue'
                        $Image = $Script:ConfigurationIcons.ImageGroupNested
                    }
                    $SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                    $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine + $SummaryMembers
                    if ($Online) {
                        New-DiagramNode -Id $ID -Label $Label -Image $Image -Level $Level -ColorBorder $BorderColor
                    } else {
                        New-DiagramNode -Id $ID -Label $Label -Level $Level -IconSolid user-friends
                    }
                    New-DiagramLink -ColorOpacity 0.5 -From $ID -To $IDParent -Color Orange -ArrowsToEnabled
                } elseif ($ADObject.Type -eq 'Computer') {
                    if (-not $HideComputers -or $HideAppliesTo -notin 'Both', 'Hierarchical') {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageComputer -Level $Level
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -IconSolid desktop -IconColor LightGray -Level $Level
                        }
                        New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Arsenic -ArrowsToEnabled -Dashes
                    }
                } else {
                    if (-not $HideOther -or $HideAppliesTo -notin 'Both', 'Hierarchical') {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageOther -Level $Level
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -IconSolid robot -IconColor LightSalmon -Level $Level
                        }
                        New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Boulder -ArrowsToEnabled -Dashes
                    }
                }
            }
        }
    }
}