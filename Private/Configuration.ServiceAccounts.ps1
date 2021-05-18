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

                        }
                    }
                }
            }
        }
    }
}