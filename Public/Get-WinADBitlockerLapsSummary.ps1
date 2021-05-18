﻿function Get-WinADBitlockerLapsSummary {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [alias('ForestName')][string] $Forest,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [string[]] $ExcludeDomains,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [string] $Filter = '*',

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [string] $SearchBase,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [ValidateSet('Base', 'OneLevel', 'SubTree', 'None')] [string] $SearchScope = 'None',


        [Parameter(ParameterSetName = 'LapsOnly')][switch] $LapsOnly,
        [Parameter(ParameterSetName = 'BitlockerOnly')][switch] $BitlockerOnly,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'LapsOnly')]
        [Parameter(ParameterSetName = 'BitlockerOnly')]
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    $ComputerProperties = Get-WinADForestSchemaProperties -Schema 'Computers' -Forest $Forest -ExtendedForestInformation $ForestInformation
    if ($ComputerProperties.Name -contains 'ms-Mcs-AdmPwd') {
        $LapsAvailable = $true
        $Properties = @(
            'Name'
            'OperatingSystem'
            'OperatingSystemVersion'
            'DistinguishedName'
            'LastLogonDate'
            'PasswordLastSet'
            'ms-Mcs-AdmPwd'
            'ms-Mcs-AdmPwdExpirationTime'
            'PrimaryGroupID'
        )
    } else {
        $LapsAvailable = $false
        $Properties = @(
            'Name'
            'OperatingSystem'
            'OperatingSystemVersion'
            'DistinguishedName'
            'LastLogonDate'
            'PasswordLastSet'
            'PrimaryGroupID'
        )
    }
    $CurrentDate = Get-Date
    $FormattedComputers = foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Parameters = @{ }
        if ($SearchScope -ne 'None') {
            $Parameters.SearchScope = $SearchScope
        }
        if ($SearchBase) {
            # If SearchBase is defined we need to check it belongs to current domain
            # if it does, great. If not we need to skip it
            $DomainInformation = Get-ADDomain -Server $QueryServer
            $DNExtract = ConvertFrom-DistinguishedName -DistinguishedName $SearchBase -ToDC
            if ($DNExtract -eq $DomainInformation.DistinguishedName) {
                $Parameters.SearchBase = $SearchBase
            } else {
                continue
            }
        }
        try {
            $Computers = Get-ADComputer -Filter $Filter -Properties $Properties -Server $QueryServer @Parameters -ErrorAction Stop
        } catch {
            Write-Warning "Get-WinADBitlockerLapsSummary - Error getting computers $($_.Exception.Message)"
        }

        foreach ($_ in $Computers) {
            if ($LapsOnly -or -not $BitlockerOnly) {
                if ($LapsAvailable) {
                    # if ($_.'ms-Mcs-AdmPwd') {
                    if ($_.'ms-Mcs-AdmPwdExpirationTime') {
                        $Laps = $true
                        $LapsExpirationDays = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring ($_.'ms-Mcs-AdmPwdExpirationTime'))
                        $LapsExpirationTime = Convert-ToDateTime -Timestring ($_.'ms-Mcs-AdmPwdExpirationTime')
                    } else {
                        $Laps = $false
                        $LapsExpirationDays = $null
                        $LapsExpirationTime = $null
                    }
                } else {
                    $Laps = 'N/A'
                }
            }
            if (-not $LapsOnly -or $BitlockerOnly) {
                [Array] $Bitlockers = Get-ADObject -Server $QueryServer -Filter 'objectClass -eq "msFVE-RecoveryInformation"' -SearchBase $_.DistinguishedName -Properties 'WhenCreated', 'msFVE-RecoveryPassword' | Sort-Object -Descending
                if ($Bitlockers) {
                    $Encrypted = $true
                    $EncryptedTime = $Bitlockers[0].WhenCreated
                } else {
                    $Encrypted = $false
                    $EncryptedTime = $null
                }
            }
            if ($null -ne $_.LastLogonDate) {
                [int] $LastLogonDays = "$(-$($_.LastLogonDate - $Today).Days)"
            } else {
                $LastLogonDays = $null
            }
            if ($null -ne $_.PasswordLastSet) {
                [int] $PasswordLastChangedDays = "$(-$($_.PasswordLastSet - $Today).Days)"
            } else {
                $PasswordLastChangedDays = $null
            }

            if ($LapsOnly) {
                [PSCustomObject] @{
                    Name                    = $_.Name
                    Enabled                 = $_.Enabled
                    Domain                  = $Domain
                    DNSHostName             = $_.DNSHostName
                    IsDC                    = if ($_.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Laps                    = $Laps
                    LapsExpirationDays      = $LapsExpirationDays
                    LapsExpirationTime      = $LapsExpirationTime
                    System                  = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
                    LastLogonDate           = $_.LastLogonDate
                    LastLogonDays           = $LastLogonDays
                    PasswordLastSet         = $_.PasswordLastSet
                    PasswordLastChangedDays = $PasswordLastChangedDays
                    OrganizationalUnit      = ConvertFrom-DistinguishedName -DistinguishedName $_.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName       = $_.DistinguishedName
                }
            } elseif ($BitlockerOnly) {
                [PSCustomObject] @{
                    Name                    = $_.Name
                    Enabled                 = $_.Enabled
                    Domain                  = $Domain
                    DNSHostName             = $_.DNSHostName
                    IsDC                    = if ($Computer.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Encrypted               = $Encrypted
                    EncryptedTime           = $EncryptedTime
                    System                  = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
                    LastLogonDate           = $_.LastLogonDate
                    LastLogonDays           = $LastLogonDays
                    PasswordLastSet         = $_.PasswordLastSet
                    PasswordLastChangedDays = $PasswordLastChangedDays
                    OrganizationalUnit      = ConvertFrom-DistinguishedName -DistinguishedName $_.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName       = $_.DistinguishedName
                }
            } else {
                [PSCustomObject] @{
                    Name                    = $_.Name
                    Enabled                 = $_.Enabled
                    Domain                  = $Domain
                    DNSHostName             = $_.DNSHostName
                    IsDC                    = if ($Computer.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Encrypted               = $Encrypted
                    EncryptedTime           = $EncryptedTime
                    Laps                    = $Laps
                    LapsExpirationDays      = $LapsExpirationDays
                    LapsExpirationTime      = $LapsExpirationTime
                    System                  = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
                    LastLogonDate           = $_.LastLogonDate
                    LastLogonDays           = $LastLogonDays
                    PasswordLastSet         = $_.PasswordLastSet
                    PasswordLastChangedDays = $PasswordLastChangedDays
                    OrganizationalUnit      = ConvertFrom-DistinguishedName -DistinguishedName $_.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName       = $_.DistinguishedName
                }
            }
        }
    }
    $FormattedComputers
}