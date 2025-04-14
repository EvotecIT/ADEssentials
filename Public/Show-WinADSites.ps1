function Show-WinADSites {
    <#
    .SYNOPSIS
    Generates a detailed HTML report on the sites, subnets and replication in a specified Active Directory forest.

    .DESCRIPTION
    This cmdlet creates a comprehensive HTML report that includes a diagram of the sites and their relationships, as well as a table with detailed information about the sites and their replication status. The report is designed to provide a clear overview of the site structure and replication health within the Active Directory.

    .PARAMETER Conditions
    Specifies the conditions to filter the sites and replication information. This can be a script block that returns a boolean value.

    .PARAMETER FilePath
    The path to save the HTML report. If not specified, a temporary file is used.

    .EXAMPLE
    Show-WinADSites -FilePath "C:\Reports\AD Sites Report.html"

    .NOTES
    This cmdlet is useful for administrators to visualize and analyze the site structure and replication health in Active Directory, helping to identify potential issues and ensure efficient domain controller communication.
    #>
    [Alias('Show-WinADSubnets')]
    [cmdletBinding()]
    param(
        [ScriptBlock] $Conditions,
        [string] $FilePath
    )
    $CacheReplication = @{}
    $Sites = Get-WinADForestSites
    $Subnets = Get-WinADForestSubnet -VerifyOverlap
    $Replication = Get-WinADForestReplication
    foreach ($Rep in $Replication) {
        $CacheReplication["$($Rep.Server)$($Rep.ServerPartner)"] = $Rep
    }

    New-HTML -TitleText "Visual Active Directory Organization" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore HTML -BoolAsString
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

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
        New-HTMLTabPanel {
            New-HTMLTab -Name 'Sites & Subnets' {
                New-HTMLSection -Title "Information about Sites" {
                    New-HTMLTable -DataTable $Sites -Filtering {
                        if (-not $DisableBuiltinConditions) {
                            New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType number -Value 0 -Name SubnetsCount -Operator gt
                            New-TableCondition -BackgroundColor CoralRed -ComparisonType number -Value 0 -Name SubnetsCount -Operator eq
                        }
                        if ($Conditions) {
                            & $Conditions
                        }
                    } -DataTableID 'DT-StandardSites' -DataStore JavaScript -ScrollX
                }
                New-HTMLSection -Title "Information about Subnets" {
                    New-HTMLTable -DataTable $Subnets -Filtering {
                        if (-not $DisableBuiltinConditions) {
                            New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value $true -Name SiteStatus -FailBackgroundColor CoralRed
                            New-TableCondition -BackgroundColor MediumSeaGreen -ComparisonType string -Value $false -Name Overlap -FailBackgroundColor CoralRed
                        }
                        if ($Conditions) {
                            & $Conditions
                        }
                    } -DataTableID 'DT-StandardSubnets1' -DataStore JavaScript -ScrollX
                }
            }
            New-HTMLTab -Name 'Replication' {
                New-HTMLSection -Title "Information about Replication" {
                    New-HTMLTable -DataTable $Replication -Filtering {
                        if (-not $DisableBuiltinConditions) {

                        }
                        if ($Conditions) {
                            & $Conditions
                        }
                    } -DataTableID 'DT-StandardReplication' -DataStore JavaScript -ScrollX
                }
            }
        }
    } -ShowHTML -FilePath $FilePath -Online
}