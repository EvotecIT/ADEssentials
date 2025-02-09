function Show-WinADSIDHistory {
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
                    #New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                } -JustifyContent flex-end -Invisible
            }

            New-HTMLSection -HeaderText "SID History Report for $($ForestInformation.Forest)" {
                New-HTMLPanel {
                    New-HTMLText -Text "Overview of SID History in the forest ", $($ForestInformation.Forest) -Color Blue, BattleshipGrey -FontSize 14pt

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
                    } -FontSize 10pt
                }
                New-HTMLPanel {
                    New-HTMLText -Text "The following table lists all domains in the forest and their respective domain SID values." -FontSize 10pt
                    New-HTMLList {
                        foreach ($SID in $Output.DomainSIDs.Keys) {
                            $DomainSID = $Output.DomainSIDs[$SID]
                            New-HTMLListItem -Text "Domain ", $($DomainSID.Domain), ", SID: ", $($DomainSID.SID), ", Type: ", $($DomainSID.Type) -Color None, BlueViolet, None, BlueViolet, None, BlueViolet -FontWeight bold, normal
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
            New-HTMLTab -Name "$Domain ($($Objects.Count))" {
                New-HTMLSection -HeaderText "Domain $Domain" {
                    New-HTMLPanel -Invisible {
                        New-HTMLText -Text "Overview of SID History in the domain ", $Domain -Color Blue, BattleshipGrey -FontSize 14pt
                        New-HTMLList {
                            New-HTMLListItem -Text "$($Objects.Count)", " objects with SID history values" -Color BlueViolet, None -FontWeight bold, normal
                        } -FontSize 10pt
                    }
                }
                New-HTMLTable -DataTable $Objects -Filtering {
                    New-HTMLTableCondition -Name 'Enabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor MintGreen -FailBackgroundColor Salmon
                } -ScrollX
            } -TextTransform uppercase
        }
        New-HTMLFooter {
            New-HTMLText -Text 'Explanation to table columns:' -FontSize 10pt
            New-HTMLList {
                New-HTMLListItem -Text "Domain", " - ", "this column shows the domain of the object" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "ObjectClass", " - ", "this column shows the object class of the object (user, device, group)" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "Internal", " - ", "this column shows if the object is from the same forest (internal migration)" -FontWeight bold, normal, normal
                New-HTMLListItem -Text "External", " - ", "this column shows if the object is from a different forest" -FontWeight bold, normal, normal
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