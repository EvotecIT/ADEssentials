function Show-WinADSites {
    [cmdletBinding()]
    param(
        [ScriptBlock] $Conditions,
        [string] $FilePath
    )
    $CacheReplication = @{}
    $Sites = Get-WinADForestSites
    $Replication = Get-WinADForestReplication
    foreach ($Rep in $Replication) {
        $CacheReplication["$($Rep.Server)$($Rep.ServerPartner)"] = $Rep
    }

    New-HTML -TitleText "Visual Active Directory Organization" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore HTML
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
        New-HTMLTabPanel {
            New-HTMLTab -TabName 'Standard' {
                New-HTMLSection -HeaderText 'Organization Diagram' {
                    New-HTMLDiagram -Height 'calc(50vh)' {
                        New-DiagramEvent -ID 'DT-StandardSites' -ColumnID 0
                        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
                        foreach ($Site in $Sites) {
                            New-DiagramNode -Id $Site.DistinguishedName -Label $Site.Name -Image 'https://cdn-icons-png.flaticon.com/512/1104/1104991.png'
                            foreach ($Subnet in $Site.Subnets) {
                                New-DiagramNode -Id $Subnet -Label $Subnet -Image 'https://cdn-icons-png.flaticon.com/512/1674/1674968.png'
                                New-DiagramEdge -From $Subnet -To $Site.DistinguishedName
                            }
                            foreach ($DC in $Site.DomainControllers) {
                                New-DiagramNode -Id $DC -Label $DC -Image 'https://cdn-icons-png.flaticon.com/512/1383/1383395.png'
                                New-DiagramEdge -From $DC -To $Site.DistinguishedName
                            }
                        }
                        foreach ($R in $CacheReplication.Values) {
                            if ($R.ConsecutiveReplicationFailures -gt 0) {
                                $Color = 'CoralRed'
                            } else {
                                $Color = 'MediumSeaGreen'
                            }
                            New-DiagramEdge -From $R.Server -To $R.ServerPartner -Color $Color -ArrowsToEnabled -ColorOpacity 0.5
                        }
                    }
                }
            }
        }
        New-HTMLSection -Title "Information about Sites" {
            New-HTMLTable -DataTable $Sites -Filtering {
                if (-not $DisableBuiltinConditions) {
                    New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType number -Value 0 -Name SubnetsCount -Operator gt
                    New-TableCondition -BackgroundColor CoralRed -ComparisonType number -Value 0 -Name SubnetsCount -Operator eq
                }
                if ($Conditions) {
                    & $Conditions
                }
            } -DataTableID 'DT-StandardSites' -DataStore JavaScript


        }
        New-HTMLTable -DataTable $Replication -Filtering {
            if (-not $DisableBuiltinConditions) {
                New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType number -Value 0 -Name SubnetsCount -Operator gt
                New-TableCondition -BackgroundColor CoralRed -ComparisonType number -Value 0 -Name SubnetsCount -Operator eq
            }
            if ($Conditions) {
                & $Conditions
            }
        } -DataTableID 'DT-StandardSites1' -DataStore JavaScript
    } -ShowHTML -FilePath $FilePath -Online
}