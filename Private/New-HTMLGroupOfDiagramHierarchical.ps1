function New-HTMLGroupOfDiagramHierarchical {
    <#
    .SYNOPSIS
    Creates a new HTML group diagram with hierarchical layout and customizable options.

    .DESCRIPTION
    This function creates a new HTML group diagram with a hierarchical layout and customizable options. It allows for displaying Active Directory groups and their members in a visual diagram format with hierarchical organization.

    .PARAMETER Identity
    Specifies an array of objects to be included in the diagram.

    .PARAMETER HideAppliesTo
    Specifies whether to hide elements based on their type. Valid values are 'Default', 'Hierarchical', or 'Both'. Default is 'Both'.

    .PARAMETER HideComputers
    Indicates whether to hide computer objects in the diagram.

    .PARAMETER HideUsers
    Indicates whether to hide user objects in the diagram.

    .PARAMETER HideOther
    Indicates whether to hide other types of objects in the diagram.

    .PARAMETER Online
    Indicates whether to display objects as online in the diagram.

    .EXAMPLE
    New-HTMLGroupOfDiagramHierarchical -Identity $ADObjects -HideUsers -Online
    Creates a new HTML group diagram with hierarchical layout, includes Active Directory objects, hides user objects, and displays objects as online.

    .EXAMPLE
    New-HTMLGroupOfDiagramHierarchical -Identity $ADObjects -HideComputers -HideAppliesTo 'Hierarchical'
    Creates a new HTML group diagram with hierarchical layout, includes Active Directory objects, hides computer objects, and only displays elements based on the hierarchical setting.
    #>
    [cmdletBinding()]
    param(
        [Array] $Identity,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [switch] $Online,
        [switch] $EnableDiagramFiltering,
        [switch] $EnableDiagramFilteringButton,
        [int] $DiagramFilteringMinimumCharacters = 3
    )
    New-HTMLDiagram -Height 'calc(100vh - 200px)' {
        New-DiagramOptionsLayout -HierarchicalEnabled $true #-HierarchicalDirection FromLeftToRight #-HierarchicalSortMethod directed
        New-DiagramOptionsPhysics -Enabled $true -HierarchicalRepulsionAvoidOverlap 1 -HierarchicalRepulsionNodeDistance 200
        #New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
        if ($Identity) {
            # Add it's members to diagram
            foreach ($ADObject in $Identity) {
                # Lets build our diagram
                [int] $Level = $($ADObject.Nesting) + 1
                $ID = "$($ADObject.DomainName)$($ADObject.DistinguishedName)$Level"
                [int] $LevelParent = $($ADObject.Nesting)
                $IDParent = "$($ADObject.ParentGroupDomain)$($ADObject.ParentGroupDN)$LevelParent"

                [int] $Level = $($ADObject.Nesting) + 1
                if ($ADObject.Type -eq 'User') {
                    if (-not $HideUsers -or $HideAppliesTo -notin 'Both', 'Hierarchical') {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageUser -Level $Level
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -Level $Level -IconSolid user -IconColor LightSteelBlue
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
                    # $SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                    $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine # + $SummaryMembers
                    if ($Online) {
                        New-DiagramNode -Id $ID -Label $Label -Image $Image -Level $Level -ColorBorder $BorderColor
                    } else {
                        New-DiagramNode -Id $ID -Label $Label -Level $Level -IconSolid user-friends
                    }
                    New-DiagramLink -ColorOpacity 0.5 -From $ID -To $IDParent -Color Orange -ArrowsFromEnabled
                } elseif ($ADObject.Type -eq 'Computer') {
                    if (-not $HideComputers -or $HideAppliesTo -notin 'Both', 'Hierarchical') {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageComputer -Level $Level
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -IconSolid desktop -IconColor LightGray -Level $Level
                        }
                        New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Arsenic -ArrowsFromEnabled -Dashes
                    }
                } else {
                    if (-not $HideOther -or $HideAppliesTo -notin 'Both', 'Hierarchical') {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Script:ConfigurationIcons.ImageOther -Level $Level
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -IconSolid robot -IconColor LightSalmon -Level $Level
                        }
                        New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Boulder -ArrowsFromEnabled -Dashes
                    }
                }
            }
        }
    } -EnableFiltering:$EnableDiagramFiltering.IsPresent -MinimumFilteringChars $DiagramFilteringMinimumCharacters -EnableFilteringButton:$EnableDiagramFilteringButton.IsPresent
}