$Script:ShowWinADComputer = [ordered] @{
    Name       = 'All Computers'
    Enabled    = $true
    Execute    = {
        Get-WinADComputers -PerDomain
    }
    Processing = {

    }
    Summary    = {

    }
    Variables  = @{

    }
    Solution   = {

        if ($Script:Reporting['Computers']['Data'] -is [System.Collections.IDictionary]) {
            New-HTMLTabPanel {
                foreach ($Domain in $Script:Reporting['Computers']['Data'].Keys) {

                    New-HTMLTab -Name $Domain {
                        New-HTMLTable -DataTable $Script:Reporting['Computers']['Data'][$Domain] -Filtering {

                        }
                    }
                }
            }
        }
    }
}