function Get-WinADBitlockerLapsSummary {
    <#
    .SYNOPSIS
    Retrieves BitLocker and LAPS information for computers in Active Directory.

    .DESCRIPTION
    This function retrieves BitLocker and LAPS information for computers in Active Directory based on the specified parameters.

    .PARAMETER Forest
    Specifies the name of the forest to query for computer information.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include in the query.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from the query.

    .PARAMETER Filter
    Specifies the filter to apply when querying for computers.

    .PARAMETER SearchBase
    Specifies the search base for the query.

    .PARAMETER SearchScope
    Specifies the scope of the search (Base, OneLevel, SubTree, None).

    .PARAMETER LapsOnly
    Switch to retrieve only LAPS information.

    .PARAMETER BitlockerOnly
    Switch to retrieve only BitLocker information.

    .PARAMETER ExtendedForestInformation
    Specifies additional forest information to include in the query.

    .EXAMPLE
    Get-WinADBitlockerLapsSummary -Forest "contoso.com" -IncludeDomains "child1.contoso.com", "child2.contoso.com" -ExcludeDomains "test.contoso.com" -LapsOnly
    Retrieves LAPS information for computers in the specified domains of the "contoso.com" forest, excluding "test.contoso.com".

    .EXAMPLE
    Get-WinADBitlockerLapsSummary -Forest "contoso.com" -IncludeDomains "child1.contoso.com", "child2.contoso.com" -ExcludeDomains "test.contoso.com" -BitlockerOnly
    Retrieves BitLocker information for computers in the specified domains of the "contoso.com" forest, excluding "test.contoso.com".

    .NOTES
    General notes
    #>
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
    $Properties = @(
        'Name'
        'OperatingSystem'
        'OperatingSystemVersion'
        'DistinguishedName'
        'LastLogonDate'
        'PasswordLastSet'
        'PrimaryGroupID'
        if ($ComputerProperties.Name -contains 'ms-Mcs-AdmPwd') {
            $LapsAvailable = $true
            'ms-Mcs-AdmPwd'
            'ms-Mcs-AdmPwdExpirationTime'
        } else {
            $LapsAvailable = $false
        }
        if ($ComputerProperties.Name -contains 'msLAPS-Password') {
            $WindowsLapsAvailable = $true
            'msLAPS-PasswordExpirationTime'
            'msLAPS-Password'
            'msLAPS-EncryptedPassword'
            'msLAPS-EncryptedPasswordHistory'
            'msLAPS-EncryptedDSRMPassword'
            'msLAPS-EncryptedDSRMPasswordHistory'
        } else {
            $WindowsLapsAvailable = $false
        }
    )
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
                    $Laps = $null
                }
            }

            if ($WindowsLapsAvailable) {
                if ($_.'msLAPS-PasswordExpirationTime') {
                    $WindowsLaps = $true
                    $WindowsLapsExpirationDays = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring ($_.'msLAPS-PasswordExpirationTime'))
                    $WindowsLapsExpirationTime = Convert-ToDateTime -Timestring ($_.'msLAPS-PasswordExpirationTime')
                    $WindowsLapsHistoryCount = $_.'msLAPS-EncryptedPasswordHistory'.Count
                } else {
                    $WindowsLaps = $false
                    $WindowsLapsExpirationDays = $null
                    $WindowsLapsExpirationTime = $null
                    $WindowsLapsHistoryCount = 0
                }
            } else {
                $WindowsLaps = $null
                $WindowsLapsExpirationDays = $null
                $WindowsLapsExpirationTime = $null
                $WindowsLapsHistoryCount = 0
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
                    Name                      = $_.Name
                    Enabled                   = $_.Enabled
                    Domain                    = $Domain
                    DNSHostName               = $_.DNSHostName
                    IsDC                      = if ($_.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Laps                      = $Laps
                    LapsExpirationDays        = $LapsExpirationDays
                    LapsExpirationTime        = $LapsExpirationTime
                    WindowsLaps               = $WindowsLaps
                    WindowsLapsExpirationDays = $WindowsLapsExpirationDays
                    WindowsLapsExpirationTime = $WindowsLapsExpirationTime
                    WindowsLapsHistoryCount   = $WindowsLapsHistoryCount
                    System                    = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
                    LastLogonDate             = $_.LastLogonDate
                    LastLogonDays             = $LastLogonDays
                    PasswordLastSet           = $_.PasswordLastSet
                    PasswordLastChangedDays   = $PasswordLastChangedDays
                    OrganizationalUnit        = ConvertFrom-DistinguishedName -DistinguishedName $_.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName         = $_.DistinguishedName
                }
            } elseif ($BitlockerOnly) {
                [PSCustomObject] @{
                    Name                    = $_.Name
                    Enabled                 = $_.Enabled
                    Domain                  = $Domain
                    DNSHostName             = $_.DNSHostName
                    IsDC                    = if ($_.PrimaryGroupID -in 516, 521) { $true } else { $false }
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
                    Name                      = $_.Name
                    Enabled                   = $_.Enabled
                    Domain                    = $Domain
                    DNSHostName               = $_.DNSHostName
                    IsDC                      = if ($_.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Encrypted                 = $Encrypted
                    EncryptedTime             = $EncryptedTime
                    Laps                      = $Laps
                    LapsExpirationDays        = $LapsExpirationDays
                    LapsExpirationTime        = $LapsExpirationTime
                    WindowsLaps               = $WindowsLaps
                    WindowsLapsExpirationDays = $WindowsLapsExpirationDays
                    WindowsLapsExpirationTime = $WindowsLapsExpirationTime
                    WindowsLapsHistoryCount   = $WindowsLapsHistoryCount
                    System                    = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
                    LastLogonDate             = $_.LastLogonDate
                    LastLogonDays             = $LastLogonDays
                    PasswordLastSet           = $_.PasswordLastSet
                    PasswordLastChangedDays   = $PasswordLastChangedDays
                    OrganizationalUnit        = ConvertFrom-DistinguishedName -DistinguishedName $_.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName         = $_.DistinguishedName
                }
            }
        }
    }
    $FormattedComputers
}