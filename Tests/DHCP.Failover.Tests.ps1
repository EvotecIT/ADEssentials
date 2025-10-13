Describe 'DHCP Failover Analysis (TestMode)' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    It 'Unions scopes across multiple relationships per partner pair' {
        $s = Get-WinADDHCPSummary -TestMode -Minimal

        # Baseline counts from the bundled TestMode data
        $s.FailoverRelationships.Count | Should -BeGreaterThan 0
        $s.FailoverAnalysis | Should -Not -BeNullOrEmpty

        # These expectations are tied to Private/Get-TestModeDHCPData.ps1
        # and validate that pair-wise union + normalization works.
        $s.FailoverRelationships.Count | Should -Be 7
        $s.FailoverAnalysis.PerSubnetIssues.Count | Should -Be 6
        $s.FailoverAnalysis.OnlyOnPrimary.Count    | Should -Be 1
        $s.FailoverAnalysis.OnlyOnSecondary.Count  | Should -Be 1
        $s.FailoverAnalysis.MissingOnBoth.Count    | Should -Be 1
    }

    It 'Does not duplicate per-subnet issues across relationships' {
        $s = Get-WinADDHCPSummary -TestMode -Minimal
        $set = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($i in $s.FailoverAnalysis.PerSubnetIssues) {
            $key = "$($i.PrimaryServer)↔$($i.SecondaryServer)|$($i.ScopeId)|$($i.Issue)"
            $added = $set.Add($key)
            $added | Should -BeTrue
        }
    }
}

