$Script:ShowWinADAccountDelegation = [ordered] @{
    Name       = 'All Accounts Delegation'
    Enabled    = $true
    Execute    = {
        Get-WinADDelegatedAccounts
    }
    Processing = {

    }
    Summary    = {

    }
    Variables  = @{

    }
    Solution   = {
        New-HTMLTable -DataTable $Script:Reporting['AccountDelegation']['Data'] -Filtering {
            # # highlight whole row as blue if the computer is disabled
            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $false -Row -BackgroundColor LightYellow
            # # highlight enabled column as red if the computer is disabled
            New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor PaleGreen

            New-HTMLTableConditionGroup {
                New-HTMLTableCondition -Name 'FullDelegation' -ComparisonType string -Operator eq -Value $true
                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true
                New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
            } -BackgroundColor Salmon -HighlightHeaders 'FullDelegation' -FailBackgroundColor PaleGreen

            New-HTMLTableCondition -Name 'ConstrainedDelegation' -ComparisonType string -Operator eq -Value $true -BackgroundColor PaleGreen -FailBackgroundColor Yellow
            New-HTMLTableCondition -Name 'ResourceDelegation' -ComparisonType string -Operator eq -Value $true -BackgroundColor PaleGreen -FailBackgroundColor Yellow
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