﻿$Script:ConfigurationBitLocker = [ordered] @{
    Name       = 'Bitlocker Summary'
    Enabled    = $true
    Execute    = {
        Get-WinADBitlockerLapsSummary -BitlockerOnly
    }
    Processing = {

    }
    Summary    = {

    }
    Variables  = @{

    }
    Solution   = {
        if ($Script:Reporting['BitLocker']['Data']) {
            New-HTMLChart {
                New-ChartLegend -LegendPosition bottom -HorizontalAlign center -Color Red, Blue, Yellow
                New-ChartTheme -Palette palette5
                foreach ($Object in $DataTable) {
                    New-ChartRadial -Name $Object.Name -Value $Object.Money
                }
                # Define event
                #New-ChartEvent -DataTableID 'NewIDtoSearchInChart' -ColumnID 0
            }

            New-HTMLTable -DataTable $Script:Reporting['BitLocker']['Data'] -Filtering -SearchBuilder {
                New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue

                New-HTMLTableCondition -Name 'Encrypted' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Salmon

                #New-HTMLTableCondition -Name 'LapsExpirationDays' -ComparisonType number -Operator lt -Value 0 -BackgroundColor BurntOrange -HighlightHeaders LapsExpirationDays, LapsExpirationTime -FailBackgroundColor LimeGreen
                #New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor Alizarin

                #New-HTMLTableCondition -Name 'Laps' -ComparisonType string -Operator eq -Value $false -BackgroundColor Alizarin -HighlightHeaders LapsExpirationDays, LapsExpirationTime

                New-HTMLTableCondition -Name 'LastLogonDays' -ComparisonType number -Operator gt -Value 60 -BackgroundColor Salmon -HighlightHeaders LastLogonDays, LastLogonDate -FailBackgroundColor LimeGreen
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator ge -Value 0 -BackgroundColor LimeGreen -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 300 -BackgroundColor Orange -HighlightHeaders PasswordLastSet, PasswordLastChangedDays
                New-HTMLTableCondition -Name 'PasswordLastChangedDays' -ComparisonType number -Operator gt -Value 360 -BackgroundColor Salmon -HighlightHeaders PasswordLastSet, PasswordLastChangedDays

                #New-HTMLTableCondition -Name 'PasswordNotRequired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
                #New-HTMLTableCondition -Name 'PasswordExpired' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor Alizarin
            }
        }
    }
}