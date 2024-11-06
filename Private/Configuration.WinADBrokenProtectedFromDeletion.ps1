$Script:ShowWinADBrokenProtectedFromDeletion = [ordered] @{
    Name       = ''
    Enabled    = $true
    Execute    = {
        Get-WinADBrokenProtectedFromDeletion -Type All
    }
    Processing = {

    }
    Summary    = {

    }
    Variables  = @{

    }
    Solution   = {
        New-HTMLTable -DataTable $Script:Reporting['BrokenProtectedFromDeletion']['Data'] -Filtering {
            New-HTMLTableCondition -Name 'HasBrokenPermissions' -Value $true -Operator 'eq' -ComparisonType string -BackgroundColor Salmon  -FailBackgroundColor MintGreen
        } -ScrollX
    }
}