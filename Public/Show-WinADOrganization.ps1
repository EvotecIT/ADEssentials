function Show-WinADOrganization {
    <#
    .SYNOPSIS
    Generates a detailed HTML report on the domains, containers, organizational units and their relationships within a specified Active Directory forest.

    .DESCRIPTION
    This cmdlet creates a comprehensive HTML report that includes a diagram of the domains, containers, organizational units and their relationships, as well as tables with detailed information about each component of the organizational structure.

    .PARAMETER Conditions
    Specifies the conditions to filter the organizational units and their relationships. This can be a script block that returns a boolean value.

    .PARAMETER FilePath
    The path to save the HTML report. If not specified, a temporary file is used.

    .PARAMETER HideHTML
    Hides the HTML report after generation. This is useful for generating reports without displaying them in a browser.

    .PARAMETER AddDiagramStandard
    Adds a standard diagram of the organizational units and their relationships to the report.
    It's important to understand that large environments may take a long time to generate the diagram if they even work.
    Test before using it in production.

    .PARAMETER AddDiagramHierarchical
    Adds a hierarchical diagram of the organizational units and their relationships to the report.
    It's important to understand that large environments may take a long time to generate the diagram if they even work.
    Test before using it in production.

    .PARAMETER Online
    Switch to indicate if the report should be generated with online resources.

    .EXAMPLE
    Show-WinADOrganization -FilePath "C:\Reports\AD Organization Report.html"

    .NOTES
    This cmdlet is useful for administrators to visualize and analyze the organizational structure within Active Directory.
    #>
    [cmdletBinding()]
    param(
        [ScriptBlock] $Conditions,
        [string] $FilePath,
        [switch] $HideHTML,
        [switch] $AddDiagramStandard,
        [switch] $AddDiagramHierarchical,
        [switch] $Online
    )

    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'


    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }

    $Organization = Get-WinADOrganization
    $Subnets = Get-WinADForestSubnet
    $Sites = Get-WinADForestSites

    New-HTML -TitleText "Visual Active Directory Organization" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString ", "
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

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

        if ($AddDiagramStandard -or $AddDiagramHierarchical) {
            New-HTMLTabPanel {
                if ($AddDiagramStandard) {
                    New-HTMLTab -TabName 'Standard' {
                        New-HTMLSection -HeaderText 'Organization Diagram' {
                            $Duplicates = [ordered] @{}
                            New-HTMLDiagram -Height 'calc(50vh)' {
                                New-DiagramEvent -ID 'DT-OrganizationalUnits' -ColumnID 2 New-DiagramNode -Label 'Active Directory Forest' -ID 'Forest' -Image 'https://cdn-icons-png.flaticon.com/512/6329/6329785.png' -ImageType squareImage
                                foreach ($Domain in $Organization.Domains) {
                                    New-DiagramNode -Label $Domain.Name -Id $Domain.DistinguishedName -Image 'https://cdn-icons-png.flaticon.com/512/6329/6329785.png' -ImageType squareImage
                                    New-DiagramEdge -From 'Forest' -To $Domain.DistinguishedName -Color Blue -ArrowsToEnabled -Dashes
                                }
                                # # Add Container nodes
                                # foreach ($Domain in $Organization.Containers.Keys) {
                                #     foreach ($Container in $Organization.Containers[$Domain]) {
                                #         New-DiagramNode -Id $Container.DistinguishedName -Label $Container.Name -Image 'https://cdn-icons-png.flaticon.com/512/4725/4725970.png' -ImageType squareImage
                                #         # Connect container to its domain
                                #         if ($Container.ParentContainers.Count -gt 0) {
                                #             $TopContainer = $Container.DistinguishedName
                                #             foreach ($Parent in $Container.ParentContainers) {
                                #                 if (-not $Duplicates[$TopContainer]) {
                                #                     New-DiagramEdge -From $TopContainer -To $Parent -Color Green -ArrowsToEnabled -Dashes
                                #                     $Duplicates[$TopContainer] = $true
                                #                 }
                                #                 $TopContainer = $Parent
                                #             }
                                #         }
                                #     }
                                # }
                                # Add OU nodes
                                foreach ($Domain in $Organization.OrganizationalUnits.Keys) {
                                    foreach ($OU in $Organization.OrganizationalUnits[$Domain]) {
                                        New-DiagramNode -Id $OU.DistinguishedName -Label $OU.Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png' -ImageType squareImage
                                        if ($OU.OrganizationalUnits.Count -gt 0) {
                                            $TopOU = $OU.DistinguishedName
                                            foreach ($Sub in $OU.OrganizationalUnits) {
                                                #$Name = ConvertFrom-DistinguishedName -DistinguishedName $Sub -ToLastName
                                                #New-DiagramNode -Id $Sub -Label $Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png'
                                                if (-not $Duplicates[$TopOU]) {
                                                    New-DiagramEdge -From $TopOU -To $Sub -Color Blue -ArrowsToEnabled -Dashes
                                                    $Duplicates[$TopOU] = $true
                                                }
                                                $TopOU = $Sub
                                            }
                                        }
                                    }
                                }
                            } -EnableFiltering -EnableFilteringButton
                        }
                    }
                }
                if ($AddDiagramHierarchical) {
                    New-HTMLTab -TabName 'Hierarchical' {
                        New-HTMLSection -HeaderText 'Organization Diagram' {
                            $Duplicates = [ordered] @{}
                            New-HTMLDiagram -Height 'calc(50vh)' {
                                #New-DiagramOptionsLayout -HierarchicalEnabled $true
                                New-DiagramEvent -ID 'DT-OrganizationalUnits' -ColumnID 2
                                #New-DiagramOptionsPhysics -RepulsionNodeDistance 200 -Solver repulsion
                                #New-DiagramOptionsPhysics -Enabled $true -HierarchicalRepulsionAvoidOverlap 1.00
                                New-DiagramOptionsLayout -ImprovedLayout $true -HierarchicalEnabled $true -HierarchicalDirection FromUpToDown -HierarchicalNodeSpacing 280 #-HierarchicalSortMethod directed -HierarchicalShakeTowards leaves
                                New-DiagramOptionsPhysics -Enabled $false New-DiagramNode -Label 'Active Directory Forest' -Id 'Forest' -Image 'https://cdn-icons-png.flaticon.com/512/6329/6329785.png' -Leve 0 -ImageType squareImage
                                foreach ($Domain in $Organization.Domains) {
                                    New-DiagramNode -Label $Domain.Name -Id $Domain.DistinguishedName -Image 'https://cdn-icons-png.flaticon.com/512/6329/6329785.png' -Level 1 -ImageType squareImage
                                    New-DiagramEdge -From 'Forest' -To $Domain.DistinguishedName -Color Blue -ArrowsToEnabled -Dashes
                                }
                                # # Add Container nodes with appropriate level
                                # foreach ($Domain in $Organization.Containers.Keys) {
                                #     foreach ($Container in $Organization.Containers[$Domain]) {
                                #         New-DiagramNode -Id $Container.DistinguishedName -Label $Container.Name -Image 'https://cdn-icons-png.flaticon.com/512/4725/4725970.png' -Level ($Container.ParentContainersCount + 2) -ImageType squareImage
                                #         if ($Container.ParentContainers.Count -gt 0) {
                                #             $TopContainer = $Container.DistinguishedName
                                #             foreach ($Parent in $Container.ParentContainers) {
                                #                 if (-not $Duplicates[$TopContainer]) {
                                #                     $newDiagramEdgeSplat = @{
                                #                         From            = $TopContainer
                                #                         To              = $Parent
                                #                         Color           = 'Green'
                                #                         ArrowsToEnabled = $true
                                #                         Dashes          = $true
                                #                         ColorOpacity    = 0.7
                                #                     }
                                #                     New-DiagramEdge @newDiagramEdgeSplat
                                #                     $Duplicates[$TopContainer] = $true
                                #                 }
                                #                 $TopContainer = $Parent
                                #             }
                                #         }
                                #     }
                                # }
                                # Add OU nodes
                                foreach ($Domain in $Organization.OrganizationalUnits.Keys) {
                                    foreach ($OU in $Organization.OrganizationalUnits[$Domain]) {
                                        New-DiagramNode -Id $OU.DistinguishedName -Label $OU.Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png' -Level ($OU.OrganizationalUnitsCount + 2) -ImageType squareImage
                                        if ($OU.OrganizationalUnits.Count -gt 0) {
                                            $TopOU = $OU.DistinguishedName
                                            foreach ($Sub in $OU.OrganizationalUnits) {
                                                #$Name = ConvertFrom-DistinguishedName -DistinguishedName $Sub -ToLastName
                                                #New-DiagramNode -Id $Sub -Label $Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png'
                                                if (-not $Duplicates[$TopOU]) {
                                                    $newDiagramEdgeSplat = @{
                                                        From            = $TopOU
                                                        To              = $Sub
                                                        Color           = 'Blue'
                                                        ArrowsToEnabled = $true
                                                        Dashes          = $true
                                                        ColorOpacity    = 0.7
                                                    }

                                                    New-DiagramEdge @newDiagramEdgeSplat
                                                    $Duplicates[$TopOU] = $true
                                                }
                                                $TopOU = $Sub
                                            }
                                        }
                                    }
                                }
                            } -EnableFiltering -EnableFilteringButton
                        }

                    }
                }
            }
        }
        New-HTMLTabPanel {
            New-HTMLTab -Name "🏗️AD Structure" {
                New-HTMLSection -Title "Active Directory Organizational Structure" {
                    $ADStructure = @(
                        # Include domains first
                        foreach ($Domain in $Organization.Domains) {
                            $Domain
                        }
                        # Include all containers
                        foreach ($Domain in $Organization.Containers.Keys) {
                            $Organization.Containers[$Domain]
                        }
                        # Include all organizational units
                        foreach ($Domain in $Organization.OrganizationalUnits.Keys) {
                            $Organization.OrganizationalUnits[$Domain]
                        }
                    )
                    New-HTMLTable -DataTable $ADStructure -DataTableID 'DT-OrganizationalUnits' -Filtering -ScrollX -ExcludeProperty 'Objects', 'OrganizationalUnits', 'OrganizationalUnitsCount', 'ParentContainers', 'ParentContainersCount'
                }
            }
            New-HTMLTab -Name "🛜Subnets" {
                New-HTMLSection -Title "Subnets" {
                    New-HTMLTable -DataTable $Subnets -Filtering -ScrollX
                }
            }
            New-HTMLTab -Name "🪑Sites" {
                New-HTMLSection -Title "Sites" {
                    New-HTMLTable -DataTable $Sites -DataTableID 'DT-Sites' -Filtering -ScrollX
                }
            }
        }
    } -ShowHTML:(-not $HideHTML) -FilePath $FilePath -Online:$Online.IsPresent
}