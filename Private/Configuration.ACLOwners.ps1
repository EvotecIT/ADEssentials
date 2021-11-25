$Script:ConfigurationACLOwners = [ordered] @{
    Name       = 'Forest ACL Owners'
    Enabled    = $true
    Execute    = {
        Get-WinADACLForest -Owner #-ExcludeOwnerType Administrative, WellKnownAdministrative
    }
    Processing = {
        $Script:Reporting['ForestACLOwners']['Variables']['OwnersAdministrative'] = 0
        $Script:Reporting['ForestACLOwners']['Variables']['OwnersWellKnownAdministrative'] = 0
        $Script:Reporting['ForestACLOwners']['Variables']['OwnersUnknown'] = 0
        $Script:Reporting['ForestACLOwners']['Variables']['OwnersNotAdministrative'] = 0
        $Script:Reporting['ForestACLOwners']['Variables']['RequiringFix'] = 0
        $Script:Reporting['ForestACLOwners']['Variables']['Total'] = 0
        $Script:Reporting['ForestACLOwners']['LimitedData'] = foreach ($Object in $Script:Reporting['ForestACLOwners']['Data']) {
            if ($Object.OwnerType -eq 'Administrative') {
                $Script:Reporting['ForestACLOwners']['Variables']['OwnersAdministrative']++
            } elseif ($Object.OwnerType -eq 'WellKnownAdministrative') {
                $Script:Reporting['ForestACLOwners']['Variables']['OwnersWellKnownAdministrative']++
            } elseif ($Object.OwnerType -eq 'NotAdministrative') {
                $Script:Reporting['ForestACLOwners']['Variables']['OwnersNotAdministrative']++
                $Script:Reporting['ForestACLOwners']['Variables']['RequiringFix']++
                $Object
            } else {
                $Script:Reporting['ForestACLOwners']['Variables']['OwnersUnknown']++
                $Script:Reporting['ForestACLOwners']['Variables']['RequiringFix']++
                $Object
            }
            $Script:Reporting['ForestACLOwners']['Variables']['Total']++
        }
    }
    Summary    = {
        New-HTMLText -TextBlock {
            "This report focuses on finding non-administrative owners owning an object in Active Directory. "
            "It goes thru every single computer, user, group, organizational unit (and other) object and find if the owner is "
            "Administrative (Domain Admins/Enterprise Admins)"
            " or "
            "WellKnownAdministrative (SYSTEM account or similar)"
            ". If it's not any of that it exposes those objects to be fixed."
        } -FontSize 10pt -LineBreak

        New-HTMLList -Type Unordered {
            New-HTMLListItem -Text 'Forest ACL Owners in Total: ', $Script:Reporting['ForestACLOwners']['Variables']['Total'] -FontWeight normal, bold
            New-HTMLListItem -Text 'Forest ACL Owners ', 'Domain Admins / Enterprise Admins' , ' as Owner: ', $Script:Reporting['ForestACLOwners']['Variables']['OwnersAdministrative'] -FontWeight normal, bold, normal, bold
            New-HTMLListItem -Text 'Forest ACL Owners ', 'BUILTIN\Administrators / SYSTEM', ' as Owner: ', $Script:Reporting['ForestACLOwners']['Variables']['OwnersWellKnownAdministrative'] -FontWeight normal, bold, normal, bold
            New-HTMLListItem -Text "Forest ACL Owners requiring change: ", $Script:Reporting['ForestACLOwners']['Variables']['RequiringFix'] -FontWeight normal, bold {
                New-HTMLList -Type Unordered {
                    New-HTMLListItem -Text 'Not Administrative: ', $Script:Reporting['ForestACLOwners']['Variables']['OwnersNotAdministrative'] -FontWeight normal, bold
                    New-HTMLListItem -Text 'Unknown (deleted objects/old trusts): ', $Script:Reporting['ForestACLOwners']['Variables']['OwnersUnknown'] -FontWeight normal, bold
                }
            }
        } -FontSize 10pt

    }
    Variables  = @{

    }
    Solution   = {
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                & $Script:ConfigurationACLOwners['Summary']
            }
            New-HTMLPanel {
                New-HTMLChart {
                    New-ChartPie -Name 'Administrative Owners' -Value $Script:Reporting['ForestACLOwners']['Variables']['OwnersAdministrative'] -Color SpringGreen
                    New-ChartPie -Name 'WellKnown Administrative Owners' -Value $Script:Reporting['ForestACLOwners']['Variables']['OwnersWellKnownAdministrative'] -Color SpringGreen
                    New-ChartPie -Name 'Unknown Owners' -Value $Script:Reporting['ForestACLOwners']['Variables']['OwnersUnknown'] -Color BrilliantRose
                    New-ChartPie -Name 'Not Administrative Owners' -Value $Script:Reporting['ForestACLOwners']['Variables']['OwnersNotAdministrative'] -Color Salmon
                } -Title 'Forest ACL Owners' -TitleAlignment center
            }
        }
        New-HTMLSection -Name 'Forest ACL Owners' {
            #if ($Script:Reporting['ForestACLOwners']['Data']) {
            New-HTMLTable -DataTable $Script:Reporting['ForestACLOwners']['LimitedData'] -Filtering {
                #New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                #New-HTMLTableCondition -Name 'LapsExpirationDays' -ComparisonType number -Operator lt -Value 0 -BackgroundColor BurntOrange -HighlightHeaders LapsExpirationDays, LapsExpirationTime -FailBackgroundColor LimeGreen
                #New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin

                #New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin -HighlightHeaders LapsExpirationDays, LapsExpirationTime

                #New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Alizarin -HighlightHeaders LastLogonDays, LastLogonDate -FailBackgroundColor LimeGreen
                #New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                #New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 300 -BackgroundColor Orange -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                #New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 360 -BackgroundColor Alizarin -HighlightHeaders PasswordLastSet, PasswordLastChangedDays

                #New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                #New-HTMLTableCondition -Name 'PasswordExpired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
            }
            #}
        }
        if ($Script:Reporting['Settings']['HideSteps'] -eq $false) {
            New-HTMLSection -Name 'Steps to fix ownership of non-compliant objects in whole forest/domain' {
                New-HTMLContainer {
                    New-HTMLSpanStyle -FontSize 10pt {
                        New-HTMLWizard {
                            New-HTMLWizardStep -Name 'Prepare environment' {
                                New-HTMLText -Text "To be able to execute actions in automated way please install required modules. Those modules will be installed straight from Microsoft PowerShell Gallery."
                                New-HTMLCodeBlock -Code {
                                    Install-Module ADEssentials -Force
                                    Import-Module ADEssentials -Force
                                } -Style powershell
                                New-HTMLText -Text "Using force makes sure newest version is downloaded from PowerShellGallery regardless of what is currently installed. Once installed you're ready for next step."
                            }
                            New-HTMLWizardStep -Name 'Prepare a report (up to date)' {
                                New-HTMLText -Text "Depending when this report was run you may want to prepare new report before proceeding with removal. To generate new report please use:"
                                New-HTMLCodeBlock -Code {
                                    Invoke-ADEssentials -FilePath $Env:UserProfile\Desktop\ADEssentials-ForestACLOwners.html -Verbose -Type ForestACLOwners
                                }
                                New-HTMLText -TextBlock {
                                    "When executed it will take a while to generate all data and provide you with new report depending on size of environment."
                                    "Once confirmed that data is still showing issues and requires fixing please proceed with next step."
                                }
                                New-HTMLText -Text "Alternatively if you prefer working with console you can run: "
                                New-HTMLCodeBlock -Code {
                                    $ForestACLOwner = Get-WinADACLForest -Owner -Verbose -ExcludeOwnerType Administrative, WellKnownAdministrative
                                    $ForestACLOwner | Format-Table
                                }
                                New-HTMLText -Text "It includes all the data as you see in table above including all the owner types (including administrative and wellknownadministrative)"

                            }
                            New-HTMLWizardStep -Name 'Fix Owners' {
                                New-HTMLText -Text @(
                                    "Following command when executed, finds all object owners within Forest/Domain that doesn't match WellKnownAdministrative (SYSTEM/BUIILTIN\Administrator) or Administrative (Domain Admins/Enterprise Admins) ownership. "
                                    "Once it finds those non-compliant owners it replaces them with Domain Admins for a given domain. It doesn't change/modify compliant owners."
                                )

                                New-HTMLText -Text "Make sure when running it for the first time to run it with ", "WhatIf", " parameter as shown below to prevent accidental removal." -FontWeight normal, bold, normal -Color Black, Red, Black

                                New-HTMLCodeBlock -Code {
                                    Set-WinADForestACLOwner -WhatIf -Verbose -IncludeOwnerType 'NotAdministrative', 'Unknown'
                                }
                                New-HTMLText -TextBlock {
                                    "Alternatively for multi-domain scenario, if you have limited Domain Admin credentials to a single domain please use following command: "
                                }
                                New-HTMLCodeBlock -Code {
                                    Set-WinADForestACLOwner -WhatIf -Verbose -IncludeOwnerType 'NotAdministrative', 'Unknown' -IncludeDomains 'YourDomainYouHavePermissionsFor'
                                }
                                New-HTMLText -TextBlock {
                                    "After execution please make sure there are no errors, make sure to review provided output, and confirm that what is about to be changed matches expected data. "
                                } -LineBreak
                                New-HTMLText -Text "Once happy with results please follow with command (this will start replacement of owners process): " -LineBreak -FontWeight bold
                                New-HTMLText -TextBlock {
                                    "This command when executed sets new owner only on first X non-compliant AD objects (computers/users/organizational units/contacts etc.). "
                                    "Use LimitProcessing parameter to prevent mass change and increase the counter when no errors occur. "
                                    "Repeat step above as much as needed increasing LimitProcessing count till there's nothing left. In case of any issues please review and action accordingly. "
                                }
                                New-HTMLCodeBlock -Code {
                                    Set-WinADForestACLOwner -Verbose -LimitProcessing 2 -IncludeOwnerType 'NotAdministrative', 'Unknown'
                                }
                                New-HTMLText -TextBlock {
                                    "Alternatively for multi-domain scenario, if you have limited Domain Admin credentials to a single domain please use following command: "
                                }
                                New-HTMLCodeBlock -Code {
                                    Set-WinADForestACLOwner -Verbose -LimitProcessing 2 -IncludeOwnerType 'NotAdministrative', 'Unknown'-IncludeDomains 'YourDomainYouHavePermissionsFor'
                                }
                            }
                        } -RemoveDoneStepOnNavigateBack -Theme arrows -ToolbarButtonPosition center -EnableAllAnchors
                    }
                }
            }
        }
        if ($Script:Reporting['ForestACLOwners']['WarningsAndErrors']) {
            New-HTMLSection -Name 'Warnings & Errors to Review' {
                New-HTMLTable -DataTable $Script:Reporting['ForestACLOwners']['WarningsAndErrors'] -Filtering {
                    New-HTMLTableCondition -Name 'Type' -Value 'Warning' -BackgroundColor SandyBrown -ComparisonType string -Row
                    New-HTMLTableCondition -Name 'Type' -Value 'Error' -BackgroundColor Salmon -ComparisonType string -Row
                }
            }
        }
    }
}