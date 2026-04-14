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

    It 'Excludes prefixed servers from failover relationships, maps, and analysis in full mode' {
        $components = @('Servers','Scopes','ScopeStatistics','Failover','Validation','TimingStatistics')
        $s = Get-WinADDHCPSummary -TestMode -IncludeComponents $components -ExcludeServerPrefix @('usfsm','it')

        $relServers = @($s.FailoverRelationships | ForEach-Object { $_.ServerName, $_.PartnerServer })
        ($relServers -join ',') | Should -Not -Match 'usfsm-|it-'

        $scope10 = $s.Scopes | Where-Object { [string]$_.ScopeId -eq '10.10.0.0' } | Select-Object -First 1
        $scope20 = $s.Scopes | Where-Object { [string]$_.ScopeId -eq '10.20.0.0' } | Select-Object -First 1

        $scope10.FailoverPartner | Should -BeNullOrEmpty
        $scope10.HasFailover     | Should -BeFalse

        $scope20.FailoverPartner | Should -Be 'corp-dhcp01.domain.com'
        $scope20.HasFailover     | Should -BeTrue

        $analysisServers = @($s.FailoverAnalysis.PerSubnetIssues | ForEach-Object { $_.PrimaryServer, $_.SecondaryServer })
        ($analysisServers -join ',') | Should -Not -Match 'usfsm-|it-'
    }
}

