$Script:ConfigurationLAPSAndBitlocker = [ordered] @{
    Name       = 'LAPS and BITLOCKER'
    Enabled    = $true
    Execute    = {
        Get-WinADBitlockerLapsSummary
    }
    Processing = {
        $v = $Script:Reporting['LapsAndBitLocker']['Variables']
        foreach ($Object in $Script:Reporting['LapsAndBitLocker']['Data']) {
            if ($Object.Enabled) {
                $v.ComputersEnabled++
            } else {
                $v.ComputersDisabled++
            }

            if ($Object.PSObject.Properties.Name -contains 'Encrypted') {
                if ($Object.Encrypted -eq $true) {
                    $v.BitLockerEncrypted++
                } else {
                    $v.BitLockerNotEncrypted++
                }
            }

            $isWindowsOS = ($Object.System -like 'Windows*')

            if ($Object.IsDC -eq $false -and $isWindowsOS) {
                $hasLegacy = ($Object.Laps -eq $true)
                $hasWin    = ($Object.WindowsLaps -eq $true)
                if ($hasLegacy -and -not $hasWin) {
                    $v.MigrationLegacyOnly++
                } elseif (-not $hasLegacy -and $hasWin) {
                    $v.MigrationWindowsOnly++
                } elseif ($hasLegacy -and $hasWin) {
                    $v.MigrationBoth++
                } else {
                    $v.MigrationNeither++
                }
            }

            if ($Object.IsDC -eq $true) {
                if ($Object.WindowsLaps -eq $true) {
                    $v.DCsWithDSRMWindowsLAPS++
                } else {
                    $v.DCsWithoutDSRMWindowsLAPS++
                }
            }
        }
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report combines LAPS (Legacy and Windows LAPS) with BitLocker coverage to provide a single view."
            "On member servers/workstations, Windows LAPS covers the local Administrator account."
            "On Domain Controllers, Windows LAPS applies to the DSRM account only."
        ) -FontSize 10pt -LineBreak
        New-HTMLText -Text "Quick stats:" -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Enabled computers: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].ComputersEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Disabled computers: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].ComputersDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "BitLocker Encrypted: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].BitLockerEncrypted) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "BitLocker Not Encrypted: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].BitLockerNotEncrypted) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Migration (non-DC Windows) - Legacy only: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].MigrationLegacyOnly) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Migration (non-DC Windows) - Windows LAPS only: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].MigrationWindowsOnly) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Migration (non-DC Windows) - Both: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].MigrationBoth) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Migration (non-DC Windows) - Neither: ", $($Script:Reporting['LapsAndBitLocker']['Variables'].MigrationNeither) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Domain Controllers with DSRM (Windows LAPS): ", $($Script:Reporting['LapsAndBitLocker']['Variables'].DCsWithDSRMWindowsLAPS) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Domain Controllers without DSRM (Windows LAPS): ", $($Script:Reporting['LapsAndBitLocker']['Variables'].DCsWithoutDSRMWindowsLAPS) -Color None, BlueMarguerite -FontWeight normal, bold
        } -FontSize 10pt
    }
    Variables  = @{
        ComputersEnabled           = 0
        ComputersDisabled          = 0
        BitLockerEncrypted         = 0
        BitLockerNotEncrypted      = 0
        MigrationLegacyOnly        = 0
        MigrationWindowsOnly       = 0
        MigrationBoth              = 0
        MigrationNeither           = 0
        DCsWithDSRMWindowsLAPS     = 0
        DCsWithoutDSRMWindowsLAPS  = 0
    }
    Solution   = {
        if ($Script:Reporting['LapsAndBitLocker']['Data']) {
            # Top summary section (no charts here to avoid duplicates)
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['LapsAndBitLocker']['Summary']
                }
            }

            # General statistics as two side-by-side carousels (like LAPS summary)
            New-HTMLSection -HeaderText 'General statistics' -CanCollapse {
                # Left column: enabled/disabled + BitLocker
                New-HTMLPanel {
                    New-HTMLCarousel -Height auto -Loop -AutoPlay {
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'Computers Enabled' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].ComputersEnabled
                                New-ChartPie -Name 'Computers Disabled' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].ComputersDisabled
                            } -Title 'Enabled vs Disabled All Computer Objects'
                        }
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'BitLocker Encrypted' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].BitLockerEncrypted -Color '#94ffc8'
                                New-ChartPie -Name 'Not Encrypted' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].BitLockerNotEncrypted -Color 'Salmon'
                            } -Title 'BitLocker Coverage'
                        }
                    }
                }
                # Right column: LAPS migration + DC DSRM
                New-HTMLPanel {
                    New-HTMLCarousel -Height auto -Loop -AutoPlay {
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'Legacy LAPS only' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].MigrationLegacyOnly -Color '#9ecae1'
                                New-ChartPie -Name 'Windows LAPS only' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].MigrationWindowsOnly -Color '#6baed6'
                                New-ChartPie -Name 'Both' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].MigrationBoth -Color '#31a354'
                                New-ChartPie -Name 'Neither' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].MigrationNeither -Color '#fd8d3c'
                            } -Title 'LAPS Migration (Workstations/Servers)'
                        }
                        New-CarouselSlide -Height auto {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'DCs with DSRM (Windows LAPS)' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].DCsWithDSRMWindowsLAPS -Color '#94ffc8'
                                New-ChartPie -Name 'DCs without DSRM (Windows LAPS)' -Value $Script:Reporting['LapsAndBitLocker']['Variables'].DCsWithoutDSRMWindowsLAPS -Color 'Salmon'
                            } -Title 'Windows LAPS DSRM Coverage (DCs)'
                        }
                    }
                }
            }

            New-HTMLTable -DataTable $Script:Reporting['LapsAndBitLocker']['Data'] -Filtering {
                New-HTMLTableCondition -Name 'Encrypted' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Salmon
                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                New-HTMLTableCondition -Name 'LapsExpirationDays' -ComparisonType number -Operator lt -Value 0 -BackgroundColor BurntOrange -HighlightHeaders LapsExpirationDays, LapsExpirationTime -FailBackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin -HighlightHeaders LapsExpirationDays, LapsExpirationTime
                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Alizarin -HighlightHeaders LastLogonDays, LastLogonDate -FailBackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 300 -BackgroundColor Orange -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 360 -BackgroundColor Alizarin -HighlightHeaders PasswordLastSet, PasswordLastChangedDays

                New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true -BackgroundColor BlizzardBlue -HighlightHeaders IsDC, Laps, LapsExpirationDays, LapsExpirationTime

                New-HTMLTableCondition -Name 'WindowsLapsExpirationDays' -ComparisonType number -Operator lt -Value 0 -BackgroundColor BurntOrange -HighlightHeaders WindowsLapsExpirationDays, WindowsLapsExpirationTime -FailBackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'WindowsLaps' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                New-HTMLTableCondition -Name 'WindowsLaps' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin -HighlightHeaders WindowsLaps, WindowsLapsExpirationDays, WindowsLapsExpirationTime
                New-HTMLTableCondition -Name 'WindowsLaps' -ComparisonType string -Operator eq -Value "" -BackgroundColor BlizzardBlue -HighlightHeaders WindowsLaps, WindowsLapsExpirationDays, WindowsLapsExpirationTime
                New-HTMLTableConditionGroup -Logic AND {
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true
                    New-HTMLTableCondition -Name 'WindowsLaps' -ComparisonType string -Operator eq -Value $true
                } -BackgroundColor LimeGreen -HighlightHeaders WindowsLaps
                New-HTMLTableConditionGroup -Logic AND {
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true
                    New-HTMLTableCondition -Name 'WindowsLaps' -ComparisonType string -Operator eq -Value $false
                } -BackgroundColor Alizarin -HighlightHeaders WindowsLaps
             }
        }
    }
}
