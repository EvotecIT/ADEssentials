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

        foreach ($C in $Computers) {
            if ($LapsOnly -or -not $BitlockerOnly) {
                if ($LapsAvailable) {
                    if ($C.'ms-Mcs-AdmPwdExpirationTime') {
                        $Laps = $true
                        $LapsExpirationDays = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring ($C.'ms-Mcs-AdmPwdExpirationTime'))
                        $LapsExpirationTime = Convert-ToDateTime -Timestring ($C.'ms-Mcs-AdmPwdExpirationTime')
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
                # Standard Windows LAPS (local Administrator) - applicable to non-DCs
                $WindowsLapsStandard = $false
                if ($C.'msLAPS-PasswordExpirationTime') {
                    $WindowsLapsStandard = $true
                    $WindowsLapsExpirationDays = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring ($C.'msLAPS-PasswordExpirationTime'))
                    $WindowsLapsExpirationTime = Convert-ToDateTime -Timestring ($C.'msLAPS-PasswordExpirationTime')
                } else {
                    $WindowsLapsExpirationDays = $null
                    $WindowsLapsExpirationTime = $null
                }

                # Windows LAPS for DSRM (Domain Controllers)
                $WindowsLapsDSRM = $false
                if ($C.'msLAPS-EncryptedDSRMPassword') {
                    $WindowsLapsDSRM = $true
                }

                if ($WindowsLapsStandard -or $WindowsLapsDSRM) {
                    $WindowsLaps = $true
                    # History count: use standard history for non-DCs else DSRM history for DCs
                    if ($WindowsLapsStandard) {
                        $WindowsLapsHistoryCount = $C.'msLAPS-EncryptedPasswordHistory'.Count
                    } elseif ($WindowsLapsDSRM) {
                        $WindowsLapsHistoryCount = $C.'msLAPS-EncryptedDSRMPasswordHistory'.Count
                    } else {
                        $WindowsLapsHistoryCount = 0
                    }
                    $WindowsLapsSetTime = Get-LAPSADUpdateTimeComputer -ADComputer $C
                    $WindowsLapsSetTimeDays = - (Convert-TimeToDays -StartTime ($CurrentDate) -EndTime $WindowsLapsSetTime)
                } else {
                    $WindowsLaps = $false
                    $WindowsLapsHistoryCount = 0
                    $WindowsLapsSetTime = $null
                    $WindowsLapsSetTimeDays = $null
                }
            } else {
                $WindowsLaps = $null
                $WindowsLapsExpirationDays = $null
                $WindowsLapsExpirationTime = $null
                $WindowsLapsHistoryCount = 0
                $WindowsLapsSetTime = $null
                $WindowsLapsSetTimeDays = $null
            }

            if (-not $LapsOnly -or $BitlockerOnly) {
                [Array] $Bitlockers = Get-ADObject -Server $QueryServer -Filter 'objectClass -eq "msFVE-RecoveryInformation"' -SearchBase $C.DistinguishedName -Properties 'WhenCreated', 'msFVE-RecoveryPassword' | Sort-Object -Descending
                if ($Bitlockers) {
                    $Encrypted = $true
                    $EncryptedTime = $Bitlockers[0].WhenCreated
                    $EncryptedDays = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime ($Bitlockers[0].WhenCreated)
                } else {
                    $Encrypted = $false
                    $EncryptedTime = $null
                    $EncryptedDays = $null
                }
            }
            if ($null -ne $C.LastLogonDate) {
                [int] $LastLogonDays = "$(-$($C.LastLogonDate - $Today).Days)"
            } else {
                $LastLogonDays = $null
            }
            if ($null -ne $C.PasswordLastSet) {
                [int] $PasswordLastChangedDays = "$(-$($C.PasswordLastSet - $Today).Days)"
            } else {
                $PasswordLastChangedDays = $null
            }

            if ($LapsOnly) {
                [PSCustomObject] @{
                    Name                      = $C.Name
                    Enabled                   = $C.Enabled
                    Domain                    = $Domain
                    DNSHostName               = $C.DNSHostName
                    IsDC                      = if ($C.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Laps                      = $Laps
                    LapsExpirationDays        = $LapsExpirationDays
                    LapsExpirationTime        = $LapsExpirationTime
                    WindowsLaps               = $WindowsLaps
                    WindowsLapsExpirationDays = $WindowsLapsExpirationDays
                    WindowsLapsExpirationTime = $WindowsLapsExpirationTime
                    WindowsLapsHistoryCount   = $WindowsLapsHistoryCount
                    WindowsLapsSetTime        = $WindowsLapsSetTime
                    WindowsLapsSetTimeDays    = $WindowsLapsSetTimeDays
                    System                    = ConvertTo-OperatingSystem -OperatingSystem $C.OperatingSystem -OperatingSystemVersion $C.OperatingSystemVersion
                    LastLogonDate             = $C.LastLogonDate
                    LastLogonDays             = $LastLogonDays
                    PasswordLastSet           = $C.PasswordLastSet
                    PasswordLastChangedDays   = $PasswordLastChangedDays
                    OrganizationalUnit        = ConvertFrom-DistinguishedName -DistinguishedName $C.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName         = $C.DistinguishedName
                }
            } elseif ($BitlockerOnly) {
                [PSCustomObject] @{
                    Name                    = $C.Name
                    Enabled                 = $C.Enabled
                    Domain                  = $Domain
                    DNSHostName             = $C.DNSHostName
                    IsDC                    = if ($C.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Encrypted               = $Encrypted
                    EncryptedTime           = $EncryptedTime
                    EncryptedDays           = $EncryptedDays
                    System                  = ConvertTo-OperatingSystem -OperatingSystem $C.OperatingSystem -OperatingSystemVersion $C.OperatingSystemVersion
                    LastLogonDate           = $C.LastLogonDate
                    LastLogonDays           = $LastLogonDays
                    PasswordLastSet         = $C.PasswordLastSet
                    PasswordLastChangedDays = $PasswordLastChangedDays
                    OrganizationalUnit      = ConvertFrom-DistinguishedName -DistinguishedName $C.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName       = $C.DistinguishedName
                }
            } else {
                [PSCustomObject] @{
                    Name                      = $C.Name
                    Enabled                   = $C.Enabled
                    Domain                    = $Domain
                    DNSHostName               = $C.DNSHostName
                    IsDC                      = if ($C.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    Encrypted                 = $Encrypted
                    EncryptedTime             = $EncryptedTime
                    EncryptedDays             = $EncryptedDays
                    Laps                      = $Laps
                    LapsExpirationDays        = $LapsExpirationDays
                    LapsExpirationTime        = $LapsExpirationTime
                    WindowsLaps               = $WindowsLaps
                    WindowsLapsExpirationDays = $WindowsLapsExpirationDays
                    WindowsLapsExpirationTime = $WindowsLapsExpirationTime
                    WindowsLapsHistoryCount   = $WindowsLapsHistoryCount
                    WindowsLapsSetTime        = $WindowsLapsSetTime
                    WindowsLapsSetTimeDays    = $WindowsLapsSetTimeDays
                    System                    = ConvertTo-OperatingSystem -OperatingSystem $C.OperatingSystem -OperatingSystemVersion $C.OperatingSystemVersion
                    LastLogonDate             = $C.LastLogonDate
                    LastLogonDays             = $LastLogonDays
                    PasswordLastSet           = $C.PasswordLastSet
                    PasswordLastChangedDays   = $PasswordLastChangedDays
                    OrganizationalUnit        = ConvertFrom-DistinguishedName -DistinguishedName $C.DistinguishedName -ToOrganizationalUnit
                    DistinguishedName         = $C.DistinguishedName
                }
            }
        }
    }
    $FormattedComputers
}
