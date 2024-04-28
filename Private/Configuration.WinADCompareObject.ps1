$Script:ConfigurationGlobalCatalogObjects = [ordered] @{
    Name       = 'Global Catalogs Object Summary'
    Enabled    = $true
    Execute    = {
        Compare-WinADGlobalCatalogObjects
    }
    Processing = {

    }
    Summary    = {
        New-HTMLText -Text @(
            "This report compares all objects on every domain controller in the forest and reports on missing objects and objects with wrong GUIDs between them."
            "By comparing the objects on each domain controller, you can identify replication issues and inconsistencies between domain controllers."
            "This report is useful for identifying issues with the global catalog and replication in your Active Directory forest."
            "The report is split into two sections: Missing Objects and Wrong GUID Objects."
        ) -FontSize 10pt -LineBreak

        foreach ($Domain in $Script:Reporting['GlobalCatalogComparison']['Data'].Keys) {
            New-HTMLText -Text "Summary for ", $Domain, " domain" -FontSize 10pt -FontWeight normal, bold, normal
            New-HTMLList {
                New-HTMLListItem -Text "Missing Objects: ", $($Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.MissingObject) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Wrong GUID Objects: ", $($Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.WrongGuid) -Color Black, Red -FontWeight normal, bold
                if ($Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.MissingObjectDC.Count -gt 0) {
                    New-HTMLListItem -Text "Domain Controllers with Missing Objects: " -FontSize 10pt -FontWeight normal, bold -NestedListItems {
                        New-HTMLList -Type Unordered {
                            foreach ($DC in $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.MissingObjectDC) {
                                New-HTMLListItem -Text $DC -Color Black, Red -FontSize 10p
                            }
                        }
                    }
                }
                if ($Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.WrongGuidDC.Count -gt 0) {
                    New-HTMLListItem -Text "Domain Controllers with Wrong GUID Objects: " -FontSize 10pt -FontWeight normal, bold -NestedListItems {
                        New-HTMLList -Type Unordered {
                            foreach ($DC in $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.WrongGuidDC) {
                                New-HTMLListItem -Text $DC -Color Black, Red -FontSize 10pt
                            }
                        }
                    }
                }
            } -FontSize 10pt
        }

        New-HTMLText -Text "While it's possible to have some missing objects, it should be investigated why that is. " -FontSize 10pt
    }
    Variables  = @{

    }
    Solution   = {
        if ($Script:Reporting['GlobalCatalogComparison']['Data']) {

            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['GlobalCatalogComparison']['Summary']
                }
            }

            New-HTMLTabPanel {
                foreach ($Domain in $Script:Reporting['GlobalCatalogComparison']['Data'].Keys) {

                    New-HTMLTab -Name $Domain {
                        New-HTMLSection -HeaderText "Missing Objects in $Domain per Domain Controller" {
                            $Data = foreach ($Key in  $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Keys) {
                                if ($Key -eq 'Summary') {
                                    continue
                                }
                                $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain][$Key].Missing
                            }
                            New-HTMLTable -DataTable $Data -Filtering {

                            } -IncludeProperty 'GlobalCatalog', 'DistinguishedName', 'Name', 'ObjectClass', 'WhenCreated', 'WhenChanged', 'ObjectGuid'
                        }
                        New-HTMLSection -HeaderText "Wrong GUID Objects in $Domain per Domain Controller" {
                            $Data = foreach ($Key in  $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Keys) {
                                if ($Key -eq 'Summary') {
                                    continue
                                }
                                $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain][$Key].WrongGuid
                            }
                            New-HTMLTable -DataTable $Data -Filtering {

                            } -IncludeProperty 'GlobalCatalog', 'DistinguishedName', 'Name', 'ObjectClass', 'WhenCreated', 'WhenChanged', 'ObjectGuid'
                        }
                    }
                }
            }
        }
    }
}