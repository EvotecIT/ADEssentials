function Show-WinADTrust {
    <#
    .SYNOPSIS
    Generates a detailed HTML report on the trust relationships in a specified Active Directory forest.

    .DESCRIPTION
    This cmdlet creates a comprehensive HTML report that includes the trust relationships, their properties, and a diagram of their relationships. The report is designed to provide a clear overview of the trust relationships within the Active Directory.

    .PARAMETER Conditions
    Specifies the conditions to filter the trust relationships. This can be a script block that returns a boolean value.

    .PARAMETER Recursive
    A switch to include all trust relationships in the report, including those that are not direct.

    .PARAMETER FilePath
    The path to save the HTML report. If not specified, a temporary file is used.

    .PARAMETER Online
    A switch to display the HTML report in the default web browser.

    .PARAMETER HideHTML
    A switch to hide the HTML report after it is generated.

    .PARAMETER DisableBuiltinConditions
    A switch to disable the built-in conditions for filtering the trust relationships.

    .PARAMETER PassThru
    A switch to return the trust relationships as objects.

    .PARAMETER SkipValidation
    A switch to skip the validation of the trust relationships.

    .EXAMPLE
    Show-WinADTrust -Recursive -Online

    .NOTES
    This cmdlet is useful for auditing and analyzing the trust relationships in Active Directory, helping administrators to identify potential security risks and ensure compliance with organizational policies.
    #>
    [alias('Show-ADTrust', 'Show-ADTrusts', 'Show-WinADTrusts')]
    [cmdletBinding()]
    param(
        [Parameter(Position = 0)][scriptblock] $Conditions,
        [switch] $Recursive,
        [string] $FilePath,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $DisableBuiltinConditions,
        [switch] $PassThru,
        [switch] $SkipValidation
    )
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    $Script:ADTrusts = @()
    New-HTML -TitleText "Visual Trusts" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore HTML
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        $Script:ADTrusts = Get-WinADTrust -Recursive:$Recursive -SkipValidation:$SkipValidation.IsPresent
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
                        New-DiagramNode -Label $Trust.'TrustSource' -IconSolid audio-description
                        New-DiagramNode -Label $Trust.'TrustTarget' -IconSolid audio-description

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
                    if (-not $DisableBuiltinConditions) {
                        New-TableCondition -BackgroundColor LimeGreen -ComparisonType string -Value 'OK' -Name TrustStatus -Operator eq
                        New-TableCondition -BackgroundColor LimeGreen -ComparisonType string -Value 'OK' -Name QueryStatus -Operator eq
                        New-TableCondition -BackgroundColor CoralRed -ComparisonType string -Value 'NOT OK' -Name QueryStatus -Operator eq
                        New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name IsTGTDelegationEnabled -Operator eq
                        New-TableCondition -ComparisonType number -Name 'ModifiedDaysAgo' -Operator gt -Value 15 -BackgroundColor MediumSeaGreen
                        New-TableCondition -ComparisonType number -Name 'ModifiedDaysAgo' -Operator gt -Value 30 -BackgroundColor GoldenFizz
                        New-TableCondition -ComparisonType number -Name 'ModifiedDaysAgo' -Operator gt -Value 90 -BackgroundColor CoralRed
                        New-TableCondition -ComparisonType number -Name 'ModifiedDaysAgo' -Operator le -Value 15 -BackgroundColor LimeGreen

                        New-TableCondition -ComparisonType string -Name 'Status' -Operator eq -Value 'Enabled' -BackgroundColor LimeGreen
                        New-TableCondition -ComparisonType string -Name 'Status' -Operator eq -Value 'Internal' -BackgroundColor LightBlue
                        New-TableCondition -ComparisonType string -Name 'Status' -Operator notin -Value 'Internal', 'Enabled' -BackgroundColor LightCoral
                    }
                    if ($Conditions) {
                        & $Conditions
                    }
                } -DataTableID 'DT-TrustsInformation' -ScrollX -ExcludeProperty 'AdditionalInformation'
            }
        }
        # Lets try to sort it into source domain per tab
        $TrustCache = [ordered]@{}
        foreach ($Trust in $ADTrusts) {
            Write-Verbose "Show-WinADTrust - Processing $($Trust.TrustSource) to $($Trust.TrustTarget)"
            if (-not $TrustCache[$Trust.TrustSource]) {
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

                                } -Transpose -TransposeName 'Setting' -HideFooter -DisablePaging -Buttons copyHtml5, excelHtml5, pdfHtml5 -ExcludeProperty AdditionalInformation
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
    } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
    if ($PassThru) {
        $Script:ADTrusts
    }
}