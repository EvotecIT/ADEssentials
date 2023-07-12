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
        New-HTMLText -Text "Following computer resources are exempt from LAPS: " -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Domain Controllers and Read Only Domain Controllers"
            New-HTMLListItem -Text 'Computer Service accounts such as AZUREADSSOACC$'
        } -FontSize 10pt
        New-HTMLText -Text 'Everything else should have proper LAPS ACL for the computer to provide data.' -FontSize 10pt
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
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Computers Enabled' -Value $Script:Reporting['LAPSACL']['Variables'].ComputersEnabled
                        New-ChartPie -Name 'Computers Disabled' -Value $Script:Reporting['LAPSACL']['Variables'].ComputersDisabled
                    } -Title "Enabled vs Disabled All Computer Objects"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'LAPS ACL OK' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACL
                        New-ChartPie -Name 'LAPS ACL Not OK' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLNot
                    } -Title "LAPS ACL OK vs Not OK"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'LAPS ACL OK - Server' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLOKServer -Color SpringGreen
                        New-ChartPie -Name 'LAPS ACL OK - Client' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLOKClient -Color LimeGreen
                        New-ChartPie -Name 'LAPS ACL Not OK - Server' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLNotServer -Color Salmon
                        New-ChartPie -Name 'LAPS ACL Not OK - Client' -Value $Script:Reporting['LAPSACL']['Variables'].LapsACLNotClient -Color Red
                    } -Title "LAPS ACL OK vs Not OK by Computer Type"
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

                    New-HTMLTableCondition -Name 'WindowsLAPSACL' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'WindowsLAPSExpirationACL' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin
                    New-HTMLTableCondition -Name 'WindowsLAPSEncryptedPassword' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin

                    New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true -BackgroundColor BlizzardBlue -HighlightHeaders LapsACL, LapsExpirationACL
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true -BackgroundColor BlizzardBlue -HighlightHeaders WindowsLAPSACL, WindowsLAPSExpirationACL, WindowsLAPSEncryptedPassword
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