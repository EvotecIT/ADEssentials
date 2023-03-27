function Get-WinADUsers {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $PerDomain
    )
    $AllUsers = [ordered] @{}
    $AllContacts = [ordered] @{}
    $AllGroups = [ordered] @{}
    $CacheUsersReport = [ordered] @{}
    #}
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
        $Output[$Domain] = foreach ($User in $AllUsers[$Domain]) {
            $UserLocation = ($User.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
            $Region = $UserLocation[-4]
            $Country = $UserLocation[-5]

            if ($User.LastLogonDate) {
                $LastLogonDays = $( - $($User.LastLogonDate - $Today).Days)
            } else {
                $LastLogonDays = $null
            }
            if ($User.PasswordLastSet) {
                $PasswordLastDays = $( - $($User.PasswordLastSet - $Today).Days)
            } else {
                $PasswordLastDays = $null
            }
            if ($User.Manager) {
                $Manager = $CacheUsersReport[$User.Manager].Name
                $ManagerSamAccountName = $CacheUsersReport[$User.Manager].SamAccountName
                $ManagerEmail = $CacheUsersReport[$User.Manager].Mail
                $ManagerEnabled = $CacheUsersReport[$User.Manager].Enabled
                $ManagerLastLogon = $CacheUsersReport[$User.Manager].LastLogonDate
                if ($ManagerLastLogon) {
                    $ManagerLastLogonDays = $( - $($ManagerLastLogon - $Today).Days)
                } else {
                    $ManagerLastLogonDays = $null
                }
                $ManagerStatus = if ($ManagerEnabled -eq $true) { 'Enabled' } elseif ($ManagerEnabled -eq $false) { 'Disabled' } else { 'Not available' }
            } else {
                if ($User.ObjectClass -eq 'user') {
                    $ManagerStatus = 'Missing'
                } else {
                    $ManagerStatus = 'Not available'
                }
                $Manager = $null
                $ManagerSamAccountName = $null
                $ManagerEmail = $null
                $ManagerEnabled = $null
                $ManagerLastLogon = $null
                $ManagerLastLogonDays = $null
            }

            if ($User."msDS-UserPasswordExpiryTimeComputed" -ne 9223372036854775807) {
                # This is standard situation where users password is expiring as needed
                try {
                    $DateExpiry = ([datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed"))
                } catch {
                    $DateExpiry = $User."msDS-UserPasswordExpiryTimeComputed"
                }
                try {
                    $DaysToExpire = (New-TimeSpan -Start (Get-Date) -End ([datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed"))).Days
                } catch {
                    $DaysToExpire = $null
                }
                $PasswordNeverExpires = $User.PasswordNeverExpires
            } else {
                # This is non-standard situation. This basically means most likely Fine Grained Group Policy is in action where it makes PasswordNeverExpires $true
                # Since FGP policies are a bit special they do not tick the PasswordNeverExpires box, but at the same time value for "msDS-UserPasswordExpiryTimeComputed" is set to 9223372036854775807
                $PasswordNeverExpires = $true
            }
            if ($PasswordNeverExpires -or $null -eq $User.PasswordLastSet) {
                $DateExpiry = $null
                $DaysToExpire = $null
            }

            if ($User.'msExchMailboxGuid') {
                $HasMailbox = $true
            } else {
                $HasMailbox = $false
            }
            $msExchRecipientTypeDetails = Convert-ExchangeRecipient -msExchRecipientTypeDetails $User.msExchRecipientTypeDetails
            $msExchRecipientDisplayType = Convert-ExchangeRecipient -msExchRecipientDisplayType $User.msExchRecipientDisplayType
            $msExchRemoteRecipientType = Convert-ExchangeRecipient -msExchRemoteRecipientType $User.msExchRemoteRecipientType


            [PSCustomObject] @{
                Name                      = $User.Name
                SamAccountName            = $User.SamAccountName
                Domain                    = $Domain
                WhenChanged               = $User.WhenChanged
                Enabled                   = $User.Enabled
                ObjectClass               = $User.ObjectClass
                #IsMissing                   = if ($Group) { $false } else { $true }
                HasMailbox                = $HasMailbox
                MustChangePasswordAtLogon = if ($User.pwdLastSet -eq 0 -and $User.PasswordExpired -eq $true) { $true } else { $false }
                PasswordNeverExpires      = $PasswordNeverExpires
                PasswordNotRequired       = $User.PasswordNotRequired
                LastLogonDays             = $LastLogonDays
                PasswordLastDays          = $PasswordLastDays
                DaysToExpire              = $DaysToExpire
                ManagerStatus             = $ManagerStatus
                Manager                   = $Manager
                ManagerSamAccountName     = $ManagerSamAccountName
                ManagerEmail              = $ManagerEmail
                ManagerLastLogonDays      = $ManagerLastLogonDays
                Level0                    = $Region
                Level1                    = $Country
                DistinguishedName         = $User.DistinguishedName
                LastLogonDate             = $User.LastLogonDate
                PasswordLastSet           = $User.PasswordLastSet
                PasswordExpiresOn         = $DateExpiry
                PasswordExpired           = $User.PasswordExpired
                CannotChangePassword      = $User.CannotChangePassword
                TrustedForDelegation      = $User.TrustedForDelegation
                ManagerDN                 = $User.Manager
                ManagerLastLogon          = $ManagerLastLogon
                Group                     = $Group
                Description               = $User.Description
                UserPrincipalName         = $User.UserPrincipalName
                RecipientTypeDetails      = $msExchRecipientTypeDetails
                RecipientDisplayType      = $msExchRecipientDisplayType
                RemoteRecipientType       = $msExchRemoteRecipientType
                WhenCreated               = $User.WhenCreated
            }
        }

    }
    if ($PerDomain) {
        $Output
    } else {
        $Output.Values
    }
}