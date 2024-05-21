$Script:ConfigurationGlobalCatalogObjects = [ordered] @{
    Name       = 'Global Catalogs Object Summary'
    Enabled    = $true
    Execute    = {
        Compare-WinADGlobalCatalogObjects -Advanced -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
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
                # New-HTMLListItem -Text "Missing Objects in Global Catalog (Reverse Lookup): ", $($Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.MissingAtSource) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Wrong GUID Objects: ", $($Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.WrongGuid) -Color Black, Red -FontWeight normal, bold
                New-HTMLListItem -Text "Domain Controllers with Missing Objects: ", $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.MissingObjectDC.Count -FontSize 10pt -FontWeight normal, bold
                #New-HTMLListItem -Text "Domain Controllers with Missing Objects in Global Catalog (Reverse Lookup): ", $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.MissingAtSourceDC.Count -FontSize 10pt -FontWeight normal, bold
                New-HTMLListItem -Text "Domain Controllers with Wrong GUID Objects: ", $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.WrongGuidD.Count -FontSize 10pt -FontWeight normal, bold
                New-HTMLListItem -Text "Errors during scan: ", $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.Errors.Count -FontSize 10pt -FontWeight normal, bold
            } -FontSize 10pt
        }

        New-HTMLText -Text @(
            "While it's possible to have some missing objects, it should be investigated why that is. ",
            "We also ignore objects that were modified in the last 24 hours to avoid false positives, and that don't exists in the Global Catalog on any given domain controller."
            #"Those objects are shown in the Ignored Objects section, but they are not considered as missing or wrong GUID objects."
            #"However you can investigate them further if needed."
        ) -FontSize 10pt
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
                        New-HTMLSection -HeaderText "Domain details" {
                            New-HTMLPanel {
                                New-HTMLText -Text "Domain: ", $Domain -FontWeight normal, bold
                                New-HTMLText -Text "Source Domain Controller: ", $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain]['Summary'].'SourceServer' -FontWeight normal, bold
                            } -Invisible
                            New-HTMLPanel {
                                New-HTMLText -Text "Missing Unique Objects: " -Color Black -FontWeight bold
                                New-HTMLList {
                                    foreach ($Unique in $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.UniqueMissing) {
                                        New-HTMLListItem -Text $Unique -Color Black, Red -FontWeight normal, bold
                                    }
                                }
                            } -Invisible
                            New-HTMLPanel {
                                New-HTMLText -Text "Wrong GUID Unique Objects: " -Color Black -FontWeight bold
                                New-HTMLList {
                                    foreach ($Unique in $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Summary.UniqueWrongGuid) {
                                        New-HTMLListItem -Text $Unique -Color Black, Red -FontWeight normal, bold
                                    }
                                }
                            } -Invisible
                        }
                        New-HTMLSection -HeaderText "Missing Objects in $Domain per Domain Controller" {
                            $Data = foreach ($Key in  $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Keys) {
                                if ($Key -eq 'Summary') {
                                    continue
                                }
                                $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain][$Key].Missing
                            }
                            New-HTMLTable -DataTable $Data -Filtering {

                            } -IncludeProperty 'GlobalCatalog', 'Domain', 'Type', 'DistinguishedName', 'Name', 'ObjectClass', 'WhenCreated', 'WhenChanged' -ScrollX
                        }
                        # New-HTMLSection -HeaderText "Missing Objects in $Domain per Global Catalog (Reverse Lookup)" {
                        #     $Data = foreach ($Key in  $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Keys) {
                        #         if ($Key -eq 'Summary') {
                        #             continue
                        #         }
                        #         $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain][$Key].MissingAtSource
                        #     }
                        #     New-HTMLTable -DataTable $Data -Filtering -ScrollX {

                        #     } -IncludeProperty 'GlobalCatalog', 'Domain', 'Type', 'DistinguishedName', 'Name', 'ObjectClass', 'WhenCreated', 'WhenChanged', 'ObjectGuid'
                        # }
                        New-HTMLSection -HeaderText "Wrong GUID Objects in $Domain per Domain Controller" {
                            $Data = foreach ($Key in  $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Keys) {
                                if ($Key -eq 'Summary') {
                                    continue
                                }
                                $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain][$Key].WrongGuid
                            }
                            New-HTMLTable -DataTable $Data -Filtering -ScrollX {

                            } -IncludeProperty 'GlobalCatalog', 'Domain', 'Type', 'DistinguishedName', 'Name', 'ObjectClass', 'WhenCreated', 'WhenChanged', 'ObjectGuid', 'NewDistinguishedName', 'SourceObjectName', 'SourceObjectDN', 'SourceObjectGuid', 'SourceObjectWhenCreated', 'SourceObjectWhenChanged'
                        }
                        New-HTMLSection -HeaderText "Errors during scan in $Domain per Domain Controller" {
                            $Data = foreach ($Key in  $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain].Keys) {
                                if ($Key -eq 'Summary') {
                                    continue
                                }
                                $Script:Reporting['GlobalCatalogComparison']['Data'][$Domain][$Key].Errors
                            }
                            New-HTMLTable -DataTable $Data -Filtering -ScrollX {

                            } -IncludeProperty 'GlobalCatalog', 'Domain', 'Object', 'Error'
                        }
                    }
                }
            }
        }
    }
}