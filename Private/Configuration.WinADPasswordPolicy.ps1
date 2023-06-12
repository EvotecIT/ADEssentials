$Script:ConfigurationPasswordPolicies = [ordered] @{
    Name       = 'Password Policies Summary'
    Enabled    = $true
    Execute    = {
        Get-WinADPasswordPolicy
    }
    Processing = {
        foreach ($PasswordPolicy in $Script:Reporting['PasswordPolicies']['Data']) {
            if ($PasswordPolicy.Name -eq 'Default Password Policy') {
                $Script:Reporting['PasswordPolicies']['Variables'].DefaultPasswordPolicy += 1
            } else {
                $Script:Reporting['PasswordPolicies']['Variables'].FineGrainedPasswordPolicies += 1
            }
        }
    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on showing all Password Policies in Active Directory forest. "
            "It shows default password policies and fine grained password policies. "
            "Keep in mind that there can only be one valid Default Password Policy per domain. "
            "If you have multiple password policies defined (that are not FGPP), only one will work, the one with the lowest precedence on the Domain Controller OU."
            "Any other Password Policy that you defined will not be shown here."
            "If you are not seeing FGPP password policies and you have them defined, make sure that you have extended rights to read them."
        ) -FontSize 10pt -LineBreak
    }
    Variables  = @{

    }
    Solution   = {
        if ($Script:Reporting['PasswordPolicies']['Data']) {
            New-HTMLSection -Invisible {
                New-HTMLPanel {
                    $Script:Reporting['PasswordPolicies']['Summary']
                }
            }
            New-HTMLTable -DataTable $Script:Reporting['PasswordPolicies']['Data'] -Filtering -SearchBuilder {
                New-HTMLTableCondition -Name 'MinPasswordLength' -ComparisonType number -Operator le -Value 8 -BackgroundColor Salmon
                New-HTMLTableCondition -Name 'MinPasswordLength' -ComparisonType number -Operator le -Value 4 -BackgroundColor Red
                New-HTMLTableCondition -Name 'MinPasswordLength' -ComparisonType number -Operator between -Value 8, 16 -BackgroundColor Yellow
                New-HTMLTableCondition -Name 'MinPasswordLength' -ComparisonType number -Operator between -Value 16, 20 -BackgroundColor LightGreen
                New-HTMLTableCondition -Name 'MinPasswordLength' -ComparisonType number -Operator ge -Value 20 -BackgroundColor Green
                New-HTMLTableCondition -Name 'ComplexityEnabled' -ComparisonType string -Operator eq -Value $false -BackgroundColor Salmon -FailBackgroundColor LightGreen
                New-HTMLTableCondition -Name 'ReversibleEncryptionEnabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor Salmon -FailBackgroundColor LightGreen
            } -ScrollX
        }
    }
}