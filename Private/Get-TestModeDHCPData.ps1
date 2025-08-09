function Get-TestModeDHCPData {
    <#
    .SYNOPSIS
    Provides test data for DHCP cmdlet mocking when TestMode is enabled.
    
    .DESCRIPTION
    This function returns test data that mimics the output of various DHCP cmdlets,
    allowing the full code path to be tested without requiring actual DHCP servers.
    
    .PARAMETER DataType
    The type of data to return (e.g., 'DhcpServersInDC', 'DhcpServerv4Scope', etc.)
    
    .PARAMETER ComputerName
    The computer name to generate data for.
    
    .PARAMETER ScopeId
    The scope ID when requesting scope-specific data.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $DataType,
        
        [string] $ComputerName,
        
        [string] $ScopeId
    )
    
    switch ($DataType) {
        'DhcpServersInDC' {
            # Mimics Get-DhcpServerInDC output
            return @(
                [PSCustomObject]@{
                    DnsName = 'dhcp01.domain.com'
                    IPAddress = '192.168.1.10'
                },
                [PSCustomObject]@{
                    DnsName = 'dhcp02.domain.com'
                    IPAddress = '192.168.1.11'
                },
                [PSCustomObject]@{
                    DnsName = 'dc01.domain.com'
                    IPAddress = '192.168.1.5'
                }
            )
        }
        
        'DhcpServerVersion' {
            # Mimics Get-DhcpServerVersion output
            if ($ComputerName -eq 'dhcp02.domain.com') {
                throw "Unable to contact DHCP server"
            }
            return [PSCustomObject]@{
                MajorVersion = 10
                MinorVersion = 0
                BuildNumber = 19041
            }
        }
        
        'DhcpServerv4Scope' {
            # Mimics Get-DhcpServerv4Scope output
            switch ($ComputerName) {
                'dhcp01.domain.com' {
                    return @(
                        [PSCustomObject]@{
                            ScopeId = [System.Net.IPAddress]::Parse('192.168.1.0')
                            Name = 'Corporate LAN'
                            Description = 'Main corporate network'
                            SubnetMask = [System.Net.IPAddress]::Parse('255.255.255.0')
                            StartRange = [System.Net.IPAddress]::Parse('192.168.1.10')
                            EndRange = [System.Net.IPAddress]::Parse('192.168.1.250')
                            LeaseDuration = [timespan]::FromHours(8)
                            State = 'Active'
                            Type = 'Dhcp'
                            SuperscopeName = $null
                        },
                        [PSCustomObject]@{
                            ScopeId = [System.Net.IPAddress]::Parse('10.1.0.0')
                            Name = 'Guest Network'
                            Description = 'Guest WiFi network'
                            SubnetMask = [System.Net.IPAddress]::Parse('255.255.255.0')
                            StartRange = [System.Net.IPAddress]::Parse('10.1.0.10')
                            EndRange = [System.Net.IPAddress]::Parse('10.1.0.200')
                            LeaseDuration = [timespan]::FromHours(4)
                            State = 'Active'
                            Type = 'Dhcp'
                            SuperscopeName = $null
                        }
                    )
                }
                'dhcp02.domain.com' {
                    throw "Unable to contact DHCP server"
                }
                'dc01.domain.com' {
                    return @(
                        [PSCustomObject]@{
                            ScopeId = [System.Net.IPAddress]::Parse('172.16.1.0')
                            Name = 'Server VLAN'
                            Description = 'Server infrastructure - 7 day lease'
                            SubnetMask = [System.Net.IPAddress]::Parse('255.255.255.0')
                            StartRange = [System.Net.IPAddress]::Parse('172.16.1.10')
                            EndRange = [System.Net.IPAddress]::Parse('172.16.1.100')
                            LeaseDuration = [timespan]::FromDays(7)
                            State = 'Active'
                            Type = 'Dhcp'
                            SuperscopeName = $null
                        }
                    )
                }
                default { return @() }
            }
        }
        
        'DhcpServerv4ScopeStatistics' {
            # Mimics Get-DhcpServerv4ScopeStatistics output
            switch ("$ComputerName-$ScopeId") {
                'dhcp01.domain.com-192.168.1.0' {
                    return [PSCustomObject]@{
                        ScopeId = $ScopeId
                        Free = 30
                        InUse = 170
                        Reserved = 5
                        Pending = 0
                        AddressesFree = 30
                        AddressesInUse = 170
                        PercentageInUse = 85.0
                        SuperscopeName = $null
                    }
                }
                'dhcp01.domain.com-10.1.0.0' {
                    return [PSCustomObject]@{
                        ScopeId = $ScopeId
                        Free = 150
                        InUse = 40
                        Reserved = 0
                        Pending = 0
                        AddressesFree = 150
                        AddressesInUse = 40
                        PercentageInUse = 21.05
                        SuperscopeName = $null
                    }
                }
                'dc01.domain.com-172.16.1.0' {
                    return [PSCustomObject]@{
                        ScopeId = $ScopeId
                        Free = 8
                        InUse = 82
                        Reserved = 1
                        Pending = 0
                        AddressesFree = 8
                        AddressesInUse = 82
                        PercentageInUse = 91.11
                        SuperscopeName = $null
                    }
                }
                default {
                    return [PSCustomObject]@{
                        ScopeId = $ScopeId
                        Free = 100
                        InUse = 50
                        Reserved = 0
                        Pending = 0
                        AddressesFree = 100
                        AddressesInUse = 50
                        PercentageInUse = 33.33
                        SuperscopeName = $null
                    }
                }
            }
        }
        
        'DhcpServerv4DnsSetting' {
            # Mimics Get-DhcpServerv4DnsSetting output
            switch ("$ComputerName-$ScopeId") {
                'dhcp01.domain.com-192.168.1.0' {
                    return [PSCustomObject]@{
                        DynamicUpdates = 'OnClientRequest'
                        UpdateDnsRRForOlderClients = $true
                        DeleteDnsRROnLeaseExpiry = $true
                        NameProtection = $false
                        DisableDnsPtrRRUpdate = $false
                    }
                }
                'dhcp01.domain.com-10.1.0.0' {
                    return [PSCustomObject]@{
                        DynamicUpdates = 'Never'
                        UpdateDnsRRForOlderClients = $false
                        DeleteDnsRROnLeaseExpiry = $false
                        NameProtection = $false
                        DisableDnsPtrRRUpdate = $true
                    }
                }
                'dc01.domain.com-172.16.1.0' {
                    return [PSCustomObject]@{
                        DynamicUpdates = 'Always'
                        UpdateDnsRRForOlderClients = $false  # This will trigger an issue
                        DeleteDnsRROnLeaseExpiry = $true
                        NameProtection = $true
                        DisableDnsPtrRRUpdate = $false
                    }
                }
                default {
                    return [PSCustomObject]@{
                        DynamicUpdates = 'OnClientRequest'
                        UpdateDnsRRForOlderClients = $true
                        DeleteDnsRROnLeaseExpiry = $true
                        NameProtection = $false
                        DisableDnsPtrRRUpdate = $false
                    }
                }
            }
        }
        
        'DhcpServerv4OptionValue' {
            # Mimics Get-DhcpServerv4OptionValue output for scope options
            switch ("$ComputerName-$ScopeId") {
                'dhcp01.domain.com-192.168.1.0' {
                    return @(
                        [PSCustomObject]@{
                            OptionId = 3
                            Name = 'Router'
                            Value = @('192.168.1.1')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        },
                        [PSCustomObject]@{
                            OptionId = 6
                            Name = 'DNS Servers'
                            Value = @('192.168.1.2', '192.168.1.3')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        },
                        [PSCustomObject]@{
                            OptionId = 15
                            Name = 'DNS Domain Name'
                            Value = @('domain.com')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        }
                    )
                }
                'dhcp01.domain.com-10.1.0.0' {
                    return @(
                        [PSCustomObject]@{
                            OptionId = 3
                            Name = 'Router'
                            Value = @('10.1.0.1')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        },
                        [PSCustomObject]@{
                            OptionId = 6
                            Name = 'DNS Servers'
                            Value = @('8.8.8.8', '8.8.4.4')  # Public DNS - will trigger issue
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        }
                        # Missing domain name option - will trigger issue
                    )
                }
                'dc01.domain.com-172.16.1.0' {
                    return @(
                        [PSCustomObject]@{
                            OptionId = 3
                            Name = 'Router'
                            Value = @('172.16.1.1')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        },
                        [PSCustomObject]@{
                            OptionId = 6
                            Name = 'DNS Servers'
                            Value = @('172.16.1.2', '172.16.1.3')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        },
                        [PSCustomObject]@{
                            OptionId = 15
                            Name = 'DNS Domain Name'
                            Value = @('domain.com')
                            VendorClass = ''
                            UserClass = ''
                            PolicyName = ''
                        }
                    )
                }
                default { return @() }
            }
        }
        
        'DhcpServerv4OptionValueAll' {
            # Server-level options
            if ($ComputerName -eq 'dhcp01.domain.com') {
                return @(
                    [PSCustomObject]@{
                        OptionId = 6
                        Name = 'DNS Servers'
                        Value = @('192.168.1.2', '192.168.1.3')
                        VendorClass = ''
                        UserClass = ''
                        PolicyName = ''
                    },
                    [PSCustomObject]@{
                        OptionId = 15
                        Name = 'DNS Domain Name'
                        Value = @('domain.com')
                        VendorClass = ''
                        UserClass = ''
                        PolicyName = ''
                    }
                )
            }
            return @()
        }
        
        'DhcpServerv4Failover' {
            # Mimics Get-DhcpServerv4Failover output
            if ($ComputerName -eq 'dhcp01.domain.com' -and $ScopeId -eq '10.1.0.0') {
                return [PSCustomObject]@{
                    Name = 'dhcp01-dhcp02-failover'
                    PartnerServer = 'dhcp02.domain.com'
                    Mode = 'LoadBalance'
                    State = 'Normal'
                    ScopeId = $ScopeId
                }
            }
            return $null
        }
        
        'DhcpServerv4Class' {
            if ($ComputerName -eq 'dhcp01.domain.com') {
                return @(
                    [PSCustomObject]@{
                        Name = 'Microsoft Windows 2000 Options'
                        Type = 'Vendor'
                        Data = 'MSFT 5.0'
                        Description = 'Microsoft Windows 2000 vendor class'
                    },
                    [PSCustomObject]@{
                        Name = 'Corporate Laptops'
                        Type = 'User'
                        Data = 'CORP-LAPTOP'
                        Description = 'Corporate laptop user class'
                    }
                )
            }
            return @()
        }
        
        default {
            return $null
        }
    }
}