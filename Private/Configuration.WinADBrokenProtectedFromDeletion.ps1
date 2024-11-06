$Script:ShowWinADBrokenProtectedFromDeletion = [ordered] @{
    Name       = 'Protected From Deletion Status'
    Enabled    = $true
    Execute    = {
        Get-WinADBrokenProtectedFromDeletion -Type All
    }
    Processing = {
        foreach ($Object in $Script:Reporting['BrokenProtectedFromDeletion']['Data']) {
            if ($Object.HasBrokenPermissions) {
                $Script:Reporting['BrokenProtectedFromDeletion']['Variables']['ObjectsBrokenTotal']++
                $Script:Reporting['BrokenProtectedFromDeletion']['Variables']['ObjectsBrokenByClass'][$Object.ObjectClass]++
                $Script:Reporting['BrokenProtectedFromDeletion']['Variables']['ObjectsBrokenByDomain'][$Object.Domain]++
            }
            $Script:Reporting['BrokenProtectedFromDeletion']['Variables']['ObjectsTotal']++
            $Script:Reporting['BrokenProtectedFromDeletion']['Variables']['ObjectsByClass'][$Object.ObjectClass]++
            $Script:Reporting['BrokenProtectedFromDeletion']['Variables']['ObjectsByDomain'][$Object.Domain]++
        }
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on Active Directory objects that have inconsistent protection from accidental deletion settings. ",
            "It helps identify objects where the ProtectedFromAccidentalDeletion flag doesn't match the actual ACL settings, ",
            "which could put critical objects at risk of accidental deletion."
        ) -FontSize 10pt -LineBreak

        New-HTMLText -Text @(
            "Here's a summary of findings:"
        ) -FontSize 10pt

        New-HTMLList -Type Unordered {
            New-HTMLListItem -Text "Total objects scanned: ", $($Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsTotal) -FontWeight normal, bold
            New-HTMLListItem -Text "Objects with broken protection: ", $($Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenTotal) -FontWeight normal, bold -Color None, Red

            New-HTMLListItem -Text "Broken objects by type:" -FontWeight bold {
                New-HTMLList -Type Unordered {
                    foreach ($Class in $Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenByClass.Keys) {
                        New-HTMLListItem -Text "$Class objects: ", $($Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenByClass[$Class]) -FontWeight normal, bold
                    }
                }
            }
            New-HTMLListItem -Text "Broken objects by domain:" -FontWeight bold {
                New-HTMLList -Type Unordered {
                    foreach ($Domain in $Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenByDomain.Keys) {
                        New-HTMLListItem -Text "$($Domain): ", $($Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenByDomain[$Domain]) -FontWeight normal, bold
                    }
                }
            }
        } -FontSize 10pt
    }
    Variables  = @{
        ObjectsTotal          = 0
        ObjectsBrokenTotal    = 0
        ObjectsByClass        = @{}
        ObjectsBrokenByClass  = @{}
        ObjectsByDomain       = @{}
        ObjectsBrokenByDomain = @{}
    }
    Solution   = {
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                $Script:Reporting['BrokenProtectedFromDeletion']['Summary']
            }
            New-HTMLPanel {
                New-HTMLChart -Title 'Objects Protection Status' {
                    New-ChartBarOptions -Type barStacked
                    New-ChartLegend -Name 'Protected', 'Broken Protection' -Color Green, Red
                    foreach ($Class in $Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsByClass.Keys) {
                        $Protected = $Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsByClass[$Class] -
                        $Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenByClass[$Class]
                        $Broken = $Script:Reporting['BrokenProtectedFromDeletion']['Variables'].ObjectsBrokenByClass[$Class]
                        New-ChartBar -Name $Class -Value $Protected, $Broken
                    }
                } -TitleAlignment center
            }
        }
        New-HTMLSection -Name 'Objects with Broken Protection' {
            New-HTMLTable -DataTable $Script:Reporting['BrokenProtectedFromDeletion']['Data'] -Filtering {
                New-HTMLTableCondition -Name 'HasBrokenPermissions' -Value $true -Operator eq -BackgroundColor Salmon -FailBackgroundColor MintCream
            } -PagingOptions 7, 15, 30, 45, 60
        }
        New-HTMLSection -Name 'Steps to fix - Protected From Deletion' {
            New-HTMLContainer {
                New-HTMLSpanStyle -FontSize 10pt {
                    New-HTMLWizard {
                        New-HTMLWizardStep -Name 'Prepare environment' {
                            New-HTMLText -Text "To be able to execute actions in automated way please install required modules. The module will be installed from PowerShell Gallery."
                            New-HTMLCodeBlock -Code {
                                Install-Module ADEssentials -Force
                                Import-Module ADEssentials -Force
                            } -Style powershell
                            New-HTMLText -Text "Using force makes sure newest version is downloaded from PowerShellGallery regardless of what is currently installed."
                        }
                        New-HTMLWizardStep -Name 'Prepare report' {
                            New-HTMLText -Text "To generate a new report before proceeding with fixes, use:"
                            New-HTMLCodeBlock -Code {
                                Get-WinADBrokenProtectedFromDeletion -Type All -ReturnBrokenOnly | Format-Table
                            }
                            New-HTMLText -Text "This will show you all objects with their current protection status. Review the output before proceeding with fixes."
                        }
                        New-HTMLWizardStep -Name 'Test fixes' {
                            New-HTMLText -Text "First, test the repair process using -WhatIf to see what would be changed:"
                            New-HTMLCodeBlock -Code {
                                Repair-WinADBrokenProtectedFromDeletion -Type All -WhatIf -LimitProcessing 5
                            }
                            New-HTMLText -Text "Review the output to ensure the correct objects will be modified."
                        }
                        New-HTMLWizardStep -Name 'Apply fixes' {
                            New-HTMLText -Text "Once you've verified the changes, run the repair command without -WhatIf:"
                            New-HTMLCodeBlock -Code {
                                Repair-WinADBrokenProtectedFromDeletion -Type All -LimitProcessing 5 -Verbose
                            }
                            New-HTMLText -TextBlock {
                                "The command will process objects in batches (5 at a time by default). "
                                "Increase the LimitProcessing parameter value once you're confident in the changes."
                            }
                        }
                        New-HTMLWizardStep -Name 'Verify changes' {
                            New-HTMLText -Text "After applying fixes, verify the changes by running another report:"
                            New-HTMLCodeBlock -Code {
                                Get-WinADBrokenProtectedFromDeletion -Type All -ReturnBrokenOnly | Format-Table
                            }
                            New-HTMLText -Text "The report should show fewer or no objects with broken protection settings."
                        }
                    } -RemoveDoneStepOnNavigateBack -Theme arrows -ToolbarButtonPosition center -EnableAllAnchors
                }
            }
        }
    }
}