function global:Get-ADRootDSE {
    param()

    & $global:GetADRootDSEImpl @PSBoundParameters
}

function global:Get-DnsServerZone {
    param(
        [string] $ComputerName
    )

    & $global:GetDnsServerZoneImpl @PSBoundParameters
}

function global:Get-DnsServerResourceRecord {
    param(
        [string] $ComputerName,
        [string] $ZoneName,
        [string] $RRType
    )

    & $global:GetDnsServerResourceRecordImpl @PSBoundParameters
}

function global:Get-ADObject {
    param(
        [string] $Server,
        [string] $Filter,
        [string] $SearchBase,
        [object[]] $Properties
    )

    & $global:GetADObjectImpl @PSBoundParameters
}

Describe 'DNS record enumeration' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    BeforeEach {
        $global:lastSearchBase = $null

        $global:GetADRootDSEImpl = {
            [PSCustomObject] @{
                dnsHostName             = 'dc01.child.parent.local'
                defaultNamingContext    = 'DC=child,DC=parent,DC=local'
                rootDomainNamingContext = 'DC=parent,DC=local'
            }
        }

        $global:GetDnsServerZoneImpl = {
            @(
                [PSCustomObject] @{
                    ZoneName            = 'child.parent.local'
                    ZoneType            = 'Primary'
                    IsDsIntegrated      = $true
                    IsReverseLookupZone = $false
                    ReplicationScope    = 'Forest'
                    DistinguishedName   = $null
                }
            )
        }

        $global:GetDnsServerResourceRecordImpl = {
            @(
                [PSCustomObject] @{
                    HostName   = 'server1'
                    TimeStamp  = $null
                    RecordData = [PSCustomObject] @{
                        IPv4Address = '10.0.0.10'
                    }
                }
            )
        }

        $global:GetADObjectImpl = {
            throw 'Get-ADObject should be mocked per test.'
        }
    }

    It 'returns DNS-backed entries without IncludeDetails' {
        $result = Get-WinDNSRecords

        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 1
        $result[0].HostName | Should -Be 'server1'
        $result[0].Zone | Should -Be 'child.parent.local'
        $result[0].RecordIP | Should -Contain '10.0.0.10'
    }

    It 'uses the forest root naming context for child-domain forest zones when details are requested' {
        $global:GetADObjectImpl = {
            param(
                [string] $Server,
                [string] $Filter,
                [string] $SearchBase,
                [object[]] $Properties
            )

            $global:lastSearchBase = $SearchBase

            @(
                [PSCustomObject] @{
                    Name                          = 'server1'
                    whenCreated                   = [datetime]'2025-01-01'
                    whenChanged                   = [datetime]'2025-01-02'
                    DistinguishedName             = 'DC=server1,DC=child.parent.local,CN=MicrosoftDNS,DC=ForestDnsZones,DC=parent,DC=local'
                    ProtectedFromAccidentalDeletion = $false
                    dNSTombstoned                 = $false
                    nTSecurityDescriptor          = [PSCustomObject] @{
                        Owner = 'CONTOSO\Domain Admins'
                    }
                }
            )
        }

        $result = Get-WinDNSRecords -IncludeDetails

        $global:lastSearchBase | Should -Be 'DC=child.parent.local,CN=MicrosoftDNS,DC=ForestDnsZones,DC=parent,DC=local'
        $result | Should -Not -BeNullOrEmpty
        $result[0].WhenCreated | Should -Be ([datetime]'2025-01-01')
    }

    It 'keeps returning DNS results when AD enrichment for details fails' {
        $global:GetADObjectImpl = {
            throw 'Directory object not found.'
        }

        $result = Get-WinDNSRecords -IncludeDetails

        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 1
        $result[0].HostName | Should -Be 'server1'
        $result[0].RecordIP | Should -Contain '10.0.0.10'
    }
}

Describe 'DNS IP enumeration' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../ADEssentials.psm1" -Force
    }

    BeforeEach {
        $global:lastIpSearchBase = $null

        $global:GetADRootDSEImpl = {
            [PSCustomObject] @{
                dnsHostName             = 'dc01.child.parent.local'
                defaultNamingContext    = 'DC=child,DC=parent,DC=local'
                rootDomainNamingContext = 'DC=parent,DC=local'
            }
        }

        $global:GetDnsServerZoneImpl = {
            @(
                [PSCustomObject] @{
                    ZoneName            = 'child.parent.local'
                    ZoneType            = 'Primary'
                    IsDsIntegrated      = $true
                    IsReverseLookupZone = $false
                    ReplicationScope    = 'Forest'
                    DistinguishedName   = $null
                }
            )
        }

        $global:GetDnsServerResourceRecordImpl = {
            @(
                [PSCustomObject] @{
                    HostName   = 'server1'
                    TimeStamp  = $null
                    RecordData = [PSCustomObject] @{
                        IPv4Address = '10.0.0.10'
                    }
                }
            )
        }

        $global:GetADObjectImpl = {
            throw 'Get-ADObject should be mocked per test.'
        }
    }

    It 'uses the forest root naming context for child-domain forest zones in IP lookups' {
        $global:GetADObjectImpl = {
            param(
                [string] $Server,
                [string] $Filter,
                [string] $SearchBase,
                [object[]] $Properties
            )

            $global:lastIpSearchBase = $SearchBase

            @(
                [PSCustomObject] @{
                    Name          = 'server1'
                    whenCreated   = [datetime]'2025-01-01'
                    whenChanged   = [datetime]'2025-01-02'
                    dNSTombstoned = $false
                }
            )
        }

        $result = Get-WinADDnsIPAddresses -IncludeDetails

        $global:lastIpSearchBase | Should -Be 'DC=child.parent.local,CN=MicrosoftDNS,DC=ForestDnsZones,DC=parent,DC=local'
        $result | Should -Not -BeNullOrEmpty
        $result[0].IPAddress | Should -Be '10.0.0.10'
    }
}
