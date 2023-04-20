$Script:ShowWinADComputer = [ordered] @{
    Name       = 'All Computers'
    Enabled    = $true
    Execute    = {
        Get-WinADComputers -PerDomain -AddOwner
    }
    Processing = {
        foreach ($Domain in $Script:Reporting['Computers']['Data'].Keys) {
            $Script:Reporting['Computers']['Variables'][$Domain] = [ordered] @{}

            foreach ($Computer in $Script:Reporting['Computers']['Data'][$Domain]) {
                $Script:Reporting['Computers']['Variables']['ComputersTotal']++
                if ($Computer.Enabled) {
                    $Script:Reporting['Computers']['Variables'][$Domain]['ComputersEnabled']++
                    $Script:Reporting['Computers']['Variables']['ComputersEnabled']++
                    if ($Computer.IsDC) {
                        $Script:Reporting['Computers']['Variables'][$Domain]['ComputersDC']++
                    } else {
                        $Script:Reporting['Computers']['Variables'][$Domain]['ComputersNotDC']++
                    }
                    if ($Computer.OperatingSystem -like "Windows Server*") {
                        $Script:Reporting['Computers']['Variables'][$Domain]['ComputersServer']++
                    } elseif ($Computer.OperatingSystem -notlike "Windows Server*" -and $Computer.OperatingSystem -like "Windows*") {
                        $Script:Reporting['Computers']['Variables'][$Domain]['ComputersClient']++
                    }
                } else {
                    $Script:Reporting['Computers']['Variables'][$Domain]['ComputersDisabled']++
                    $Script:Reporting['Computers']['Variables']['ComputersDisabled']++
                }
                if ($Computer.OperatingSystem) {
                    $Script:Reporting['Computers']['Variables']['Systems'][$computer.OperatingSystem]++
                } else {
                    $Script:Reporting['Computers']['Variables']['Systems']['Unknown']++
                }

                if ($Computer.OperatingSystem -like "Windows Server*") {
                    $Script:Reporting['Computers']['Variables']['ComputersServer']++
                    if ($Computer.Enabled) {
                        $Script:Reporting['Computers']['Variables']['ComputersServerEnabled']++
                    } else {
                        $Script:Reporting['Computers']['Variables']['ComputersServerDisabled']++
                    }
                } elseif ($Computer.OperatingSystem -notlike "Windows Server*" -and $Computer.OperatingSystem -like "Windows*") {
                    $Script:Reporting['Computers']['Variables']['ComputersWorkstation']++
                    if ($Computer.Enabled) {
                        $Script:Reporting['Computers']['Variables']['ComputersWorkstationEnabled']++
                    } else {
                        $Script:Reporting['Computers']['Variables']['ComputersWorkstationDisabled']++
                    }
                } else {
                    $Script:Reporting['Computers']['Variables']['ComputersOther']++
                    if ($Computer.Enabled) {
                        $Script:Reporting['Computers']['Variables']['ComputersOtherEnabled']++
                    } else {
                        $Script:Reporting['Computers']['Variables']['ComputersOtherDisabled']++
                    }

                }
            }
        }
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on showing status of all computer objects in the domain. "
            "It shows how many computers are enabled, disabled, expired, etc."
        ) -FontSize 10pt -LineBreak
        New-HTMLText -Text "Here's an overview of some statistics about computers:" -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Total number of computers: ", $($Script:Reporting['Computers']['Variables'].ComputersTotal) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of enabled computers: ", $($Script:Reporting['Computers']['Variables'].ComputersEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of disabled computers: ", $($Script:Reporting['Computers']['Variables'].ComputersDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of workstations: ", $($Script:Reporting['Computers']['Variables'].ComputersWorkstation) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of enabled workstations: ", $($Script:Reporting['Computers']['Variables'].ComputersWorkstationEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of disabled workstations: ", $($Script:Reporting['Computers']['Variables'].ComputersWorkstationDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of servers: ", $($Script:Reporting['Computers']['Variables'].ComputersServer) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of enabled servers: ", $($Script:Reporting['Computers']['Variables'].ComputersServerEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of disabled servers: ", $($Script:Reporting['Computers']['Variables'].ComputersServerDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of other computers: ", $($Script:Reporting['Computers']['Variables'].ComputersOther) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of enabled other computers: ", $($Script:Reporting['Computers']['Variables'].ComputersOtherEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of disabled other computers: ", $($Script:Reporting['Computers']['Variables'].ComputersOtherDisabled) -Color None, BlueMarguerite -FontWeight normal, bold
        } -FontSize 10pt
    }
    Variables  = @{
        ComputersTotal               = 0
        ComputersEnabled             = 0
        ComputersDisabled            = 0
        ComputersWorkstation         = 0
        ComputersWorkstationEnabled  = 0
        ComputersWorkstationDisabled = 0
        ComputersServer              = 0
        ComputersServerEnabled       = 0
        ComputersServerDisabled      = 0
        ComputersOther               = 0
        ComputersOtherEnabled        = 0
        ComputersOtherDisabled       = 0
        Systems                      = [ordered] @{
            Unknown = 0
        }
    }
    Solution   = {
        if ($Script:Reporting['Computers']['Data'] -is [System.Collections.IDictionary]) {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['Computers']['Summary']
                }
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartBarOptions -Type bar
                        New-ChartLegend -Name 'Computers by Operating System' -Color SpringGreen, Salmon
                        foreach ($System in $Script:Reporting['Computers']['Variables'].Systems.Keys) {
                            New-ChartBar -Name $System -Value $Script:Reporting['Computers']['Variables']['Systems'][$System]
                        }
                        New-ChartAxisY -LabelMaxWidth 300 -Show
                    } -Title 'Computers by Operating System' -TitleAlignment center
                }
            }
            New-HTMLSection -HeaderText 'General statistics' -CanCollapse {
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Computers Enabled' -Value $Script:Reporting['Computers']['Variables'].ComputersEnabled
                        New-ChartPie -Name 'Computers Disabled' -Value $Script:Reporting['Computers']['Variables'].ComputersDisabled
                    } -Title "Enabled vs Disabled All Computer Objects"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Clients enabled' -Value $Script:Reporting['Computers']['Variables'].ComputersWorkstationEnabled
                        New-ChartPie -Name 'Clients disabled' -Value $Script:Reporting['Computers']['Variables'].ComputersWorkstationDisabled
                    } -Title "Enabled vs Disabled Workstations"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Servers enabled' -Value $Script:Reporting['Computers']['Variables'].ComputersServerEnabled
                        New-ChartPie -Name 'Servers disabled' -Value $Script:Reporting['Computers']['Variables'].ComputersServerDisabled
                    } -Title "Enabled vs Disabled Servers"
                }
                New-HTMLPanel {
                    New-HTMLChart -Gradient {
                        New-ChartPie -Name 'Servers' -Value $Script:Reporting['Computers']['Variables'].ComputersServer
                        New-ChartPie -Name 'Clients' -Value $Script:Reporting['Computers']['Variables'].ComputersWorkstation
                        New-ChartPie -Name 'Non-Windows' -Value $Script:Reporting['Computers']['Variables'].ComputersOther
                    } -Title "Computers by Type"
                }
            }
            New-HTMLTabPanel {
                foreach ($Domain in $Script:Reporting['Computers']['Data'].Keys) {
                    New-HTMLTab -Name $Domain {
                        New-HTMLTable -DataTable $Script:Reporting['Computers']['Data'][$Domain] -Filtering {
                            # highlight whole row as blue if the computer is disabled
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -Row -BackgroundColor LightYellow
                            # highlight enabled column as red if the computer is disabled
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -BackgroundColor Salmon
                            # highlight whole row as green if the computer is enabled and LastLogon, PasswordDays Over 30
                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator le -Value 30
                                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator le -Value 30
                            } -BackgroundColor PaleGreen -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 30
                                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType string -Operator eq -Value ''
                            } -BackgroundColor LightPink -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType string -Operator eq -Value ''
                                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 30
                            } -BackgroundColor LightPink -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType string -Operator eq -Value ''
                                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType string -Operator eq -Value ''
                            } -BackgroundColor LightPink -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            # highlight whole row as green if the computer is enabled and LastLogon, PasswordDays Over 30
                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 30
                                New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 30
                            } -BackgroundColor Salmon -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled
                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'TrustedForDelegation' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
                            } -BackgroundColor Red -HighlightHeaders Name, SamAccountName, TrustedForDelegation, IsDC
                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                                New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $True
                            } -BackgroundColor Red -HighlightHeaders Name, SamAccountName, Enabled, PasswordNotRequired
                        } -ScrollX
                    }
                }
            }
        }
    }
}