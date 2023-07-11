function Get-WinADComputers {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $PerDomain,
        [switch] $AddOwner
    )

    $AllUsers = [ordered] @{}
    $AllContacts = [ordered] @{}
    $AllGroups = [ordered] @{}
    $AllComputers = [ordered] @{}
    $CacheUsersReport = [ordered] @{}

    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'Description',
            'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword',
            'TrustedForDelegation', 'TrustedToAuthForDelegation', 'msExchMailboxGuid', 'msExchRemoteRecipientType', 'msExchRecipientTypeDetails',
            'msExchRecipientDisplayType', 'pwdLastSet', "msDS-UserPasswordExpiryTimeComputed",
            'WhenCreated', 'WhenChanged'
        )
        $AllUsers[$Domain] = Get-ADUser -Filter * -Properties $Properties -Server $QueryServer #$ForestInformation['QueryServers'][$Domain].HostName[0]
        $AllContacts[$Domain] = Get-ADObject -Filter 'objectClass -eq "contact"' -Properties SamAccountName, Mail, Name, DistinguishedName, WhenChanged, Whencreated, DisplayName -Server $QueryServer
        $Properties = @(
            'SamAccountName', 'CanonicalName', 'Mail', 'Name', 'DistinguishedName', 'isCriticalSystemObject', 'ObjectSID'
        )
        $AllGroups[$Domain] = Get-ADGroup -Filter * -Properties $Properties -Server $QueryServer
        $Properties = @(
            'DistinguishedName', 'LastLogonDate', 'PasswordLastSet', 'Enabled', 'DnsHostName', 'PasswordNeverExpires', 'PasswordNotRequired',
            'PasswordExpired', 'ManagedBy', 'OperatingSystemVersion', 'OperatingSystem' , 'TrustedForDelegation', 'WhenCreated', 'WhenChanged', 'PrimaryGroupID'
            'nTSecurityDescriptor'
        )
        $AllComputers[$Domain] = Get-ADComputer -Filter * -Server $QueryServer -Properties $Properties
    }

    foreach ($Domain in $AllUsers.Keys) {
        foreach ($U in $AllUsers[$Domain]) {
            $CacheUsersReport[$U.DistinguishedName] = $U
        }
    }
    foreach ($Domain in $AllContacts.Keys) {
        foreach ($C in $AllContacts[$Domain]) {
            $CacheUsersReport[$C.DistinguishedName] = $C
        }
    }
    foreach ($Domain in $AllGroups.Keys) {
        foreach ($G in $AllGroups[$Domain]) {
            $CacheUsersReport[$G.DistinguishedName] = $G
        }
    }


    $Output = [ordered] @{}
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $Output[$Domain] = foreach ($Computer in $AllComputers[$Domain]) {
            $ComputerLocation = ($Computer.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
            $Region = $ComputerLocation[-4]
            $Country = $ComputerLocation[-5]

            if ($Computer.ManagedBy) {
                $Manager = $CacheUsersReport[$Computer.ManagedBy].Name
                $ManagerSamAccountName = $CacheUsersReport[$Computer.ManagedBy].SamAccountName
                $ManagerEmail = $CacheUsersReport[$Computer.ManagedBy].Mail
                $ManagerEnabled = $CacheUsersReport[$Computer.ManagedBy].Enabled
                $ManagerLastLogon = $CacheUsersReport[$Computer.ManagedBy].LastLogonDate
                if ($ManagerLastLogon) {
                    $ManagerLastLogonDays = $( - $($ManagerLastLogon - $Today).Days)
                } else {
                    $ManagerLastLogonDays = $null
                }
                $ManagerStatus = if ($ManagerEnabled -eq $true) { 'Enabled' } elseif ($ManagerEnabled -eq $false) { 'Disabled' } else { 'Not available' }
            } else {
                $ManagerStatus = 'Not available'
                $Manager = $null
                $ManagerSamAccountName = $null
                $ManagerEmail = $null
                $ManagerEnabled = $null
                $ManagerLastLogon = $null
                $ManagerLastLogonDays = $null
            }

            if ($null -ne $Computer.LastLogonDate) {
                $LastLogonDays = "$(-$($Computer.LastLogonDate - $Today).Days)"
            } else {
                $LastLogonDays = $null
            }
            if ($null -ne $Computer.PasswordLastSet) {
                $PasswordLastChangedDays = "$(-$($Computer.PasswordLastSet - $Today).Days)"
            } else {
                $PasswordLastChangedDays = $null
            }

            if ($AddOwner) {
                $Owner = Get-ADACLOwner -ADObject $Computer -Verbose -Resolve
                [PSCustomObject] @{
                    Name                  = $Computer.Name
                    SamAccountName        = $Computer.SamAccountName
                    Domain                = $Domain
                    IsDC                  = if ($Computer.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    WhenChanged           = $Computer.WhenChanged
                    Enabled               = $Computer.Enabled
                    LastLogonDays         = $LastLogonDays
                    PasswordLastDays      = $PasswordLastChangedDays
                    Level0                = $Region
                    Level1                = $Country
                    OperatingSystem       = $Computer.OperatingSystem
                    #OperatingSystemVersion = $Computer.OperatingSystemVersion
                    OperatingSystemName   = ConvertTo-OperatingSystem -OperatingSystem $Computer.OperatingSystem -OperatingSystemVersion $Computer.OperatingSystemVersion
                    DistinguishedName     = $Computer.DistinguishedName
                    LastLogonDate         = $Computer.LastLogonDate
                    PasswordLastSet       = $Computer.PasswordLastSet
                    PasswordNeverExpires  = $Computer.PasswordNeverExpires
                    PasswordNotRequired   = $Computer.PasswordNotRequired
                    PasswordExpired       = $Computer.PasswordExpired
                    ManagerStatus         = $ManagerStatus
                    Manager               = $Manager
                    ManagerSamAccountName = $ManagerSamAccountName
                    ManagerEmail          = $ManagerEmail
                    ManagerLastLogonDays  = $ManagerLastLogonDays
                    OwnerName             = $Owner.OwnerName
                    OwnerSID              = $Owner.OwnerSID
                    OwnerType             = $Owner.OwnerType
                    ManagerDN             = $Computer.ManagedBy
                    Description           = $Computer.Description
                    TrustedForDelegation  = $Computer.TrustedForDelegation
                }
            } else {
                $Owner = $null
                [PSCustomObject] @{
                    Name                  = $Computer.Name
                    SamAccountName        = $Computer.SamAccountName
                    Domain                = $Domain
                    IsDC                  = if ($Computer.PrimaryGroupID -in 516, 521) { $true } else { $false }
                    WhenChanged           = $Computer.WhenChanged
                    Enabled               = $Computer.Enabled
                    LastLogonDays         = $LastLogonDays
                    PasswordLastDays      = $PasswordLastChangedDays
                    Level0                = $Region
                    Level1                = $Country
                    OperatingSystem       = $Computer.OperatingSystem
                    #OperatingSystemVersion = $Computer.OperatingSystemVersion
                    OperatingSystemName   = ConvertTo-OperatingSystem -OperatingSystem $Computer.OperatingSystem -OperatingSystemVersion $Computer.OperatingSystemVersion
                    DistinguishedName     = $Computer.DistinguishedName
                    LastLogonDate         = $Computer.LastLogonDate
                    PasswordLastSet       = $Computer.PasswordLastSet
                    PasswordNeverExpires  = $Computer.PasswordNeverExpires
                    PasswordNotRequired   = $Computer.PasswordNotRequired
                    PasswordExpired       = $Computer.PasswordExpired
                    ManagerStatus         = $ManagerStatus
                    Manager               = $Manager
                    ManagerSamAccountName = $ManagerSamAccountName
                    ManagerEmail          = $ManagerEmail
                    ManagerLastLogonDays  = $ManagerLastLogonDays
                    ManagerDN             = $Computer.ManagedBy
                    Description           = $Computer.Description
                    TrustedForDelegation  = $Computer.TrustedForDelegation
                }
            }
        }
    }
    if ($PerDomain) {
        $Output
    } else {
        foreach ($O in $Output.Keys) {
            $Output[$O]
        }
    }
}