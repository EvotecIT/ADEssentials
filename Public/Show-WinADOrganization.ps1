function Show-WinADOrganization {
    [cmdletBinding()]
    param(
        [ScriptBlock] $Conditions,
        [string] $FilePath
    )

    $CachedOU = [ordered] @{}
    $ForestInformation = Get-WinADForestDetails
    $Script:OrganiazationalUnits = @()
    #$Organization = Get-WinADOrganization

    New-HTML -TitleText "Visual Active Directory Organization" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore HTML
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
        New-HTMLTabPanel {
            New-HTMLTab -TabName 'Standard' {
                New-HTMLSection -HeaderText 'Organization Diagram' {
                    New-HTMLDiagram -Height 'calc(50vh)' {
                        New-DiagramEvent -ID 'DT-StandardOrg' -ColumnID 3
                        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
                        #foreach ($OU in $Organization.Keys) {
                        #Add-Node -Name $OU -Organization $Organization
                        #New-DiagramNode -Label $OU
                        #}

                        foreach ($Domain in $ForestInformation.Domains) {
                            New-DiagramNode -Label $Domain -Id $Domain -Image 'https://cdn-icons-png.flaticon.com/512/6329/6329785.png'

                            $Script:OrganiazationalUnits = Get-ADOrganizationalUnit -Filter * -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -Properties DistinguishedName, CanonicalName
                            foreach ($OU in $OrganiazationalUnits) {
                                New-DiagramNode -Id $OU.DistinguishedName -Label $OU.Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png'

                                [Array] $SubOU = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit
                                if ($SubOU.Count -gt 0) {
                                    foreach ($Sub in $SubOU[0]) {
                                        $Name = ConvertFrom-DistinguishedName -DistinguishedName $Sub -ToLastName
                                        New-DiagramNode -Id $Sub -Label $Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png'
                                        New-DiagramEdge -From $OU.DistinguishedName -To $Sub -Color Blue -ArrowsToEnabled -Dashes
                                    }
                                } else {
                                    New-DiagramEdge -From $Domain -To $OU.DistinguishedName -Color Blue -ArrowsToEnabled -Dashes
                                }

                                <#
                            $NameSplit = $OU.canonicalName.Split("/")
                            $CurrentLevel = $CachedOU[$Domain]
                            foreach ($N in $NameSplit) {
                                if ($N -ne $Domain) {
                                    if (-not $CurrentLevel[$N]) {
                                        $CurrentLevel[$N] = [ordered] @{}
                                    } else {
                                        $CurrentLevel = $CurrentLevel[$N]
                                    }

                                }
                            }
                            #>
                            }
                            <#
                        foreach ($OU in $OrganiazationalUnits) {
                            [Array] $SubOU = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit -IncludeParent | Select-Object -Last 1

                            New-DiagramLink -From $OU.DistinguishedName -To $O

                        }
                        #>
                        }
                        #$CachedOU


                        foreach ($Trust in $ADTrusts) {
                            #New-DiagramNode -Label $Trust.'TrustSource' -IconSolid audio-description #-IconColor LightSteelBlue
                            #New-DiagramNode -Label $Trust.'TrustTarget' -IconSolid audio-description #-IconColor LightSteelBlue

                            $newDiagramLinkSplat = @{
                                From         = $Trust.'TrustSource'
                                To           = $Trust.'TrustTarget'
                                ColorOpacity = 0.7
                            }
                            <#
                        if ($Trust.'TrustDirection' -eq 'Disabled') {

                        } elseif ($Trust.'TrustDirection' -eq 'Inbound') {
                            $newDiagramLinkSplat.ArrowsFromEnabled = $true
                        } elseif ($Trust.'TrustDirection' -eq 'Outbount') {
                            $newDiagramLinkSplat.ArrowsToEnabled = $true
                            New-DiagramLink @newDiagramLinkSplat
                        } elseif ($Trust.'TrustDirection' -eq 'Bidirectional') {
                            $newDiagramLinkSplat.ArrowsToEnabled = $true
                            $newDiagramLinkSplat.ArrowsFromEnabled = $true
                        }
                        if ($Trust.IntraForest) {
                            $newDiagramLinkSplat.Color = 'DarkSpringGreen'
                        }
                        if ($Trust.QueryStatus -eq 'OK' -or $Trust.TrustStatus -eq 'OK') {
                            $newDiagramLinkSplat.Dashes = $false
                            $newDiagramLinkSplat.FontColor = 'Green'
                        } else {
                            $newDiagramLinkSplat.Dashes = $true
                            $newDiagramLinkSplat.FontColor = 'Red'
                        }
                        if ($Trust.IsTGTDelegationEnabled) {
                            $newDiagramLinkSplat.Color = 'Red'
                            $newDiagramLinkSplat.Label = "Delegation Enabled"
                        } else {
                            $newDiagramLinkSplat.Label = $Trust.QueryStatus
                        }
                        #>
                            #New-DiagramLink @newDiagramLinkSplat
                        }
                    }
                }

            }
            New-HTMLTab -TabName 'Hierarchical' {
                New-HTMLSection -HeaderText 'Organization Diagram' {
                    New-HTMLDiagram -Height 'calc(50vh)' {
                        New-DiagramOptionsLayout -HierarchicalEnabled $true
                        New-DiagramEvent -ID 'DT-StandardOrg' -ColumnID 3
                        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
                        #foreach ($OU in $Organization.Keys) {
                        #Add-Node -Name $OU -Organization $Organization
                        #New-DiagramNode -Label $OU
                        #}

                        foreach ($Domain in $ForestInformation.Domains) {
                            New-DiagramNode -Label $Domain -Id $Domain -Image 'https://cdn-icons-png.flaticon.com/512/6329/6329785.png'

                            $Script:OrganiazationalUnits = Get-ADOrganizationalUnit -Filter * -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -Properties DistinguishedName, CanonicalName
                            foreach ($OU in $OrganiazationalUnits) {
                                New-DiagramNode -Id $OU.DistinguishedName -Label $OU.Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png'

                                [Array] $SubOU = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit
                                if ($SubOU.Count -gt 0) {
                                    foreach ($Sub in $SubOU[0]) {
                                        $Name = ConvertFrom-DistinguishedName -DistinguishedName $Sub -ToLastName
                                        New-DiagramNode -Id $Sub -Label $Name -Image 'https://cdn-icons-png.flaticon.com/512/3767/3767084.png'
                                        New-DiagramEdge -From $OU.DistinguishedName -To $Sub
                                    }
                                } else {
                                    New-DiagramEdge -From $Domain -To $OU.DistinguishedName
                                }

                                <#
                            $NameSplit = $OU.canonicalName.Split("/")
                            $CurrentLevel = $CachedOU[$Domain]
                            foreach ($N in $NameSplit) {
                                if ($N -ne $Domain) {
                                    if (-not $CurrentLevel[$N]) {
                                        $CurrentLevel[$N] = [ordered] @{}
                                    } else {
                                        $CurrentLevel = $CurrentLevel[$N]
                                    }

                                }
                            }
                            #>
                            }
                            <#
                        foreach ($OU in $OrganiazationalUnits) {
                            [Array] $SubOU = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit -IncludeParent | Select-Object -Last 1

                            New-DiagramLink -From $OU.DistinguishedName -To $O

                        }
                        #>
                        }
                        #$CachedOU


                        foreach ($Trust in $ADTrusts) {
                            #New-DiagramNode -Label $Trust.'TrustSource' -IconSolid audio-description #-IconColor LightSteelBlue
                            #New-DiagramNode -Label $Trust.'TrustTarget' -IconSolid audio-description #-IconColor LightSteelBlue

                            $newDiagramLinkSplat = @{
                                From         = $Trust.'TrustSource'
                                To           = $Trust.'TrustTarget'
                                ColorOpacity = 0.7
                            }
                            <#
                        if ($Trust.'TrustDirection' -eq 'Disabled') {

                        } elseif ($Trust.'TrustDirection' -eq 'Inbound') {
                            $newDiagramLinkSplat.ArrowsFromEnabled = $true
                        } elseif ($Trust.'TrustDirection' -eq 'Outbount') {
                            $newDiagramLinkSplat.ArrowsToEnabled = $true
                            New-DiagramLink @newDiagramLinkSplat
                        } elseif ($Trust.'TrustDirection' -eq 'Bidirectional') {
                            $newDiagramLinkSplat.ArrowsToEnabled = $true
                            $newDiagramLinkSplat.ArrowsFromEnabled = $true
                        }
                        if ($Trust.IntraForest) {
                            $newDiagramLinkSplat.Color = 'DarkSpringGreen'
                        }
                        if ($Trust.QueryStatus -eq 'OK' -or $Trust.TrustStatus -eq 'OK') {
                            $newDiagramLinkSplat.Dashes = $false
                            $newDiagramLinkSplat.FontColor = 'Green'
                        } else {
                            $newDiagramLinkSplat.Dashes = $true
                            $newDiagramLinkSplat.FontColor = 'Red'
                        }
                        if ($Trust.IsTGTDelegationEnabled) {
                            $newDiagramLinkSplat.Color = 'Red'
                            $newDiagramLinkSplat.Label = "Delegation Enabled"
                        } else {
                            $newDiagramLinkSplat.Label = $Trust.QueryStatus
                        }
                        #>
                            #New-DiagramLink @newDiagramLinkSplat
                        }
                    }
                }

            }
        }

        New-HTMLSection -Title "Information about Trusts" {
            New-HTMLTable -DataTable $Script:OrganiazationalUnits -Filtering {
                if (-not $DisableBuiltinConditions) {
                    #New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'OK' -Name TrustStatus -Operator eq
                    #New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'OK' -Name QueryStatus -Operator eq
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType string -Value 'NOT OK' -Name QueryStatus -Operator eq
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name IsTGTDelegationEnabled -Operator eq
                }
                if ($Conditions) {
                    & $Conditions
                }
            } -DataTableID 'DT-StandardOrg'
        }
    } -ShowHTML -FilePath $FilePath -Online
}