$Script:ShowWinADGroup = [ordered] @{
    Name       = 'All Groups'
    Enabled    = $true
    Execute    = {
        Get-WinADGroups -PerDomain -AddOwner
    }
    Processing = {

    }
    Summary    = {

    }
    Variables  = @{

    }
    Solution   = {
        if ($Script:Reporting['Groups']['Data'] -is [System.Collections.IDictionary]) {
            New-HTMLTabPanel {
                foreach ($Domain in $Script:Reporting['Groups']['Data'].Keys) {

                    New-HTMLTab -Name $Domain {
                        New-HTMLTable -DataTable $Script:Reporting['Groups']['Data'][$Domain] -Filtering {
                            New-HTMLTableColumnOption -ColumnIndex 17 -Width 3000
                            New-HTMLTableCondition -Name 'ManagerCanUpdateGroupMembership' -ComparisonType string -Operator eq -Value $true -BackgroundColor LightYellow
                            New-HTMLTableCondition -Name 'ManagerCanUpdateGroupMembership' -ComparisonType string -Operator eq -Value $false -BackgroundColor PaleGreen
                            #New-HTMLTableCondition -Name 'GroupWriteBack' -ComparisonType string -Operator eq -Value $true -BackgroundColor Pink
                            #New-HTMLTableCondition -Name 'GroupWriteBack' -ComparisonType string -Operator eq -Value $false -BackgroundColor PaleGreen
                            # highlight whole row as blue if the computer is disabled
                            # New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -Row -BackgroundColor LightYellow
                            # # highlight enabled column as red if the computer is disabled
                            # New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -BackgroundColor Salmon
                            # # highlight whole row as green if the computer is enabled and LastLogon, PasswordDays Over 30
                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator le -Value 30
                            #     New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator le -Value 30
                            # } -BackgroundColor PaleGreen -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 30
                            #     New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType string -Operator eq -Value ''
                            # } -BackgroundColor LightPink -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType string -Operator eq -Value ''
                            #     New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 30
                            # } -BackgroundColor LightPink -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType string -Operator eq -Value ''
                            #     New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType string -Operator eq -Value ''
                            # } -BackgroundColor LightPink -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled

                            # # highlight whole row as green if the computer is enabled and LastLogon, PasswordDays Over 30
                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 30
                            #     New-HTMLTableCondition -Name 'PasswordLastDays' -ComparisonType number -Operator gt -Value 30
                            # } -BackgroundColor Salmon -HighlightHeaders LastLogonDays, PasswordLastDays, Enabled
                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'TrustedForDelegation' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
                            # } -BackgroundColor Red -HighlightHeaders Name, SamAccountName, TrustedForDelegation, IsDC
                            # New-HTMLTableConditionGroup -Conditions {
                            #     New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $True
                            #     New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $True
                            # } -BackgroundColor Red -HighlightHeaders Name, SamAccountName, Enabled, PasswordNotRequired
                        } -ScrollX
                    }
                }
            }
        }
    }
}