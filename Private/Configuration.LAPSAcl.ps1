$Script:ConfigurationLAPSACL = [ordered] @{
    Name       = 'LAPS ACL'
    Enabled    = $true
    Execute    = {
        Get-WinADComputerACLLAPS -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    }
    Processing = {
        foreach ($Object in $Script:Reporting['LAPSACL']['Data']) {
            if ($Object.Enabled) {
                $Script:Reporting['LAPSACL']['Variables']['ComputersEnabled']++
                if ($Object.LapsACL) {
                    $Script:Reporting['LAPSACL']['Variables']['LapsACL']++
                    if ($Object.OperatingSystem -like "Windows Server*") {
                        $Script:Reporting['LAPSACL']['Variables']['LapsACLOKServer']++
                    } elseif ($Object.OperatingSystem -notlike "Windows Server*" -and $Object.OperatingSystem -like "Windows*") {
                        $Script:Reporting['LAPSACL']['Variables']['LapsACLOKClient']++
                    }
                } else {
                    if ($Object.IsDC -eq $false) {
                        $Script:Reporting['LAPSACL']['Variables']['LapsACLNot']++
                        if ($Object.OperatingSystem -like "Windows Server*") {
                            $Script:Reporting['LAPSACL']['Variables']['LapsACLNotServer']++
                        } elseif ($Object.OperatingSystem -notlike "Windows Server*" -and $Object.OperatingSystem -like "Windows*") {
                            $Script:Reporting['LAPSACL']['Variables']['LapsACLNotClient']++
                        }
                    }
                }

                # Windows LAPS ACL coverage (only for Windows OS)
                if ($Object.OperatingSystem -like "Windows*") {
                    if ($Object.WindowsLAPSACL) {
                        $Script:Reporting['LAPSACL']['Variables']['WindowsLAPSACL']++
                        if ($Object.OperatingSystem -like "Windows Server*") {
                            $Script:Reporting['LAPSACL']['Variables']['WindowsLAPSACLOKServer']++
                        } elseif ($Object.OperatingSystem -notlike "Windows Server*") {
                            $Script:Reporting['LAPSACL']['Variables']['WindowsLAPSACLOKClient']++
                        }
                    } else {
                        $Script:Reporting['LAPSACL']['Variables']['WindowsLAPSACLNot']++
                        if ($Object.OperatingSystem -like "Windows Server*") {
                            $Script:Reporting['LAPSACL']['Variables']['WindowsLAPSACLNotServer']++
                        } elseif ($Object.OperatingSystem -notlike "Windows Server*") {
                            $Script:Reporting['LAPSACL']['Variables']['WindowsLAPSACLNotClient']++
                        }
                    }
                }

                # DC DSRM windows LAPS ACL support
                if ($Object.IsDC -eq $true) {
                    if ($Object.WindowsLAPSEncryptedDSRMPassword) {
                        $Script:Reporting['LAPSACL']['Variables']['DCsWithDSRMWindowsLAPSACL']++
                    } else {
                        $Script:Reporting['LAPSACL']['Variables']['DCsWithoutDSRMWindowsLAPSACL']++
                    }
                }
            } else {
                $Script:Reporting['LAPSACL']['Variables']['ComputersDisabled']++
            }
        }
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on detecting whether computer has ability to read/write to LAPS properties in Active Directory. "
            "Often for many reasons such as broken ACL inheritance or not fully implemented SELF write access to LAPS - LAPS is implemented only partially. "
            "This means while IT may be thinking that LAPS should be functioning properly - the computer itself may not have rights to write password back to AD, making LAPS not functional. "

        ) -FontSize 10pt -LineBreak
        New-HTMLText -Text "Notes on applicability: " -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Legacy LAPS does not apply to Domain Controllers (no local SAM)."
            New-HTMLListItem -Text "Windows LAPS applies to DSRM on Domain Controllers; ensure ACLs cover ms-LAPS-EncryptedDSRMPassword."
            New-HTMLListItem -Text 'Computer Service accounts such as AZUREADSSOACC$ are not applicable.'
        } -FontSize 10pt
        New-HTMLText -Text 'Everything else (Windows members) should have proper Legacy LAPS or Windows LAPS ACLs for the computer to provide data.' -FontSize 10pt
        New-HTMLText -Text "At-a-glance Windows LAPS ACL counts:" -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Windows LAPS ACL OK: ", $($Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACL) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Windows LAPS ACL Not OK: ", $($Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACLNot) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "DCs with DSRM (Windows LAPS ACL): ", $($Script:Reporting['LAPSACL']['Variables'].DCsWithDSRMWindowsLAPSACL) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "DCs without DSRM (Windows LAPS ACL): ", $($Script:Reporting['LAPSACL']['Variables'].DCsWithoutDSRMWindowsLAPSACL) -Color None, BlueMarguerite -FontWeight normal, bold
        } -FontSize 10pt
    }
    Variables  = @{
        ComputersEnabled  = 0
        ComputersDisabled = 0
        LapsACL           = 0
        LapsACLNot        = 0
        LapsACLOKServer   = 0
        LapsACLOKClient   = 0
        LapsACLNotServer  = 0
        LapsACLNotClient  = 0

        # Windows LAPS ACL
        WindowsLAPSACL            = 0
        WindowsLAPSACLNot         = 0
        WindowsLAPSACLOKServer    = 0
        WindowsLAPSACLOKClient    = 0
        WindowsLAPSACLNotServer   = 0
        WindowsLAPSACLNotClient   = 0

        # DC/DSRM ACL coverage
        DCsWithDSRMWindowsLAPSACL    = 0
        DCsWithoutDSRMWindowsLAPSACL = 0
    }
    Solution   = {
        if ($Script:Reporting['LAPSACL']['Data']) {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['LAPSACL']['Summary']
                }
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartBarOptions -Type barStacked
                        New-ChartLegend -Names 'Enabled', 'Disabled' -Color SpringGreen, Salmon
                        New-ChartBar -Name 'Computers' -Value $Script:Reporting['LAPSACL']['Variables'].ComputersEnabled, $Script:Reporting['LAPSACL']['Variables'].ComputersDisabled
                        # New-ChartAxisY -LabelMaxWidth 300 -Show
                    } -Title 'Active Computers' -TitleAlignment center
                }
            }
            New-HTMLSection -HeaderText 'General statistics' -CanCollapse {
                # Left column: high-level coverage
                New-HTMLPanel {
                    New-HTMLCarousel -Height auto -Loop -AutoPlay {
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'Computers Enabled' -Value $Script:Reporting['LAPSACL']['Variables'].ComputersEnabled
                                New-ChartPie -Name 'Computers Disabled' -Value $Script:Reporting['LAPSACL']['Variables'].ComputersDisabled
                            } -Title "Enabled vs Disabled All Computer Objects"
                        }
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'LAPS ACL OK' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACL
                                New-ChartPie -Name 'LAPS ACL Not OK' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLNot
                            } -Title "LAPS ACL OK vs Not OK"
                        }
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'Windows LAPS ACL OK' -Value $Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACL
                                New-ChartPie -Name 'Windows LAPS ACL Not OK' -Value $Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACLNot
                            } -Title "Windows LAPS ACL OK vs Not OK"
                        }
                    }
                }
                # Right column: breakdowns by type + DCs
                New-HTMLPanel {
                    New-HTMLCarousel -Height auto -Loop -AutoPlay {
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'LAPS ACL OK - Server' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLOKServer -Color SpringGreen
                                New-ChartPie -Name 'LAPS ACL OK - Client' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLOKClient -Color LimeGreen
                                New-ChartPie -Name 'LAPS ACL Not OK - Server' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLNotServer -Color Salmon
                                New-ChartPie -Name 'LAPS ACL Not OK - Client' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLNotClient -Color Red
                            } -Title "LAPS ACL OK vs Not OK by Computer Type"
                        }
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'Windows LAPS ACL OK - Server' -Value $Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACLOKServer -Color SpringGreen
                                New-ChartPie -Name 'Windows LAPS ACL OK - Client' -Value $Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACLOKClient -Color LimeGreen
                                New-ChartPie -Name 'Windows LAPS ACL Not OK - Server' -Value $Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACLNotServer -Color Salmon
                                New-ChartPie -Name 'Windows LAPS ACL Not OK - Client' -Value $Script:Reporting['LAPSACL']['Variables'].WindowsLAPSACLNotClient -Color Red
                            } -Title "Windows LAPS ACL OK vs Not OK by Computer Type"
                        }
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'DCs with DSRM (Windows LAPS ACL)' -Value $Script:Reporting['LAPSACL']['Variables'].DCsWithDSRMWindowsLAPSACL -Color '#94ffc8'
                                New-ChartPie -Name 'DCs without DSRM (Windows LAPS ACL)' -Value $Script:Reporting['LAPSACL']['Variables'].DCsWithoutDSRMWindowsLAPSACL -Color 'Salmon'
                            } -Title "Windows LAPS DSRM ACL Coverage (DCs)"
                        }
                    }
                }
            }
            New-HTMLSection -Name 'LAPS ACL Summary' {
                New-HTMLTable -DataTable $Script:Reporting['LAPSACL']['Data'] -Filtering {
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'LapsACL' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'LapsExpirationACL' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
                    } -BackgroundColor LimeGreen -HighlightHeaders LapsACL, LapsExpirationACL
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'LapsACL' -ComparisonType string -Operator eq -Value $false
                        New-HTMLTableCondition -Name 'LapsExpirationACL' -ComparisonType string -Operator eq -Value $false
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
                    } -BackgroundColor Alizarin -HighlightHeaders LapsACL, LapsExpirationACL

                    New-HTMLTableCondition -Name 'WindowsLAPSACL' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen
                    New-HTMLTableCondition -Name 'WindowsLAPSExpirationACL' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen
                    New-HTMLTableCondition -Name 'WindowsLAPSEncryptedPassword' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'WindowsLAPSEncryptedDSRMPassword' -ComparisonType string -Operator eq -Value $true
                    } -BackgroundColor LimeGreen -HighlightHeaders WindowsLAPSEncryptedDSRMPassword
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'WindowsLAPSEncryptedDSRMPasswordHistory' -ComparisonType string -Operator eq -Value $true
                    } -BackgroundColor LimeGreen -HighlightHeaders WindowsLAPSEncryptedDSRMPasswordHistory

                    New-HTMLTableCondition -Name 'WindowsLAPSACL' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'WindowsLAPSExpirationACL' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'WindowsLAPSEncryptedPassword' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'WindowsLAPSEncryptedDSRMPassword' -ComparisonType string -Operator eq -Value $false
                    } -BackgroundColor Alizarin -HighlightHeaders WindowsLAPSEncryptedDSRMPassword
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'WindowsLAPSEncryptedDSRMPasswordHistory' -ComparisonType string -Operator eq -Value $false
                    } -BackgroundColor Alizarin -HighlightHeaders WindowsLAPSEncryptedDSRMPasswordHistory

                    New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true -BackgroundColor BlizzardBlue -HighlightHeaders LapsACL, LapsExpirationACL
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true -BackgroundColor BlizzardBlue -HighlightHeaders WindowsLAPSACL, WindowsLAPSExpirationACL, WindowsLAPSEncryptedPassword, WindowsLAPSEncryptedDSRMPassword, WindowsLAPSEncryptedDSRMPasswordHistory
                }
            }
            if ($Script:Reporting['LAPSACL']['WarningsAndErrors']) {
                New-HTMLSection -Name 'Warnings & Errors to Review' {
                    New-HTMLTable -DataTable $Script:Reporting['LAPSACL']['WarningsAndErrors'] -Filtering {
                        New-HTMLTableCondition -Name 'Type' -Value 'Warning' -BackgroundColor SandyBrown -ComparisonType string -Row
                        New-HTMLTableCondition -Name 'Type' -Value 'Error' -BackgroundColor Salmon -ComparisonType string -Row
                    } -PagingOptions 10, 20, 30, 40, 50
                }
            }
        }
    }
}
