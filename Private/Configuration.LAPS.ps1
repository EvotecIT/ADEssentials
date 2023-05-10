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
                if ($Computer.LastLogonDays -lt 60 -and $Computer.Laps -eq $false -and $Computer.IsDC -eq $false -and $Computer.System -like "Windows*") {
                    $Script:Reporting['LAPS']['Variables']['ComputersActiveNoLaps']++
                } elseif ($Computer.LastLogonDays -lt 60 -and $Computer.Laps -eq $true -and $Computer.IsDC -eq $false -and $Computer.System -like "Windows*") {
                    $Script:Reporting['LAPS']['Variables']['ComputersActiveWithLaps']++
                }
                if ($Computer.LastLogonDays -gt 360) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOver360days']++
                } elseif ($Computer.LastLogonDays -gt 180) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOver180days']++
                } elseif ($Computer.LastLogonDays -gt 90) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOver90days']++
                } elseif ($Computer.LastLogonDays -gt 60) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOver60days']++
                } elseif ($Computer.LastLogonDays -gt 30) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOver30days']++
                } elseif ($Computer.LastLogonDays -gt 15) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOver15days']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersRecent']++
                }
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersDisabled']++
            }
            if ($Computer.Laps -eq $true -and $Computer.Enabled -eq $true) {
                $Script:Reporting['LAPS']['Variables']['ComputersLapsEnabled']++
                if ($Computer.LapsExpirationDays -lt 0) {
                    $Script:Reporting['LAPS']['Variables']['ComputersLapsExpired']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersLapsNotExpired']++
                }
            } elseif ($Computer.Enabled -eq $true) {
                if ($Computer.IsDC -eq $true -or $Computer.System -notlike "Windows*") {
                    $Script:Reporting['LAPS']['Variables']['ComputersLapsNotApplicable']++
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersLapsDisabled']++
                }
            }
            if ($Computer.LastLogonDays -gt 60) {
                $Script:Reporting['LAPS']['Variables']['ComputersInactive']++
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersActive']++
            }
            if ($Computer.System -like "Windows Server*") {
                $Script:Reporting['LAPS']['Variables']['ComputersServer']++
                if ($Computer.Enabled) {
                    $Script:Reporting['LAPS']['Variables']['ComputersServerEnabled']++
                    if ($Computer.Laps -eq $true -and $Computer.IsDc -eq $false) {
                        $Script:Reporting['LAPS']['Variables']['ComputersServerLapsEnabled']++
                    } elseif ($Computer.Laps -eq $false -and $Computer.IsDc -eq $false) {
                        $Script:Reporting['LAPS']['Variables']['ComputersServerLapsDisabled']++
                    }
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersServerDisabled']++
                }
            } elseif ($Computer.System -notlike "Windows Server*" -and $Computer.System -like "Windows*") {
                $Script:Reporting['LAPS']['Variables']['ComputersWorkstation']++
                if ($Computer.Enabled) {
                    $Script:Reporting['LAPS']['Variables']['ComputersWorkstationEnabled']++
                    if ($Computer.Laps) {
                        $Script:Reporting['LAPS']['Variables']['ComputersWorkstationLapsEnabled']++
                    } else {
                        $Script:Reporting['LAPS']['Variables']['ComputersWorkstationLapsDisabled']++
                    }
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersWorkstationDisabled']++
                }
            } else {
                $Script:Reporting['LAPS']['Variables']['ComputersOther']++
                if ($Computer.Enabled) {
                    $Script:Reporting['LAPS']['Variables']['ComputersOtherEnabled']++
                    if ($Computer.Laps) {
                        $Script:Reporting['LAPS']['Variables']['ComputersOtherLapsEnabled']++
                    } else {
                        $Script:Reporting['LAPS']['Variables']['ComputersOtherLapsDisabled']++
                    }
                } else {
                    $Script:Reporting['LAPS']['Variables']['ComputersOtherDisabled']++
                }
            }
        }
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on showing LAPS status of all computer objects in the domain. "
            "It shows how many computers are enabled, disabled, have LAPS enabled, disabled, expired, etc."
            "It's perfectly normal that some LAPS passwords are expired, due to working over VPN etc."
        ) -FontSize 10pt -LineBreak
        New-HTMLText -Text "Following computer resources are exempt from LAPS: " -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Domain Controllers and Read Only Domain Controllers"
            New-HTMLListItem -Text 'Computer Service accounts such as AZUREADSSOACC$'
        } -FontSize 10pt
        New-HTMLText -Text "Here's an overview of some statistics about computers:" -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Total number of computers: ", $($Script:Reporting['LAPS']['Variables'].ComputersTotal) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of enabled computers: ", $($Script:Reporting['LAPS']['Variables'].ComputersEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of disabled computers: ", $($Script:Reporting['LAPS']['Variables'].ComputersDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of active computers (less then 60 days): ", $($Script:Reporting['LAPS']['Variables'].ComputersActive) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of inactive computers (over 60 days): ", $($Script:Reporting['LAPS']['Variables'].ComputersInactive) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of active computers with LAPS (less then 60 days): ", $($Script:Reporting['LAPS']['Variables'].ComputersActiveWithLaps) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of active computers without LAPS (less then 60 days): ", $($Script:Reporting['LAPS']['Variables'].ComputersActiveNoLaps) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of computers (enabled) with LAPS: ", $($Script:Reporting['LAPS']['Variables'].ComputersLapsEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of computers (enabled) without LAPS: ", $($Script:Reporting['LAPS']['Variables'].ComputersLapsDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of servers (enabled) with LAPS: ", $($Script:Reporting['LAPS']['Variables'].ComputersServerLapsEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of servers (enabled)  without LAPS: ", $($Script:Reporting['LAPS']['Variables'].ComputersServerLapsDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of workstations (enabled) with LAPS: ", $($Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of workstations (enabled) without LAPS: ", $($Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
        } -FontSize 10pt
    }
    Variables  = @{
        ComputersActiveNoLaps            = 0
        ComputersActiveWithLaps          = 0
        ComputersTotal                   = 0
        ComputersEnabled                 = 0
        ComputersDisabled                = 0
        ComputersActive                  = 0
        ComputersInactive                = 0
        ComputersLapsEnabled             = 0
        ComputersLapsDisabled            = 0
        ComputersLapsNotApplicable       = 0
        ComputersLapsExpired             = 0
        ComputersLapsNotExpired          = 0
        ComputersServer                  = 0
        ComputersServerEnabled           = 0
        ComputersServerDisabled          = 0
        ComputersServerLapsEnabled       = 0
        ComputersServerLapsDisabled      = 0
        ComputersWorkstation             = 0
        ComputersWorkstationEnabled      = 0
        ComputersWorkstationDisabled     = 0
        ComputersWorkstationLapsEnabled  = 0
        ComputersWorkstationLapsDisabled = 0
        ComputersOther                   = 0
        ComputersOtherEnabled            = 0
        ComputersOtherDisabled           = 0
        ComputersOtherLapsEnabled        = 0
        ComputersOtherLapsDisabled       = 0
        ComputersOver360days             = 0
        ComputersOver180days             = 0
        ComputersOver90days              = 0
        ComputersOver60days              = 0
        ComputersOver30days              = 0
        ComputersOver15days              = 0
        ComputersRecent                  = 0
    }
    Solution   = {
        if ($Script:Reporting['LAPS']['Data']) {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['LAPS']['Summary']
                }
                New-HTMLPanel {

                    New-HTMLChart {
                        New-ChartBarOptions -Type bar
                        New-ChartLegend -Name 'Active Computers (by last logon age)' -Color SpringGreen, Salmon
                        New-ChartBar -Name 'Computers (over 360 days)' -Value $Script:Reporting['LAPS']['Variables'].ComputersOver360days
                        New-ChartBar -Name 'Computers (over 180 days)' -Value $Script:Reporting['LAPS']['Variables'].ComputersOver180days
                        New-ChartBar -Name 'Computers (over 90 days)' -Value $Script:Reporting['LAPS']['Variables'].ComputersOver90days
                        New-ChartBar -Name 'Computers (over 60 days)' -Value $Script:Reporting['LAPS']['Variables'].ComputersOver60days
                        New-ChartBar -Name 'Computers (over 30 days)' -Value $Script:Reporting['LAPS']['Variables'].ComputersOver30days
                        New-ChartBar -Name 'Computers (over 15 days)' -Value $Script:Reporting['LAPS']['Variables'].ComputersOver15days
                        New-ChartBar -Name 'Computers (Recent)' -Value $Script:Reporting['LAPS']['Variables'].ComputersRecent
                        New-ChartAxisY -LabelMaxWidth 300 -Show
                    } -Title 'Active Computers' -TitleAlignment center

                }
            }
            New-HTMLSection -HeaderText 'General statistics' -CanCollapse {
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Computers Enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersEnabled
                        New-ChartPie -Name 'Computers Disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersDisabled
                    } -Title "Enabled vs Disabled All Computer Objects"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Clients enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationEnabled
                        New-ChartPie -Name 'Clients disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationDisabled
                    } -Title "Enabled vs Disabled Workstations"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Servers enabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerEnabled
                        New-ChartPie -Name 'Servers disabled' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerDisabled
                    } -Title "Enabled vs Disabled Servers"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Servers' -Value $Script:Reporting['LAPS']['Variables'].ComputersServer
                        New-ChartPie -Name 'Clients' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstation
                        New-ChartPie -Name 'Non-Windows' -Value $Script:Reporting['LAPS']['Variables'].ComputersOther
                    } -Title "Computers by Type"
                }
            }
            New-HTMLSection -HeaderText 'LAPS statistics' -CanCollapse -Direction column {
                New-HTMLSection -Invisible {
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'With LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsEnabled -Color '#94ffc8'
                            New-ChartPie -Name 'Without LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsDisabled -Color 'Salmon'
                            New-ChartPie -Name 'LAPS N/A' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsNotApplicable -Color 'LightGray'
                        } -Title "All Computers with LAPS"
                    }
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'With LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersActiveWithLaps -Color '#94ffc8'
                            New-ChartPie -Name 'Without LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersActiveNoLaps -Color 'Salmon'
                        } -Title "Active Computers with LAPS" -SubTitle "Logged on within the last 60 days"
                    }
                    New-HTMLPanel {
                        New-HTMLChart -Gradient {
                            New-ChartPie -Name 'LAPS Expired' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsExpired
                            New-ChartPie -Name 'LAPS Up-to-date' -Value $Script:Reporting['LAPS']['Variables'].ComputersLapsNotExpired
                        } -Title "LAPS Passwords Expired"
                    }
                }
                New-HTMLSection -Invisible {
                    New-HTMLSection -HeaderText 'Servers (Windows Server)' -CanCollapse {
                        New-HTMLPanel {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'With LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerLapsEnabled -Color '#94ffc8'
                                New-ChartPie -Name 'Without LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersServerLapsDisabled -Color 'Salmon'
                            } -Title "Servers with LAPS"
                        }
                    }
                    New-HTMLSection -HeaderText 'Workstations (Windows Client)' -CanCollapse {
                        New-HTMLPanel {
                            New-HTMLChart -Gradient {
                                New-ChartPie -Name 'With LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsEnabled -Color '#94ffc8'
                                New-ChartPie -Name 'Without LAPS' -Value $Script:Reporting['LAPS']['Variables'].ComputersWorkstationLapsDisabled -Color 'Salmon'
                            } -Title "Workstations with LAPS"
                        }
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