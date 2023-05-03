$Script:ShowWinADUser = [ordered] @{
    Name       = 'All Users'
    Enabled    = $true
    Execute    = {
        Get-WinADUsers -PerDomain -AddOwner
    }
    Processing = {

    }
    Variables  = @{

    }
    Summary    = {

    }
    Solution   = {
        if ($Script:Reporting['Users']['Data'] -is [System.Collections.IDictionary]) {
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