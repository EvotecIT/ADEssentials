$Script:ShowWinADUser = [ordered] @{
    Name       = 'All Users'
    Enabled    = $true
    Execute    = {
        Get-WinADUsers -PerDomain -AddOwner
    }
    Processing = {
        foreach ($Domain in $Script:Reporting['Users']['Data'].Keys) {
            foreach ($User in $Script:Reporting['Users']['Data'][$Domain]) {
                $Script:Reporting['Users']['Variables']['UsersTotal']++
                if ($User.Enabled) {
                    $Script:Reporting['Users']['Variables']['UsersEnabled']++

                    if ($User.PasswordNeverExpires) {
                        $Script:Reporting['Users']['Variables']['PasswordNeverExpires']++
                    } else {
                        $Script:Reporting['Users']['Variables']['PasswordExpires']++
                    }
                    if ($User.PasswordNotRequired) {
                        $Script:Reporting['Users']['Variables']['PasswordNotRequired']++
                    }
                    if ($User.PasswordLastDays -gt 360) {
                        $Script:Reporting['Users']['Variables']['PasswordLastDays360']++
                    } elseif ($User.PasswordLastDays -gt 300) {
                        $Script:Reporting['Users']['Variables']['PasswordLastDays300']++
                    } elseif ($User.PasswordLastDays -gt 180) {
                        $Script:Reporting['Users']['Variables']['PasswordLastDays180']++
                    } elseif ($User.PasswordLastDays -gt 90) {
                        $Script:Reporting['Users']['Variables']['PasswordLastDays90']++
                    } elseif ($User.PasswordLastDays -gt 60) {
                        $Script:Reporting['Users']['Variables']['PasswordLastDays60']++
                    } else {
                        $Script:Reporting['Users']['Variables']['PasswordLastDaysRecent']++
                    }
                    if ($User.LastLogonDays -gt 360) {
                        $Script:Reporting['Users']['Variables']['LastLogonDays360']++
                    } elseif ($User.LastLogonDays -gt 300) {
                        $Script:Reporting['Users']['Variables']['LastLogonDays300']++
                    } elseif ($User.LastLogonDays -gt 180) {
                        $Script:Reporting['Users']['Variables']['LastLogonDays180']++
                    } elseif ($User.LastLogonDays -gt 90) {
                        $Script:Reporting['Users']['Variables']['LastLogonDays90']++
                    } elseif ($User.LastLogonDays -gt 60) {
                        $Script:Reporting['Users']['Variables']['LastLogonDays60']++
                    } else {
                        $Script:Reporting['Users']['Variables']['LastLogonDaysRecent']++
                    }
                } else {
                    $Script:Reporting['Users']['Variables']['UsersDisabled']++
                }
                if ($User.OwnerType -notin "WellKnownAdministrative", 'Administrative') {
                    $Script:Reporting['Users']['Variables']['OwnerNotAdministrative']++
                } else {
                    $Script:Reporting['Users']['Variables']['OwnerAdministrative']++
                }
                $Script:Reporting['Users']['Variables'].PasswordPolicies[$User.PasswordPolicyName]++
            }
        }
    }
    Variables  = @{
        PasswordPolicies = [ordered] @{}
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on showing status of all users objects in the Active Directory forest. "
            "It shows how many users are enabled, disabled, expired, etc."
        ) -FontSize 10pt -LineBreak
        New-HTMLText -Text "Here's an overview of some statistics about users:" -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Total number of users: ", $($Script:Reporting['Users']['Variables'].UsersTotal) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of enabled users: ", $($Script:Reporting['Users']['Variables'].UsersEnabled) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of disabled users: ", $($Script:Reporting['Users']['Variables'].UsersDisabled) -Color None, BlueMarguerite -FontWeight normal, bold

            New-HTMLListItem -Text "Total number of owners that are Domain Admins/Enterprise Admins: ", $($Script:Reporting['Users']['Variables'].OwnerAdministrative) -Color None, BlueMarguerite -FontWeight normal, bold
            New-HTMLListItem -Text "Total number of owenrs that are non-administrative: ", $($Script:Reporting['Users']['Variables'].OwnerNotAdministrative) -Color None, BlueMarguerite -FontWeight normal, bold

            foreach ($PasswordPolicy in $Script:Reporting['Users']['Variables'].PasswordPolicies.Keys) {
                $Number = $Script:Reporting['Users']['Variables'].PasswordPolicies[$PasswordPolicy]
                New-HTMLListItem -Text "Total number of users with password policy '$PasswordPolicy': ", $Number -Color None, BlueMarguerite -FontWeight normal, bold
            }
        } -FontSize 10pt
    }
    Solution   = {
        if ($Script:Reporting['Users']['Data'] -is [System.Collections.IDictionary]) {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['Users']['Summary']
                }
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartBarOptions -Type bar
                        New-ChartLegend -Name 'Users by Password Policies' -Color SpringGreen, Salmon
                        foreach ($PasswordPolicy in $Script:Reporting['Users']['Variables'].PasswordPolicies.Keys) {
                            New-ChartBar -Name $PasswordPolicy -Value $Script:Reporting['Users']['Variables']['PasswordPolicies'][$PasswordPolicy]
                        }
                        New-ChartAxisY -LabelMaxWidth 300 -Show
                    } -Title 'Users by Password Policies' -TitleAlignment center
                }
            }
            New-HTMLSection -HeaderText 'General statistics' -CanCollapse {
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartPie -Name 'Users Enabled' -Value $Script:Reporting['Users']['Variables'].UsersEnabled -Color '#58ffc5'
                        New-ChartPie -Name 'Users Disabled' -Value $Script:Reporting['Users']['Variables'].UsersDisabled -Color CoralRed
                    } -Title "Enabled vs Disabled All User Objects"
                }
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartPie -Name 'Administrative' -Value $Script:Reporting['Users']['Variables'].OwnerAdministrative -Color '#58ffc5'
                        New-ChartPie -Name 'Other' -Value $Script:Reporting['Users']['Variables'].OwnerNotAdministrative -Color CoralRed
                    } -Title "Owner being Administrative vs Other"
                }
                New-HTMLPanel {
                    New-HTMLChart {
                        New-ChartPie -Name 'Password Never Expires' -Value $Script:Reporting['Users']['Variables'].PasswordNeverExpires -Color CoralRed
                        New-ChartPie -Name 'Password Expires' -Value $Script:Reporting['Users']['Variables'].PasswordExpires -Color '#58ffc5'
                    } -Title "Password Never Expires vs Expires" -SubTitle 'Enabled Only'
                }
            }
            New-HTMLTabPanel -Orientation horizontal {
                foreach ($Domain in $Script:Reporting['Users']['Data'].Keys) {
                    New-HTMLTab -Name $Domain {
                        New-HTMLTable -DataTable $Script:Reporting['Users']['Data'][$Domain] -Filtering {
                            # highlight whole row as blue if the computer is disabled
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -Row -BackgroundColor LightYellow
                            # highlight enabled column as red if the computer is disabled
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -BackgroundColor Salmon
                            # highlight enabled column as BrightTurquoise if the computer is enabled
                            # we don't know if it's any good, but lets try it
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor BrightTurquoise
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