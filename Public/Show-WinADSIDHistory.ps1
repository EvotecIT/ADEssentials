function Show-WinADSIDHistory {
    <#
    .SYNOPSIS
    Generates an HTML report for SID History across the Active Directory forest.

    .DESCRIPTION
    This function generates a comprehensive HTML report showing SID History information for objects in the Active Directory forest.
    It displays statistics about objects with SID history values, including users, groups, and computers, as well as their enabled/disabled status.
    The report also includes information about internal, external, and unknown SID history values and their respective domains.

    .PARAMETER Forest
    The name of the Active Directory forest to analyze.

    .PARAMETER ExcludeDomains
    An array of domain names to exclude from the analysis.

    .PARAMETER IncludeDomains
    An array of domain names to include in the analysis. Also aliased as 'Domain' or 'Domains'.

    .PARAMETER ExtendedForestInformation
    A hashtable containing extended forest information. Usually provided by Get-WinADForestDetails.

    .PARAMETER PassThru
    Switch to return the SID history data as output in addition to generating the HTML report.

    .PARAMETER FilePath
    The path where the HTML report will be saved.

    .PARAMETER HideHTML
    Switch to prevent the automatic display of the HTML report after generation.

    .PARAMETER Online
    Switch to indicate if the report should be generated with online resources.

    .EXAMPLE
    Show-WinADSIDHistory -Online

    Generates and displays an HTML report of SID History for the current forest using online resources.

    .EXAMPLE
    Show-WinADSIDHistory -Forest "contoso.com" -FilePath "C:\Reports\SIDHistory.html"

    Generates an HTML report for the specified forest and saves it to the specified file path.

    .EXAMPLE
    Show-WinADSIDHistory -IncludeDomains "domain1.local","domain2.local" -PassThru

    Generates a report for specific domains and returns the data structure for further processing.

    .NOTES
    The report includes:
    - Total count of objects with SID history
    - Breakdown by object type (users, groups, computers)
    - Enabled vs disabled objects statistics
    - Domain SID information
    - Detailed per-domain analysis
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $PassThru,
        [string] $FilePath,
        [switch] $HideHTML,
        [switch] $Online
    )
    $Output = @{}
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -Extended
    $Output = Get-WinADSIDHistory -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ForestInformation -All

    New-HTML {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString ", " -BoolAsString
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

            New-HTMLText -Text "Overview of SID History in the forest ", $($ForestInformation.Forest) -Color None, None -FontSize 14pt -FontWeight normal, bold -Alignment center

            New-HTMLSection -HeaderText "SID History Report for $($ForestInformation.Forest)" {
                New-HTMLPanel {
                    New-HTMLText -Text @(
                        "The following table lists all objects in the forest that have SID history values. ",
                        "The table is grouped by domain and shows the number of objects in each domain that have SID history values."
                    ) -FontSize 10pt

                    New-HTMLList {
                        New-HTMLListItem -Text "$($Output.All.Count)", " objects with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.TotalUsers)", "  users with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.TotalGroups)", "  groups with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.TotalComputers)", "  computers with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.EnabledObjects)", "  enabled objects with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.DisabledObjects)", "  disabled objects with SID history values" -Color Salmon, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Keys.Count - 2)", "  different domains with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                    } -LineBreak -FontSize 10pt

                    New-HTMLText -Text @(
                        "The following table lists all trusts in the forest and their respective trust type.",
                        "The trust type can be either external or forest trust."
                    ) -FontSize 10pt

                    New-HTMLText -Text "The following statistics provide insights into the SID history categories:" -FontSize 10pt

                    New-HTMLList {
                        # Add statistics for the three SID history categories
                        New-HTMLListItem -Text "$($Output.Statistics.InternalSIDs)", " SID history values from internal forest domains" -Color ForestGreen, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.ExternalSIDs)", " SID history values from external trusted domains" -Color DodgerBlue, None -FontWeight bold, normal
                        New-HTMLListItem -Text "$($Output.Statistics.UnknownSIDs)", " SID history values from unknown domains (deleted or broken trusts)" -Color Crimson, None -FontWeight bold, normal
                    } -FontSize 10pt
                }
                New-HTMLPanel {
                    New-HTMLText -Text "The following table lists all domains in the forest and their respective domain SID values." -FontSize 10pt
                    New-HTMLList {
                        foreach ($SID in $Output.DomainSIDs.Keys) {
                            $DomainSID = $Output.DomainSIDs[$SID]
                            New-HTMLListItem -Text "Domain ", $($DomainSID.Domain), ", SID: ", $($DomainSID.SID), ", Type: ", $($DomainSID.Type) -Color None, BlueViolet, None, BlueViolet, None, BlueViolet -FontWeight normal, bold, normal, bold, normal, bold
                        }
                    } -FontSize 10pt
                }
            }
        }
        [Array] $DomainNames = foreach ($Key in $Output.Keys) {
            if ($Key -in @('Statistics', 'Trusts', 'DomainSIDs', 'DuplicateSIDs')) {
                continue
            }
            $Key
        }
        foreach ($Domain in $DomainNames) {
            [Array] $Objects = $Output[$Domain]
            $EnabledObjects = $Objects | Where-Object { $_.Enabled }
            $DisabledObjects = $Objects | Where-Object { -not $_.Enabled }
            $Types = $Objects | Group-Object -Property ObjectClass -NoElement


            if ($Domain -eq 'All') {
                $Name = 'All'
            } else {
                if ($Output.DomainSIDs[$Domain]) {
                    $DomainName = $Output.DomainSIDs[$Domain].Domain
                    $DomainType = $Output.DomainSIDs[$Domain].Type
                    #$Name = "$Domain [$DomainName] ($($Objects.Count))"
                    $Name = "$DomainName ($($Objects.Count))"
                } else {
                    $Name = "$Domain ($($Objects.Count))"
                }
            }

            New-HTMLTab -Name $Name {
                New-HTMLSection -HeaderText "Domain $Domain" {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "Overview for ", $Domain -Color Blue, BattleshipGrey -FontSize 10pt
                        New-HTMLList {
                            New-HTMLListItem -Text "$($Objects.Count)", " objects with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                            New-HTMLListItem -Text "$($EnabledObjects.Count)", " enabled objects with SID history values" -Color Green, None -FontWeight bold, normal
                            New-HTMLListItem -Text "$($DisabledObjects.Count)", " disabled objects with SID history values" -Color Salmon, None -FontWeight bold, normal

                            # Calculate SID history categories for this domain
                            $InternalSIDsForDomain = ($Objects | ForEach-Object { $_.InternalCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                            $ExternalSIDsForDomain = ($Objects | ForEach-Object { $_.ExternalCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                            $UnknownSIDsForDomain = ($Objects | ForEach-Object { $_.UnknownCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum

                            New-HTMLListItem -Text "$InternalSIDsForDomain", " SID history values from internal forest domains" -Color ForestGreen, None -FontWeight bold, normal
                            New-HTMLListItem -Text "$ExternalSIDsForDomain", " SID history values from external trusted domains" -Color DodgerBlue, None -FontWeight bold, normal
                            New-HTMLListItem -Text "$UnknownSIDsForDomain", " SID history values from unknown domains" -Color Crimson, None -FontWeight bold, normal

                            New-HTMLListItem -Text "Object types:" {
                                New-HTMLList {
                                    foreach ($Type in $Types) {
                                        New-HTMLListItem -Text "$($Type.Count)", " ", $Type.Name, " objects with SID history values" -Color BlueViolet, None, BlueViolet, None -FontWeight bold, normal, bold, normal
                                    }
                                }
                            } -FontSize 10pt
                        } -FontSize 10pt
                    }
                }
                New-HTMLTable -DataTable $Objects -Filtering {
                    New-HTMLTableCondition -Name 'Enabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor MintGreen -FailBackgroundColor Salmon
                    New-HTMLTableCondition -Name 'InternalCount' -ComparisonType number -Operator gt -Value 0 -BackgroundColor ForestGreen
                    New-HTMLTableCondition -Name 'ExternalCount' -ComparisonType number -Operator gt -Value 0 -BackgroundColor DodgerBlue
                    New-HTMLTableCondition -Name 'UnknownCount' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Crimson
                } -ScrollX
            } -TextTransform uppercase
        }
        New-HTMLFooter {
            New-HTMLText -Text 'Explanation to table columns:' -FontSize 10pt
            New-HTMLList {
                New-HTMLListItem -Text "Domain", " - ", "this column shows the domain of the object" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "ObjectClass", " - ", "this column shows the object class of the object (user, device, group)" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "Internal", " - ", "this column shows SIDs from domains within the current forest" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "External", " - ", "this column shows SIDs from domains that are trusted by the current forest" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "Unknown", " - ", "this column shows SIDs from domains that no longer exist or have broken trusts" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "Enabled", " - ", "this column shows if the object is enabled" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "SIDHistory", " - ", "this column shows the SID history values of the object" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "Domains", " - ", "this column shows the domains of the SID history values" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "DomainsExpanded", " - ", "this column shows the expanded domains of the SID history values (if possible), including SID if not possible to expand" -FontWeight bold, normal, normal
            } -FontSize 10pt
        }
    } -FilePath $FilePath -ShowHTML:(-not $HideHTML) -Online:$Online.IsPresent

    if ($PassThru) {
        $Output
    }
}