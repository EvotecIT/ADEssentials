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

        $ADTrusts = Get-WinADTrusts -Recursive:$Recursive

        New-HTMLTab -TabName 'Trusts' {
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
                }
            }
            New-HTMLSection {
                New-HTMLDiagram {
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
                            ColorOpacity = 0.5
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
                        }
                        $newDiagramLinkSplat.Label = $Trust.QueryStatus
                        New-DiagramLink @newDiagramLinkSplat
                    }
                }
            }
        }

    } -Online:$Online -FilePath $FilePath -ShowHTML:(-not $HideHTML)
}