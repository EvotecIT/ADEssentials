function Show-WinADTrust {
    [alias('Show-ADTrust', 'Show-ADTrusts', 'Show-WinADTrusts')]
    [cmdletBinding()]
    param(
        [switch] $Recursive,
        [string] $FilePath,
        [switch] $Online,
        [switch] $HideHTML
    )
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    New-HTML -TitleText "Visual Trusts" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore HTML
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey


        #$Messages = $($ADTrusts = Get-WinADTrust -Recursive:$Recursive) 4>&1 3>&1 2>&1
        #$Messages += Write-Verbose "Show-WinADTrust - Found $($ADTrusts.Count) trusts" 4>&1
        $ADTrusts = Get-WinADTrust -Recursive:$Recursive
        Write-Verbose "Show-WinADTrust - Found $($ADTrusts.Count) trusts"
        New-HTMLTab -TabName 'Summary' {
            New-HTMLSection -HeaderText 'Trusts Diagram' {
                New-HTMLDiagram -Height 'calc(50vh)' {
                    #New-DiagramEvent -ID 'DT-TrustsInformation' -ColumnID 0
                    New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
                    foreach ($Node in $AllNodes) {
                        New-DiagramNode -Label $Node.'Trust'
                    }
                    foreach ($Trust in $ADTrusts) {
                        New-DiagramNode -Label $Trust.'TrustSource' -IconSolid audio-description #-IconColor LightSteelBlue
                        New-DiagramNode -Label $Trust.'TrustTarget' -IconSolid audio-description #-IconColor LightSteelBlue

                        $newDiagramLinkSplat = @{
                            From         = $Trust.'TrustSource'
                            To           = $Trust.'TrustTarget'
                            ColorOpacity = 0.7
                        }
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
                        New-DiagramLink @newDiagramLinkSplat
                    }
                }
            }
            New-HTMLSection -Title "Information about Trusts" {
                New-HTMLTable -DataTable $ADTrusts -Filtering {
                    #New-TableHeader -Names Name, SamAccountName, DomainName, DisplayName -Title 'Member'
                    #New-TableHeader -Names DirectMembers, DirectGroups, IndirectMembers, TotalMembers -Title 'Statistics'
                    #New-TableHeader -Names GroupType, GroupScope -Title 'Group Details'
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $false -Name Enabled -Operator eq
                    #New-TableCondition -BackgroundColor LightBlue -ComparisonType string -Value '' -Name ParentGroup -Operator eq -Row
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name CrossForest -Operator eq
                    New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'OK' -Name TrustStatus -Operator eq
                    New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'OK' -Name QueryStatus -Operator eq
                    New-TableCondition -BackgroundColor CoralRed -ComparisonType string -Value 'NOT OK' -Name QueryStatus -Operator eq
                    New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name IsTGTDelegationEnabled -Operator eq
                } -DataTableID 'DT-TrustsInformation'
            }
        }
        # Lets try to sort it into source domain per tab
        $TrustCache = [ordered]@{}
        foreach ($Trust in $ADTrusts) {
            #$Messages += Write-Verbose "Show-WinADTrust - Processing $($Trust.TrustSource) to $($Trust.TrustTarget)" 4>&1
            Write-Verbose "Show-WinADTrust - Processing $($Trust.TrustSource) to $($Trust.TrustTarget)"
            if (-not $TrustCache[$Trust.TrustSource]) {
                #$Messages += Write-Verbose "Show-WinADTrust - Creating cache for $($Trust.TrustSource)" 4>&1
                Write-Verbose "Show-WinADTrust - Creating cache for $($Trust.TrustSource)"
                $TrustCache[$Trust.TrustSource] = [System.Collections.Generic.List[PSCustomObject]]::new()
            }
            $TrustCache[$Trust.TrustSource].Add($Trust)
        }
        foreach ($Source in $TrustCache.Keys) {
            New-HTMLTab -TabName "Source $($Source.ToUpper())" {
                foreach ($Trust in $TrustCache[$Source]) {
                    if ($Trust.QueryStatus -eq 'OK' -or $Trust.TrustStatus -eq 'OK') {
                        $IconColor = 'MediumSeaGreen'
                        $IconSolid = 'smile'
                    } else {
                        $IconColor = 'CoralRed'
                        $IconSolid = 'angry'
                    }

                    New-HTMLTab -TabName "Target $($Trust.TrustTarget.ToUpper())" -IconColor $IconColor -IconSolid $IconSolid -TextColor $IconColor {
                        New-HTMLSection -Invisible {
                            New-HTMLSection -Title "Trust Information" {
                                New-HTMLTable -DataTable $Trust {
                                    New-TableHeader -Names Name, Value -Title 'Trust Information'
                                } -Transpose -HideFooter -DisablePaging -Buttons copyHtml5, excelHtml5, pdfHtml5
                            }
                            New-HTMLSection -Invisible -Wrap wrap {
                                New-HTMLSection -Title "Name suffix status" {
                                    New-HTMLTable -DataTable $Trust.AdditionalInformation.msDSTrustForestTrustInfo -Filtering {
                                        if ($Trust.AdditionalInformation.msDSTrustForestTrustInfo.Count -gt 0) {
                                            New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'Enabled' -Name Status -Operator eq -Row
                                            New-TableCondition -BackgroundColor CoralRed -ComparisonType string -Value 'Enabled' -Name Status -Operator ne -Row
                                        }
                                    }
                                }
                                New-HTMLSection -Title "Name suffix routing (include)" {
                                    New-HTMLTable -DataTable $Trust.AdditionalInformation.SuffixesInclude -Filtering {
                                        if ($Trust.AdditionalInformation.SuffixesInclude.Count -gt 0) {
                                            New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'Enabled' -Name Status -Operator eq -Row
                                            New-TableCondition -BackgroundColor CoralRed -ComparisonType string -Value 'Enabled' -Name Status -Operator ne -Row
                                        }
                                    }
                                }
                                New-HTMLSection -Title "Name suffix routing (exclude)" {
                                    New-HTMLTable -DataTable $Trust.AdditionalInformation.SuffixesExclude -Filtering {
                                        if ($Trust.AdditionalInformation.SuffixesExclude.Count -gt 0) {
                                            New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value 'Enabled' -Name Status -Operator eq -Row
                                            New-TableCondition -BackgroundColor CoralRed -ComparisonType string -Value 'Enabled' -Name Status -Operator ne -Row
                                        }
                                    }
                                }
                            }
                        }

                    }
                }
            }
        }
        #New-HTMLTab -TabName "Logs" {
        #    New-HTMLTable -DataTable ($Messages.Message)
        #}
    } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
}