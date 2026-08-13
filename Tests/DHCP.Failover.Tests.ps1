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
            $key = "$($i.PrimaryServer)<->$($i.SecondaryServer)|$($i.ScopeId)|$($i.Issue)"
            $added = $set.Add($key)
            $added | Should -BeTrue
        }
    }
}

Describe 'DHCP DNS record management validation (TestMode)' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    It 'Flags scopes when PTR registration updates are disabled' {
        $s = Get-WinADDHCPSummary -TestMode -Minimal

        $ptrIssue = $s.ValidationResults.WarningIssues.DNSRecordManagement | Where-Object { [string] $_.ScopeId -eq '10.1.0.0' } | Select-Object -First 1
        $ptrIssue | Should -Not -BeNullOrEmpty
        $ptrIssue.DisableDnsPtrRRUpdate | Should -BeTrue
        $ptrIssue.Issues | Should -Contain 'PTR registration disabled'
    }
}

Describe 'DHCP option issue parsing' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    It 'Returns null for empty or whitespace issue text' {
        InModuleScope ADEssentials {
            ConvertTo-DHCPOptionIssueRecord -Issue '   ' | Should -BeNullOrEmpty
        }
    }
}

Describe 'DHCP Server Prefix Filters (TestMode)' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    It 'Filters servers by IncludeServerPrefix (case-insensitive)' {
        $s = Get-WinADDHCPSummary -TestMode -Minimal -IncludeServerPrefix 'DHCP'
        $s.Servers.Count | Should -Be 2
        $s.Servers.ServerName | Should -Not -Contain 'dc01.domain.com'
    }

    It 'Filters servers by ExcludeServerPrefix and clears unrelated failover relationships' {
        $all = Get-WinADDHCPSummary -TestMode -Minimal
        $expected = @(
            $all.Servers | Where-Object {
                $short = ([string]$_.ServerName).Split('.')[0].ToLower()
                -not $short.StartsWith('dhcp')
            }
        ).Count

        $s = Get-WinADDHCPSummary -TestMode -Minimal -ExcludeServerPrefix 'dhcp'
        $s.Servers.Count | Should -Be $expected
        @(
            $s.Servers | Where-Object {
                $short = ([string]$_.ServerName).Split('.')[0].ToLower()
                $short.StartsWith('dhcp')
            }
        ).Count | Should -Be 0
        $s.FailoverRelationships.Count | Should -Be 0
    }
}

Describe 'DHCP Server Exclusions Affect All Outcomes (TestMode)' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
        $script:origGetTestModeDHCPData = Get-Command Get-TestModeDHCPData -Module ADEssentials
    }

    BeforeEach {
        Mock -ModuleName ADEssentials Get-WinDHCPServerInfo {
            param(
                [string] $ComputerName,
                [switch] $TestMode
            )
            [PSCustomObject]@{
                IsReachable     = $true
                PingSuccessful  = $true
                DNSResolvable   = $true
                DHCPResponding  = $true
                Version         = '10.0'
                Status          = 'Online'
                ErrorMessage    = $null
                IPAddress       = '192.168.100.10'
                ResponseTimeMs  = 5
                ReverseDNSName  = $ComputerName
                ReverseDNSValid = $true
            }
        }

        Mock -ModuleName ADEssentials Get-TestModeDHCPData {
            param(
                [Parameter(Mandatory)][string] $DataType,
                [string] $ComputerName,
                [string] $ScopeId
            )

            switch ($DataType) {
                'DhcpServersInDC' {
                    return @(
                        [PSCustomObject]@{ DnsName = 'corp-dhcp01.domain.com'; IPAddress = '192.168.1.10' },
                        [PSCustomObject]@{ DnsName = 'corp-dhcp02.domain.com'; IPAddress = '192.168.1.11' },
                        [PSCustomObject]@{ DnsName = 'usfsm-dhcp01.domain.com'; IPAddress = '192.168.1.21' },
                        [PSCustomObject]@{ DnsName = 'it-dhcp01.domain.com'; IPAddress = '192.168.1.24' }
                    )
                }
                'DhcpServerv4Scope' {
                    switch ($ComputerName) {
                        'corp-dhcp01.domain.com' {
                            return @(
                                [PSCustomObject]@{
                                    ScopeId        = [System.Net.IPAddress]::Parse('10.10.0.0')
                                    Name           = 'Corp Scope 01'
                                    Description    = 'Corp scope on primary'
                                    SubnetMask     = [System.Net.IPAddress]::Parse('255.255.255.0')
                                    StartRange     = [System.Net.IPAddress]::Parse('10.10.0.10')
                                    EndRange       = [System.Net.IPAddress]::Parse('10.10.0.200')
                                    LeaseDuration  = [timespan]::FromHours(8)
                                    State          = 'Active'
                                    Type           = 'Dhcp'
                                    SuperscopeName = $null
                                }
                            )
                        }
                        'corp-dhcp02.domain.com' {
                            return @(
                                [PSCustomObject]@{
                                    ScopeId        = [System.Net.IPAddress]::Parse('10.20.0.0')
                                    Name           = 'Corp Scope 02'
                                    Description    = 'Corp scope on secondary'
                                    SubnetMask     = [System.Net.IPAddress]::Parse('255.255.255.0')
                                    StartRange     = [System.Net.IPAddress]::Parse('10.20.0.10')
                                    EndRange       = [System.Net.IPAddress]::Parse('10.20.0.200')
                                    LeaseDuration  = [timespan]::FromHours(8)
                                    State          = 'Active'
                                    Type           = 'Dhcp'
                                    SuperscopeName = $null
                                }
                            )
                        }
                        'usfsm-dhcp01.domain.com' {
                            return @(
                                [PSCustomObject]@{
                                    ScopeId        = [System.Net.IPAddress]::Parse('10.30.0.0')
                                    Name           = 'Excluded Scope'
                                    Description    = 'Scope on excluded server'
                                    SubnetMask     = [System.Net.IPAddress]::Parse('255.255.255.0')
                                    StartRange     = [System.Net.IPAddress]::Parse('10.30.0.10')
                                    EndRange       = [System.Net.IPAddress]::Parse('10.30.0.200')
                                    LeaseDuration  = [timespan]::FromHours(8)
                                    State          = 'Active'
                                    Type           = 'Dhcp'
                                    SuperscopeName = $null
                                }
                            )
                        }
                        'it-dhcp01.domain.com' {
                            return @(
                                [PSCustomObject]@{
                                    ScopeId        = [System.Net.IPAddress]::Parse('10.40.0.0')
                                    Name           = 'Excluded IT Scope'
                                    Description    = 'Scope on excluded IT server'
                                    SubnetMask     = [System.Net.IPAddress]::Parse('255.255.255.0')
                                    StartRange     = [System.Net.IPAddress]::Parse('10.40.0.10')
                                    EndRange       = [System.Net.IPAddress]::Parse('10.40.0.200')
                                    LeaseDuration  = [timespan]::FromHours(8)
                                    State          = 'Active'
                                    Type           = 'Dhcp'
                                    SuperscopeName = $null
                                }
                            )
                        }
                        default { return @() }
                    }
                }
                'DhcpServerv4ScopeStatistics' {
                    return [PSCustomObject]@{
                        ScopeId         = $ScopeId
                        Free            = 90
                        InUse           = 10
                        Reserved        = 0
                        Pending         = 0
                        AddressesFree   = 90
                        AddressesInUse  = 10
                        PercentageInUse = 10.0
                        SuperscopeName  = $null
                    }
                }
                'DhcpServerv4DnsSetting' {
                    return [PSCustomObject]@{
                        DynamicUpdates             = 'Always'
                        UpdateDnsRRForOlderClients = $true
                        DeleteDnsRROnLeaseExpiry   = $true
                        NameProtection             = $false
                        DisableDnsPtrRRUpdate      = $false
                    }
                }
                'DhcpServerv4OptionValue' {
                    return @(
                        [PSCustomObject]@{
                            OptionId   = 6
                            Name       = 'DNS Servers'
                            Value      = @('10.0.0.2')
                            VendorClass= ''
                            UserClass  = ''
                            PolicyName = ''
                        },
                        [PSCustomObject]@{
                            OptionId   = 15
                            Name       = 'DNS Domain Name'
                            Value      = @('domain.com')
                            VendorClass= ''
                            UserClass  = ''
                            PolicyName = ''
                        }
                    )
                }
                'DhcpServerv4FailoverAll' {
                    switch ($ComputerName) {
                        'corp-dhcp01.domain.com' {
                            return @(
                                [PSCustomObject]@{
                                    Name          = 'FO-Excluded'
                                    PartnerServer = 'usfsm-dhcp01.domain.com'
                                    Mode          = 'LoadBalance'
                                    State         = 'Normal'
                                    ScopeId       = @('10.10.0.0')
                                }
                            )
                        }
                        'corp-dhcp02.domain.com' {
                            return @(
                                [PSCustomObject]@{
                                    Name          = 'FO-Internal'
                                    PartnerServer = 'corp-dhcp01.domain.com'
                                    Mode          = 'LoadBalance'
                                    State         = 'Normal'
                                    ScopeId       = @('10.20.0.0')
                                }
                            )
                        }
                        default { return @() }
                    }
                }
                default {
                    return & $script:origGetTestModeDHCPData @PSBoundParameters
                }
            }
        }
    }

    It 'Excludes prefixed servers and their scopes in minimal mode' {
        $s = Get-WinADDHCPSummary -TestMode -Minimal -ExcludeServerPrefix @('usfsm','it')

        $serverNames = @($s.Servers.ServerName)
        $serverNames.Count | Should -Be 2
        ($serverNames -join ',') | Should -Not -Match 'usfsm-|it-'

        $scopeServerNames = @($s.Scopes.ServerName | Select-Object -Unique)
        $scopeServerNames.Count | Should -Be 2
        ($scopeServerNames -join ',') | Should -Not -Match 'usfsm-|it-'
    }

    It 'Retains an excluded partner as evidence without analyzing that partner as complete' {
        $components = @('Servers','Scopes','ScopeStatistics','Failover','Validation','TimingStatistics')
        $s = Get-WinADDHCPSummary -TestMode -IncludeComponents $components -ExcludeServerPrefix @('usfsm','it')

        $externalRelationship = $s.FailoverRelationships |
            Where-Object { $_.PartnerServer -eq 'usfsm-dhcp01.domain.com' } |
            Select-Object -First 1
        $externalRelationship | Should -Not -BeNullOrEmpty

        $scope10 = $s.Scopes | Where-Object { [string]$_.ScopeId -eq '10.10.0.0' } | Select-Object -First 1
        $scope20 = $s.Scopes | Where-Object { [string]$_.ScopeId -eq '10.20.0.0' } | Select-Object -First 1

        $scope10.FailoverPartner | Should -Be 'usfsm-dhcp01.domain.com'
        $scope10.HasFailover     | Should -BeTrue
        $scope10.FailoverStatus  | Should -Be 'Configured'
        $scope10.Issues          | Should -Not -Contain 'Missing DHCP failover configuration'

        $scope20.FailoverPartner | Should -Be 'corp-dhcp01.domain.com'
        $scope20.HasFailover     | Should -BeTrue

        $analysisServers = @($s.FailoverAnalysis.PerSubnetIssues | ForEach-Object { $_.PrimaryServer, $_.SecondaryServer })
        ($analysisServers -join ',') | Should -Not -Match 'usfsm-|it-'
        @($s.FailoverAnalysis.UnverifiedScopes | Where-Object { $_.SecondaryServer -match 'usfsm-' }).Count | Should -Be 1
    }
}

Describe 'DHCP failover evidence contracts' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    It 'Normalizes provider IPAddress arrays into configured per-scope evidence' {
        InModuleScope ADEssentials {
            $relationships = @(
                [PSCustomObject]@{
                    Name          = 'FO-ProductionShape'
                    PartnerServer = 'dhcp02.domain.com'
                    ScopeId       = [System.Net.IPAddress[]]@(
                        [System.Net.IPAddress]::Parse('10.34.97.0'),
                        [System.Net.IPAddress]::Parse('10.34.100.0')
                    )
                }
            )
            $status = [PSCustomObject]@{ Success = $true }
            $map = New-DHCPFailoverEvidenceMap -Computer 'dhcp01.domain.com' -Relationships $relationships -CollectionStatus $status

            $evidence = Get-DHCPFailoverScopeEvidence -EvidenceMap $map -ScopeId ([System.Net.IPAddress]::Parse('10.34.97.0'))

            $evidence.Status | Should -Be 'Configured'
            $evidence.Verified | Should -BeTrue
            $evidence.PartnerServer | Should -Be 'dhcp02.domain.com'
        }
    }

    It 'Classifies a missing relationship as unknown when enumeration failed' {
        InModuleScope ADEssentials {
            $status = [PSCustomObject]@{ Success = $false; ErrorMessage = 'Access denied' }
            $map = New-DHCPFailoverEvidenceMap -Computer 'dhcp01.domain.com' -Relationships @() -CollectionStatus $status

            $evidence = Get-DHCPFailoverScopeEvidence -EvidenceMap $map -ScopeId '10.34.97.0'
            $scopeObject = [PSCustomObject]@{
                FailoverStatus  = $evidence.Status
                FailoverPartner = $null
                Issues          = [System.Collections.Generic.List[string]]::new()
                HasIssues       = $false
                DNSSettings     = $null
            }
            $scope = [PSCustomObject]@{
                LeaseDuration = [timespan]::FromHours(8)
                Description   = ''
            }

            $evidence.Status | Should -Be 'Unknown'
            $evidence.Verified | Should -BeFalse
            Get-WinADDHCPScopeValidation -Scope $scope -ScopeObject $scopeObject | Should -BeFalse
            $scopeObject.Issues | Should -Not -Contain 'Missing DHCP failover configuration'
        }
    }

    It 'Preserves unknown and not-collected states in downstream redundancy analysis' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Scopes = @(
                    [PSCustomObject]@{
                        ScopeId = '10.34.97.0'; Name = 'Unknown'; ServerName = 'dhcp01.domain.com'
                        State = 'Active'; PercentageInUse = 80; FailoverPartner = $null; FailoverStatus = 'Unknown'
                    },
                    [PSCustomObject]@{
                        ScopeId = '10.34.100.0'; Name = 'Excluded'; ServerName = 'dhcp01.domain.com'
                        State = 'Active'; PercentageInUse = 80; FailoverPartner = $null; FailoverStatus = 'NotCollected'
                    }
                )
                ScopeRedundancyAnalysis = [System.Collections.Generic.List[Object]]::new()
            }

            Get-WinADDHCPScopeRedundancyAnalysis -DHCPSummary $summary

            $summary.ScopeRedundancyAnalysis[0].RedundancyStatus | Should -Be 'Failover Status Unknown'
            $summary.ScopeRedundancyAnalysis[0].RiskLevel | Should -Be 'Unknown'
            $summary.ScopeRedundancyAnalysis[0].Recommendation | Should -Be 'Resolve failover collection errors'
            $summary.ScopeRedundancyAnalysis[1].RedundancyStatus | Should -Be 'Failover Not Collected'
            $summary.ScopeRedundancyAnalysis[1].RiskLevel | Should -Be 'Unknown'
            $summary.ScopeRedundancyAnalysis[1].Recommendation | Should -Be 'Collect failover data'
        }
    }

    It 'Does not mark retained relationships verified when row normalization fails' {
        InModuleScope ADEssentials {
            $good = [PSCustomObject]@{
                Name          = 'FO-Good'
                PartnerServer = 'dhcp02.domain.com'
                Mode          = 'LoadBalance'
                State         = 'Normal'
                ScopeId       = @('10.34.97.0')
            }
            $bad = [PSCustomObject]@{
                Name    = 'FO-Bad'
                Mode    = 'LoadBalance'
                State   = 'Normal'
                ScopeId = @('10.34.100.0')
            }
            Add-Member -InputObject $bad -MemberType ScriptProperty -Name PartnerServer -Value { throw 'Relationship normalization failed' }

            Mock Get-TestModeDHCPData { @($good, $bad) }
            $summary = [ordered]@{
                FailoverRelationships   = [System.Collections.Generic.List[Object]]::new()
                FailoverCollectionStatus = [System.Collections.Generic.List[Object]]::new()
                Errors                  = [System.Collections.Generic.List[Object]]::new()
                Warnings                = [System.Collections.Generic.List[Object]]::new()
            }

            Get-WinADDHCPFailoverRelationships -Computer 'dhcp01.domain.com' -DHCPSummary $summary -TestMode -WarningAction SilentlyContinue

            $summary.FailoverRelationships.Count | Should -Be 1
            $summary.FailoverCollectionStatus.Count | Should -Be 1
            $summary.FailoverCollectionStatus[0].Success | Should -BeFalse
            $summary.FailoverCollectionStatus[0].RelationshipCount | Should -Be 1

            $map = New-DHCPFailoverEvidenceMap -Computer 'dhcp01.domain.com' -Relationships $summary.FailoverRelationships -CollectionStatus $summary.FailoverCollectionStatus[0]
            $evidence = Get-DHCPFailoverScopeEvidence -EvidenceMap $map -ScopeId '10.34.97.0'
            $evidence.Status | Should -Be 'Configured'
            $evidence.Verified | Should -BeFalse
            $evidence.EvidenceSource | Should -Be 'Partial relationship evidence from incomplete enumeration'
        }
    }

    It 'Only treats successful server enumeration as verification evidence' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Servers = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com' }
                )
                CanonicalNameCache = @{}
                FailoverCollectionStatus = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Success = $false }
                )
            }

            $enumerated = Get-DHCPFailoverEnumeratedServerSet -DHCPSummary $summary
            $enumerated.Contains('DHCP01.DOMAIN.COM') | Should -BeTrue
            $enumerated.Contains('dhcp02.domain.com') | Should -BeFalse
        }
    }

    It 'Reports coverage as not assessed when every scope is unverified' {
        InModuleScope ADEssentials {
            $scopes = @(
                [PSCustomObject]@{ State = 'Active'; FailoverStatus = 'Unknown'; FailoverPartner = $null },
                [PSCustomObject]@{ State = 'Active'; FailoverStatus = 'NotCollected'; FailoverPartner = $null }
            )

            $coverage = Get-DHCPFailoverCoverageSummary -Scopes $scopes

            $coverage.ConfiguredCount | Should -Be 0
            $coverage.MissingCount | Should -Be 0
            $coverage.UnverifiedCount | Should -Be 2
            $coverage.AssessedCount | Should -Be 0
            $coverage.Percentage | Should -BeNullOrEmpty
            $coverage.Display | Should -Be 'N/A'
        }
    }

    It 'Uses only active verified scopes in coverage and risk ratings' {
        InModuleScope ADEssentials {
            $scopes = @(
                [PSCustomObject]@{
                    ScopeId = '10.1.0.0'; Name = 'Verified'; ServerName = 'dhcp01.domain.com'; State = 'Active'
                    PercentageInUse = 20; FailoverStatus = 'Configured'; FailoverVerified = $true; FailoverPartner = 'dhcp02.domain.com'
                },
                [PSCustomObject]@{
                    ScopeId = '10.2.0.0'; Name = 'Partial'; ServerName = 'dhcp01.domain.com'; State = 'Active'
                    PercentageInUse = 20; FailoverStatus = 'Configured'; FailoverVerified = $false; FailoverPartner = 'dhcp02.domain.com'
                },
                [PSCustomObject]@{
                    ScopeId = '10.3.0.0'; Name = 'Inactive'; ServerName = 'dhcp01.domain.com'; State = 'Inactive'
                    PercentageInUse = 20; FailoverStatus = 'Configured'; FailoverVerified = $true; FailoverPartner = 'dhcp02.domain.com'
                },
                [PSCustomObject]@{
                    ScopeId = '10.4.0.0'; Name = 'Missing'; ServerName = 'dhcp01.domain.com'; State = 'Active'
                    PercentageInUse = 20; FailoverStatus = 'Missing'; FailoverVerified = $true; FailoverPartner = $null
                }
            )

            $coverage = Get-DHCPFailoverCoverageSummary -Scopes $scopes
            $coverage.ConfiguredCount | Should -Be 1
            $coverage.MissingCount | Should -Be 1
            $coverage.UnverifiedCount | Should -Be 1
            $coverage.Percentage | Should -Be 50

            $summary = [ordered]@{
                Scopes = $scopes
                ScopeRedundancyAnalysis = [System.Collections.Generic.List[Object]]::new()
            }
            Get-WinADDHCPScopeRedundancyAnalysis -DHCPSummary $summary
            $partial = $summary.ScopeRedundancyAnalysis | Where-Object ScopeId -eq '10.2.0.0'
            $partial.RedundancyStatus | Should -Be 'Failover Evidence Unverified'
            $partial.RiskLevel | Should -Be 'Unknown'
            $partial.Recommendation | Should -Be 'Resolve failover collection errors'
        }
    }

    It 'Keeps unknown scopes visible when unrelated relationships exist' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Servers = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp03.domain.com' }
                )
                CanonicalNameCache = @{}
                FailoverCollectionStatus = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp03.domain.com'; Success = $false }
                )
                FailoverRelationships = @(
                    [PSCustomObject]@{
                        ServerName = 'dhcp01.domain.com'; PartnerServer = 'dhcp02.domain.com'; GatheredFrom = 'dhcp01.domain.com'
                        Name = 'FO-Unrelated'; Mode = 'LoadBalance'; State = 'Normal'; ScopeId = @()
                    }
                )
                Scopes = @(
                    [PSCustomObject]@{
                        ServerName = 'dhcp03.domain.com'; ScopeId = '10.30.0.0'; State = 'Active'
                        FailoverStatus = 'Unknown'; FailoverVerified = $false; FailoverPartner = $null
                    }
                )
                FailoverAnalysis = $null
            }

            Get-WinADDHCPFailoverAnalysis -DHCPSummary $summary

            $unknown = @($summary.FailoverAnalysis.UnverifiedScopes | Where-Object ScopeId -eq '10.30.0.0')
            $unknown.Count | Should -Be 1
            $unknown[0].Verified | Should -BeFalse
        }
    }

    It 'Compares partner scopes by normalized server pair when relationship names differ' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Servers = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com' }
                )
                CanonicalNameCache = @{}
                FailoverCollectionStatus = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Success = $true }
                )
                FailoverRelationships = @(
                    [PSCustomObject]@{
                        ServerName = 'dhcp01.domain.com'; PartnerServer = 'dhcp02.domain.com'
                        Name = 'FO-Primary-Name'; ScopeId = @('10.20.0.0')
                    },
                    [PSCustomObject]@{
                        ServerName = 'dhcp02.domain.com'; PartnerServer = 'DHCP01'
                        Name = 'FO-Partner-Name'; ScopeId = @('10.20.0.0')
                    }
                )
                Scopes = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.20.0.0' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; ScopeId = '10.20.0.0' }
                )
            }

            $rows = @(Get-DHCPFailoverPairComparison -DHCPSummary $summary)

            $rows.Count | Should -Be 1
            $rows[0].Relationship | Should -Be 'FO-Partner-Name, FO-Primary-Name'
            $rows[0].OnPartnerA | Should -BeTrue
            $rows[0].OnPartnerB | Should -BeTrue
            $rows[0].VerifiedFromBothSides | Should -BeTrue
            $rows[0].Status | Should -Be 'On both partners'
            $rows[0].FailoverConfiguration | Should -Be 'configured'
        }
    }

    It 'Keeps pair comparison unverified until both partner enumerations succeed' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Servers = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com' }
                )
                CanonicalNameCache = @{}
                FailoverCollectionStatus = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Success = $false }
                )
                FailoverRelationships = @(
                    [PSCustomObject]@{
                        ServerName = 'dhcp01.domain.com'; PartnerServer = 'dhcp02.domain.com'
                        Name = 'FO-Partial'; ScopeId = @('10.30.0.0')
                    }
                )
                Scopes = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.30.0.0' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; ScopeId = '10.30.0.0' }
                )
            }

            $rows = @(Get-DHCPFailoverPairComparison -DHCPSummary $summary)

            $rows.Count | Should -Be 1
            $rows[0].VerifiedFromBothSides | Should -BeFalse
            $rows[0].Status | Should -Be 'Missing on dhcp02.domain.com (Unverified)'
            $rows[0].FailoverConfiguration | Should -Be 'unverified'

            $summary.FailoverCollectionStatus[1].Success = $true
            $verifiedRows = @(Get-DHCPFailoverPairComparison -DHCPSummary $summary)
            $verifiedRows[0].VerifiedFromBothSides | Should -BeTrue
            $verifiedRows[0].Status | Should -Be 'Missing on dhcp02.domain.com'
            $verifiedRows[0].FailoverConfiguration | Should -Be 'missing on one partner'
        }
    }

    It 'Classifies a common scope absent from both relationship assignments as missing on both' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Servers = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com' }
                )
                CanonicalNameCache = @{}
                FailoverCollectionStatus = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Success = $true }
                )
                FailoverRelationships = @(
                    [PSCustomObject]@{
                        ServerName = 'dhcp01.domain.com'; PartnerServer = 'dhcp02.domain.com'
                        Name = 'FO-Empty'; ScopeId = @()
                    },
                    [PSCustomObject]@{
                        ServerName = 'dhcp02.domain.com'; PartnerServer = 'dhcp01.domain.com'
                        Name = 'FO-Empty'; ScopeId = @()
                    }
                )
                Scopes = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; ScopeId = '10.40.0.0' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; ScopeId = '10.40.0.0' }
                )
            }

            $rows = @(Get-DHCPFailoverPairComparison -DHCPSummary $summary)

            $rows.Count | Should -Be 1
            $rows[0].Status | Should -Be 'Missing on both'
            $rows[0].FailoverConfiguration | Should -BeOfType [string]
            $rows[0].FailoverConfiguration | Should -Be 'missing on both'
        }
    }

    It 'Only labels successfully enumerated servers without relationships as standalone' {
        InModuleScope ADEssentials {
            $summary = [ordered]@{
                Servers = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com' },
                    [PSCustomObject]@{ ServerName = 'dhcp03.domain.com' }
                )
                CanonicalNameCache = @{}
                FailoverRelationships = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; PartnerServer = 'dhcp02.domain.com' }
                )
                FailoverCollectionStatus = @(
                    [PSCustomObject]@{ ServerName = 'dhcp01.domain.com'; Success = $true },
                    [PSCustomObject]@{ ServerName = 'dhcp02.domain.com'; Success = $false },
                    [PSCustomObject]@{ ServerName = 'dhcp03.domain.com'; Success = $true }
                )
            }

            $standalone = @(Get-DHCPStandaloneServerName -DHCPSummary $summary)

            $standalone.Count | Should -Be 1
            $standalone[0] | Should -Be 'dhcp03.domain.com'
        }
    }

    It 'Keeps canonical-name caches isolated between summary runs' {
        InModuleScope ADEssentials {
            $first = [ordered]@{
                Servers = @([PSCustomObject]@{ ServerName = 'dhcp01.first.example' })
                CanonicalNameCache = @{}
            }
            $second = [ordered]@{
                Servers = @([PSCustomObject]@{ ServerName = 'dhcp01.second.example' })
                CanonicalNameCache = @{}
            }

            Resolve-DHCPServerName -Name 'dhcp01' -DHCPSummary $first | Should -Be 'dhcp01.first.example'
            Resolve-DHCPServerName -Name 'dhcp01' -DHCPSummary $second | Should -Be 'dhcp01.second.example'
        }
    }

    It 'Runs full TestMode without falling through to live DHCP collection' {
        $warnings = @()
        $errors = @()

        $summary = Get-WinADDHCPSummary -TestMode -WarningVariable warnings -ErrorVariable errors

        $summary.Scopes.Count | Should -BeGreaterThan 0
        $summary.Errors.Count | Should -Be 0
        $warnings.Count | Should -Be 0
        $errors.Count | Should -Be 0
        $summary.AuditLogs.Count | Should -Be $summary.Servers.Count
        $summary.Databases.Count | Should -Be $summary.Servers.Count
        $summary.ServerSettings.Count | Should -Be $summary.Servers.Count
        $summary.NetworkBindings.Count | Should -Be $summary.Servers.Count
        $summary.SecurityFilters.Count | Should -Be $summary.Servers.Count
        @($summary.AuditLogs | Where-Object { $null -eq $_.Enable -or [string]::IsNullOrWhiteSpace($_.Path) }).Count | Should -Be 0
        @($summary.Databases | Where-Object { [string]::IsNullOrWhiteSpace($_.FileName) -or [string]::IsNullOrWhiteSpace($_.BackupPath) }).Count | Should -Be 0
        @($summary.ServerSettings | Where-Object { -not $_.IsAuthorized -or -not $_.IsDomainJoined }).Count | Should -Be 0
        @($summary.SecurityFilters | Where-Object FilteringMode -eq 'None').Count | Should -Be 0
    }
}

