function Show-GroupMemberOther {
    [cmdletBinding()]
    param(
        [string[]] $GroupName,
        [string] $FilePath
    )
    #$Objects = [list]
    New-HTML -TitleText "Group Membership for $GroupName" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLSection -Height 800 -Title "Group membership diagram $GroupName" {
            New-HTMLDiagram -Height 800 {
                #New-DiagramOptionsLayout -RandomSeed 1000 -HierarchicalEnabled $true #-HierarchicalNodeSpacing 100 #-HierarchicalDirection FromUpToDown #-HierarchicalSortMethod directed
                New-DiagramOptionsPhysics -Enabled $false
                foreach ($Group in $GroupName) {
                    $ADGroup = Get-WinADGroupMember -Group $Group -All -AddSelf -CountMembers
                    if ($ADGroup) {

                        #New-DiagramEvent -ID 'GroupTableID' -ColumnID 1
                        # Add forest and it's domains to diagram
                        #New-DiagramNode -Id "Forest$($Forest.Name)" -Label $Forest.Name -Level 0
                        #foreach ($Domain in $Forest.Domains) {
                        # New-DiagramNode -Id $Domain -Label $Domain -To "Forest$($Forest.Name)" -Level 2
                        #}
                        # Lets get a group and all it's members
                        #foreach ($Group in $SummaryPermission | Where-Object { $_.Type -eq 'Group' -or $_.Type -eq 'Alias' } ) {

                        if ($ADGroup) {
                            # Add it's members to diagram
                            foreach ($ADObject in $ADGroup) {
                                # Lets build our
                                [int] $Level = $($ADObject.Nesting) + 1
                                $ID = "$($ADObject.DomainName)$($ADObject.Name)"
                                [int] $LevelParent = $($ADObject.Nesting)
                                $IDParent = "$($ADObject.ParentGroupDomain)$($ADObject.ParentGroup)"


                                [int] $Level = $($ADObject.Nesting) + 1
                                if ($ADObject.Type -eq 'User') {
                                    #if (-not $RemoveUsers) {
                                    #    $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                                    #    New-DiagramNode -Id $ID -Label $Label -To $IDParent -Image 'https://image.flaticon.com/icons/svg/3135/3135715.svg' -Level $Level
                                    #}
                                    # New-DiagramLink -From $ID -To $IDParent
                                } elseif ($ADObject.Type -eq 'Group') {
                                    $SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                                    #$SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                                    $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine + $SummaryMembers
                                    New-DiagramNode -Id $ID -Label $Label -To $IDParent -Image 'https://image.flaticon.com/icons/svg/166/166258.svg' -Level $Level


                                    New-DiagramLink -From $ID -To $IDParent
                                } elseif ($ADObject.Type -eq 'Computer') {
                                    if (-not $RemoveComputers) {
                                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                                        New-DiagramNode -Id $ID -Label $Label -To $IDParent -Image 'https://image.flaticon.com/icons/svg/3003/3003040.svg' -Level $Level
                                    }
                                    # New-DiagramLink -From $ID -To $IDParent
                                } else {
                                    #$Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                                    #New-DiagramNode -Id $ID -Label $Label -To $IDParent -Image 'https://image.flaticon.com/icons/svg/3003/3003040.svg' -Level $Level
                                }
                            }
                        }
                        #}
                    }
                }
            }
        }
        #New-HTMLSection -Title "Group membership table $GroupName" {
        #    New-HTMLTable -DataTable $ADGroup -Filtering -DataTableID 'GroupTableID'
        #}
    } -Online -FilePath $FilePath -ShowHTML
}

#Show-GroupMemberOther -GroupName 'Domain Admins', 'Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html #-RemoveUsers