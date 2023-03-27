$Script:ConfigurationLAPS = [ordered] @{
    Name       = 'LAPS Summary'
    Enabled    = $true
    Execute    = {
        Get-WinADBitlockerLapsSummary -LapsOnly
    }
    Processing = {
        foreach ($Computer in $Script:Reporting['LAPS']['Data']) {
            $Script:Reporting['LAPS']['Variables']['ComputersTotal']++
            if ($Computer.Enabled) {
                $Script:Reporting['LAPS']['Variables']['ComputersEnabled']++
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersDisabled']++
            }
            if ($Computer.Laps) {
                $Script:Reporting['LAPS']['Variables']['ComputersLapsEnabled']++
            } else {
                if ($Computer.IsDC -eq $true) {
                    $Script:Reporting['LAPS']['Variables']['ComputersLapsNotApplicable']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersLapsDisabled']++
                }
            }
            if ($Computer.LapsExpirationDays -lt 0) {
                $Script:Reporting['LAPS']['Variables']['ComputersLapsExpired']++
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersLapsNotExpired']++
            }
            if ($Computer.LastLogonDays -gt 60) {
                $Script:Reporting['LAPS']['Variables']['ComputersInactive']++
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersActive']++
            }
            if ($Computer.LastLogonDays -lt 60 -and $Computer.Laps -eq $false -and $Computer.IsDC -eq $false) {
                $Script:Reporting['LAPS']['Variables']['ComputersActiveNoLaps']++
            } elseif ($Computer.LastLogonDays -lt 60 -and $Computer.Laps -eq $true -and $Computer.IsDC -eq $false) {
                $Script:Reporting['LAPS']['Variables']['ComputersActiveWithLaps']++
            }
            if ($Computer.System -like "Windows Server*") {
                $Script:Reporting['LAPS']['Variables']['ComputersServer']++
                if ($Computer.Enabled) {
                    $Script:Reporting['LAPS']['Variables']['ComputersServerEnabled']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersServerDisabled']++
                }
                if ($Computer.Laps) {
                    $Script:Reporting['LAPS']['Variables']['ComputersServerLapsEnabled']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersServerLapsDisabled']++
                }
            } elseif ($Computer.System -like "Windows 10*" -or $Computer.System -like "Windows 8*" -or $Computer.System -like "Windows 7*" -or $Computer.System -like "Windows 11*") {
                $Script:Reporting['LAPS']['Variables']['ComputersWorkstation']++
                if ($Computer.Enabled) {
                    $Script:Reporting['LAPS']['Variables']['ComputersWorkstationEnabled']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersWorkstationDisabled']++
                }
                if ($Computer.Laps) {
                    $Script:Reporting['LAPS']['Variables']['ComputersWorkstationLapsEnabled']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersWorkstationLapsDisabled']++
                }
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersOther']++
                if ($Computer.Enabled) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOtherEnabled']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersOtherDisabled']++
                }
                if ($Computer.Laps) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOtherLapsEnabled']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersOtherLapsDisabled']++
                }
            }
        }
    }
    Summary    = {

    }
    Variables  = @{}
    Solution   = {
        if ($Script:Reporting['LAPS']['Data']) {
            New-HTMLSection -HeaderText 'Summary statistics' -CanCollapse {
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Computers Enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersEnabled
                        New-ChartPie -Name 'Computers Disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersDisabled
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Servers' -Value $Script:Reporting['LAPS']['Variables'].ComputersServer
                        New-ChartPie -Name 'Clients' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstation
                        New-ChartPie -Name 'Non-Windows' -Value $Script:Reporting['LAPS']['Variables'].ComputersOther
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'LAPS Enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsEnabled -Color '#94ffc8'
                        New-ChartPie -Name 'LAPS Disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsDisabled -Color 'Salmon'
                        New-ChartPie -Name 'LAPS Not Applicable' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsNotApplicable -Color 'LightGray'
                    }
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'LAPS Expired' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsExpired
                        New-ChartPie -Name 'LAPS Not Expired' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsNotExpired
                    }
                }
            }
            New-HTMLSection -Invisible {
                New-HTMLSection -HeaderText 'Servers (Windows Server)' -CanCollapse {
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'Servers enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerEnabled
                            New-ChartPie -Name 'Servers disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerDisabled
                        }
                    }
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'LAPS enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerLapsEnabled -Color '#94ffc8'
                            New-ChartPie -Name 'LAPS disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerLapsDisabled -Color 'Salmon'
                            New-ChartPie -Name 'LAPS not applicable' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerLapsNotApplicable -Color 'LightGray'
                        }
                    }
                }
                New-HTMLSection -HeaderText 'Workstations (Windows Client)' -CanCollapse {
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'Clients enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationEnabled
                            New-ChartPie -Name 'Clients disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationDisabled
                        }
                    }
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'LAPS enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsEnabled -Color '#94ffc8'
                            New-ChartPie -Name 'LAPS disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsDisabled -Color 'Salmon'
                            New-ChartPie -Name 'LAPS not applicable' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsNotApplicable -Color 'LightGray'
                        }
                    }
                }
            }
            New-HTMLTable -DataTable $Script:Reporting['LAPS']['Data'] -Filtering {
                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                New-HTMLTableCondition -Name 'LapsExpirationDays' -ComparisonType number -Operator lt -Value 0 -BackgroundColor BurntOrange -HighlightHeaders LapsExpirationDays, LapsExpirationTime -FailBackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin

                New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin -HighlightHeaders LapsExpirationDays, LapsExpirationTime

                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Alizarin -HighlightHeaders LastLogonDays, LastLogonDate -FailBackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 300 -BackgroundColor Orange -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 360 -BackgroundColor Alizarin -HighlightHeaders PasswordLastSet, PasswordLastChangedDays

                #New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                #New-HTMLTableCondition -Name 'PasswordExpired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
            }
        }
    }
}