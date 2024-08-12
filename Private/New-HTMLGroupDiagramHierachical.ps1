function New-HTMLGroupDiagramHierachical {
    <#
    .SYNOPSIS
    Creates an HTML diagram representing Active Directory groups and their members in a hierarchical layout.

    .DESCRIPTION
    The New-HTMLGroupDiagramHierachical function generates an HTML diagram that visually represents Active Directory groups and their members in a hierarchical structure. The diagram includes nodes for users, groups, computers, and other objects, with customizable options for displaying and organizing the information.

    .PARAMETER ADGroup
    Specifies an array of Active Directory objects (groups) to be included in the diagram.

    .PARAMETER HideAppliesTo
    Specifies whether to hide specific types of objects in the diagram. Valid values are 'Default', 'Hierarchical', and 'Both'. Default value is 'Both'.

    .PARAMETER HideComputers
    Indicates whether to hide computer objects in the diagram.

    .PARAMETER HideUsers
    Indicates whether to hide user objects in the diagram.

    .PARAMETER HideOther
    Indicates whether to hide other types of objects in the diagram.

    .PARAMETER Online
    Indicates whether to display online status information in the diagram.

    .EXAMPLE
    New-HTMLGroupDiagramHierachical -ADGroup $ADGroupArray -HideAppliesTo 'Both' -Online
    Generates an HTML diagram displaying all objects in the $ADGroupArray with online status information included.

    .EXAMPLE
    New-HTMLGroupDiagramHierachical -ADGroup $ADGroupArray -HideComputers -HideUsers
    Generates an HTML diagram excluding computer and user objects from the $ADGroupArray.

    .NOTES
    File Name      : New-HTMLGroupDiagramHierachical.ps1
    Author         : Your Name
    Prerequisite   : PowerShell V5
    Copyright 2021 - Your Company
    #>

    [cmdletBinding()]
    param(
        [Array] $ADGroup,
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
        if ($ADGroup) {
            # Add it's members to diagram
            foreach ($ADObject in $ADGroup) {
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
                        New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Blue -ArrowsToEnabled -Dashes
                    }
                } elseif ($ADObject.Type -eq 'Group') {
                    if ($ADObject.Nesting -eq -1) {
                        $BorderColor = 'LightGreen'
                        $Image = $Script:ConfigurationIcons.ImageGroup
                        $IconSolid = 'user-friends'
                    } elseif ($ADObject.CircularIndirect -eq $true -or $ADObject.CircularDirect -eq $true) {
                        $Image = $Script:ConfigurationIcons.ImageGroupCircular
                        $BorderColor = 'PaleVioletRed'
                        $IconSolid = 'circle-notch'
                    } else {
                        $BorderColor = 'VeryLightGrey'
                        $Image = $Script:ConfigurationIcons.ImageGroupNested
                        $IconSolid = 'users'
                    }
                    $SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                    if ($ADObject.CircularIndirect -eq $true -or $ADObject.CircularDirect -eq $true) {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine + $SummaryMembers + [System.Environment]::NewLine + "Circular: $True"
                    } else {
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine + $SummaryMembers
                    }
                    if ($Online) {
                        New-DiagramNode -Id $ID -Label $Label -Image $Image -Level $Level -ColorBorder $BorderColor
                    } else {
                        New-DiagramNode -Id $ID -Label $Label -Level $Level -IconSolid $IconSolid -IconColor $BorderColor
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
    } -EnableFiltering:$EnableDiagramFiltering.IsPresent -MinimumFilteringChars $DiagramFilteringMinimumCharacters -EnableFilteringButton:$EnableDiagramFilteringButton.IsPresent
}