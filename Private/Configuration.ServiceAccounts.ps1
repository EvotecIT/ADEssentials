$Script:ConfigurationServiceAccounts = [ordered] @{
    Name       = 'Service Accounts'
    Enabled    = $true
    Execute    = {
        Get-WinADServiceAccount -PerDomain
    }
    Processing = {

    }
    Summary    = {

    }
    Variables  = @{

    }
    Solution   = {

        if ($Script:Reporting['ServiceAccounts']['Data'] -is [System.Collections.IDictionary]) {
            New-HTMLTabPanel {
                foreach ($Domain in $Script:Reporting['ServiceAccounts']['Data'].Keys) {

                    New-HTMLTab -Name $Domain {
                        New-HTMLTable -DataTable $Script:Reporting['ServiceAccounts']['Data'][$Domain] -Filtering {
                            New-HTMLTableCondition -Name 'ServiceAccountType' -ComparisonType string -Operator like -Value '*dMSA*' -BackgroundColor LightBlue
                            New-HTMLTableCondition -Name 'SupportsDESEncryption' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Red
                            New-HTMLTableCondition -Name 'SupportsRC4Encryption' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon
                            New-HTMLTableCondition -Name 'FallsBackToDomainEncryptionDefaults' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightYellow
                            New-HTMLTableConditionGroup -Conditions {
                                New-HTMLTableCondition -Name 'SupportsAESKeys' -ComparisonType bool -Operator eq -Value $false
                                New-HTMLTableCondition -Name 'FallsBackToDomainEncryptionDefaults' -ComparisonType bool -Operator eq -Value $false
                            } -BackgroundColor LightPink -HighlightHeaders SupportedEncryptionTypes, SupportsAESKeys
                        }
                    }
                }
            }
        }
    }
}
