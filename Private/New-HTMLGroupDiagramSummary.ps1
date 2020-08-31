function New-HTMLGroupDiagramSummary {
    [cmdletBinding()]
    param(
        [Array] $ADGroup,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $RemoveAppliesTo = 'Both',
        [switch] $RemoveComputers,
        [switch] $RemoveUsers,
        [switch] $RemoveOther,
        [string] $DataTableID,
        [int] $ColumnID
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
                #[int] $Level = $($ADObject.Nesting) + 1
                $ID = "$($ADObject.DomainName)$($ADObject.Name)"
                #[int] $LevelParent = $($ADObject.Nesting)
                $IDParent = "$($ADObject.ParentGroupDomain)$($ADObject.ParentGroup)"
                # We track connection for ID to make sure that only once the conenction is added
                if (-not $ConnectionsTracker[$ID]) {
                    $ConnectionsTracker[$ID] = @{}
                }
                if (-not $ConnectionsTracker[$ID][$IDParent]) {
                    if ($ADObject.Type -eq 'User') {
                        if (-not $RemoveUsers -or $RemoveAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            New-DiagramNode -Id $ID -Label $Label -Image 'https://image.flaticon.com/icons/svg/3135/3135715.svg'
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Blue -ArrowsToEnabled -Dashes
                        }
                    } elseif ($ADObject.Type -eq 'Group') {
                        if ($ADObject.Nesting -eq -1) {
                            $BorderColor = 'Red'
                            $Image = 'https://image.flaticon.com/icons/svg/921/921347.svg'
                        } else {
                            $BorderColor = 'Blue'
                            $Image = 'https://image.flaticon.com/icons/svg/166/166258.svg'
                        }
                        $SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine + $SummaryMembers
                        New-DiagramNode -Id $ID -Label $Label -Image $Image -ArrowsToEnabled -ColorBorder $BorderColor
                        New-DiagramLink -ColorOpacity 0.5 -From $ID -To $IDParent -Color Orange -ArrowsToEnabled
                    } elseif ($ADObject.Type -eq 'Computer') {
                        if (-not $RemoveComputers -or $RemoveAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            New-DiagramNode -Id $ID -Label $Label -Image 'https://image.flaticon.com/icons/svg/3003/3003040.svg'
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Arsenic -ArrowsToEnabled -Dashes
                        }
                    } else {
                        if (-not $RemoveOther -or $RemoveAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            New-DiagramNode -Id $ID -Label $Label -Image 'https://image.flaticon.com/icons/svg/3347/3347551.svg'
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Boulder -ArrowsToEnabled -Dashes
                        }
                    }
                    $ConnectionsTracker[$ID][$IDParent] = $true
                }
            }
        }
    }
}