$Script:ShowWinADUser = [ordered] @{
    Name       = 'All Users'
    Enabled    = $true
    Execute    = {
        Get-WinADUsers -PerDomain
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

                        }
                    }
                }
            }
        }
    }
}