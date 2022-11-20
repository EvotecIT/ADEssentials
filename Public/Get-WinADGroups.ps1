function Get-WinADGroups {
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
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'SamAccountName'
            #'Description',
            #'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword',
            #'TrustedForDelegation', 'TrustedToAuthForDelegation', 'msExchMailboxGuid', 'msExchRemoteRecipientType', 'msExchRecipientTypeDetails',
            # 'msExchRecipientDisplayType', 'pwdLastSet', "msDS-UserPasswordExpiryTimeComputed",
            # 'WhenCreated', 'WhenChanged'
        )

        $AllUsers[$Domain] = Get-ADUser -Filter * -Properties $Properties -Server $QueryServer #$ForestInformation['QueryServers'][$Domain].HostName[0]
        $AllContacts[$Domain] = Get-ADObject -Filter 'objectClass -eq "contact"' -Properties SamAccountName, Mail, Name, DistinguishedName, WhenChanged, Whencreated, DisplayName -Server $QueryServer

        $Properties = @(
            'SamAccountName', 'msExchRecipientDisplayType', 'msExchRecipientTypeDetails', 'CanonicalName', 'Mail', 'Description', 'Name',
            'GroupScope', 'GroupCategory', 'DistinguishedName', 'isCriticalSystemObject', 'adminCount', 'WhenChanged', 'Whencreated', 'DisplayName',
            'ManagedBy', 'member', 'memberof', 'ProtectedFromAccidentalDeletion', 'nTSecurityDescriptor', 'groupType'
            'SID', 'SIDHistory', 'proxyaddresses'
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
        $Output[$Domain] = foreach ($Group in $AllGroups[$Domain]) {
            # $UserLocation = ($User.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
            # $Region = $UserLocation[-4]
            # $Country = $UserLocation[-5]

            # if ($User.LastLogonDate) {
            #     $LastLogonDays = $( - $($User.LastLogonDate - $Today).Days)
            # } else {
            #     $LastLogonDays = $null
            # }
            # if ($User.PasswordLastSet) {
            #     $PasswordLastDays = $( - $($User.PasswordLastSet - $Today).Days)
            # } else {
            #     $PasswordLastDays = $null
            # }
            if ($Group.ManagedBy) {
                $ManagerAll = $CacheUsersReport[$Group.ManagedBy]
                $Manager = $CacheUsersReport[$Group.ManagedBy].DisplayName
                $ManagerSamAccountName = $CacheUsersReport[$Group.ManagedBy].SamAccountName
                $ManagerEmail = $CacheUsersReport[$Group.ManagedBy].Mail
                $ManagerEnabled = $CacheUsersReport[$Group.ManagedBy].Enabled
                $ManagerLastLogon = $CacheUsersReport[$Group.ManagedBy].LastLogonDate
                if ($ManagerLastLogon) {
                    $ManagerLastLogonDays = $( - $($ManagerLastLogon - $Today).Days)
                } else {
                    $ManagerLastLogonDays = $null
                }
                $ManagerStatus = if ($ManagerEnabled -eq $true) { 'Enabled' } elseif ($ManagerEnabled -eq $false) { 'Disabled' } else { 'Not available' }
            } else {
                $ManagerAll = $null
                if ($Group.ObjectClass -eq 'user') {
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

            # if ($User."msDS-UserPasswordExpiryTimeComputed" -ne 9223372036854775807) {
            #     # This is standard situation where users password is expiring as needed
            #     try {
            #         $DateExpiry = ([datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed"))
            #     } catch {
            #         $DateExpiry = $User."msDS-UserPasswordExpiryTimeComputed"
            #     }
            #     try {
            #         $DaysToExpire = (New-TimeSpan -Start (Get-Date) -End ([datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed"))).Days
            #     } catch {
            #         $DaysToExpire = $null
            #     }
            #     $PasswordNeverExpires = $User.PasswordNeverExpires
            # } else {
            #     # This is non-standard situation. This basically means most likely Fine Grained Group Policy is in action where it makes PasswordNeverExpires $true
            #     # Since FGP policies are a bit special they do not tick the PasswordNeverExpires box, but at the same time value for "msDS-UserPasswordExpiryTimeComputed" is set to 9223372036854775807
            #     $PasswordNeverExpires = $true
            # }
            # if ($PasswordNeverExpires -or $null -eq $User.PasswordLastSet) {
            #     $DateExpiry = $null
            #     $DaysToExpire = $null
            # }

            # if ($User.'msExchMailboxGuid') {
            #     $HasMailbox = $true
            # } else {
            #     $HasMailbox = $false
            # }
            $msExchRecipientTypeDetails = Convert-ExchangeRecipient -msExchRecipientTypeDetails $Group.msExchRecipientTypeDetails
            $msExchRecipientDisplayType = Convert-ExchangeRecipient -msExchRecipientDisplayType $Group.msExchRecipientDisplayType
            # $msExchRemoteRecipientType = Convert-ExchangeRecipient -msExchRemoteRecipientType $User.msExchRemoteRecipientType
            if ($ManagerAll.ObjectSID) {
                $ACL = Get-ADACL -ADObject $Group -Resolve -Principal $ManagerAll.ObjectSID -IncludeObjectTypeName 'Self-Membership'
            } else {
                $ACL = $null
            }

            $GroupWriteback = $false
            # https://practical365.com/azure-ad-connect-group-writeback-deep-dive/
            if ($Group.msExchRecipientDisplayType -eq 17) {
                # M365 Security Group and M365 Mail-Enabled security Group
                $GroupWriteback = $true
            } else {
                # if ($Group.GroupType -eq -2147483640 -and $Group.GroupCategory -eq 'Security' -and $Group.GroupScope -eq 'Universal') {
                #     $GroupWriteback = $true
                # } else {
                #     $GroupWriteback = $false
                #  }
            }

            [PSCustomObject] @{
                Name                            = $Group.Name
                #DisplayName                     = $Group.DisplayName
                CanonicalName                   = $Group.CanonicalName
                Domain                          = $Domain
                SamAccountName                  = $Group.SamAccountName

                GroupScope                      = $Group.GroupScope
                GroupCategory                   = $Group.GroupCategory
                #GroupWriteBack                  = $GroupWriteBack
                #ManagedBy                       = $Group.ManagedBy
                msExchRecipientTypeDetails      = $msExchRecipientTypeDetails
                msExchRecipientDisplayType      = $msExchRecipientDisplayType

                Manager                         = $Manager
                ManagerCanUpdateGroupMembership = if ($ACL) { $true } else { $false }
                ManagerSamAccountName           = $ManagerSamAccountName
                ManagerEmail                    = $ManagerEmail
                ManagerEnabled                  = $ManagerEnabled
                ManagerLastLogon                = $ManagerLastLogon
                ManagerLastLogonDays            = $ManagerLastLogonDays
                ManagerStatus                   = $ManagerStatus
                WhenCreated                     = $Group.WhenCreated
                WhenChanged                     = $Group.WhenChanged
                ProtectedFromAccidentalDeletion = $Group.ProtectedFromAccidentalDeletion
                ProxyAddresses                  = Convert-ExchangeEmail -Emails $Group.ProxyAddresses -RemoveDuplicates -RemovePrefix
                Description                     = $Group.Description
                DistinguishedName               = $Group.DistinguishedName
                # ObjectClass           = $Group.ObjectClass
                # Name                        = $Group.Name
                # SamAccountName              = $Group.SamAccountName
                # Domain                      = $Domain
                # WhenChanged                 = $Group.WhenChanged
                # Enabled                     = $Group.Enabled
                #ObjectClass                 = $Group.ObjectClass
                #IsMissing                   = if ($Group) { $false } else { $true }
                # HasMailbox                  = $HasMailbox
                # MustChangePasswordAtLogon   = if ($User.pwdLastSet -eq 0 -and $User.PasswordExpired -eq $true) { $true } else { $false }
                # PasswordNeverExpires        = $PasswordNeverExpires
                # PasswordNotRequired         = $User.PasswordNotRequired
                # LastLogonDays               = $LastLogonDays
                # PasswordLastDays            = $PasswordLastDays
                # DaysToExpire                = $DaysToExpire
                # ManagerStatus               = $ManagerStatus
                # Manager                     = $Manager
                # ManagerSamAccountName       = $ManagerSamAccountName
                # ManagerEmail                = $ManagerEmail
                # ManagerLastLogonDays        = $ManagerLastLogonDays
                # Level0                      = $Region
                # Level1                      = $Country
                # DistinguishedName           = $User.DistinguishedName
                # LastLogonDate               = $User.LastLogonDate
                # PasswordLastSet             = $User.PasswordLastSet
                # PasswordExpiresOn           = $DateExpiry
                # PasswordExpired             = $User.PasswordExpired
                # CannotChangePassword        = $User.CannotChangePassword
                # AccountTrustedForDelegation = $User.AccountTrustedForDelegation
                # ManagerDN                   = $User.Manager
                # ManagerLastLogon            = $ManagerLastLogon
                # Group                       = $Group
                # Description                 = $User.Description
                # UserPrincipalName           = $User.UserPrincipalName
                # RecipientTypeDetails        = $msExchRecipientTypeDetails
                # RecipientDisplayType        = $msExchRecipientDisplayType
                # RemoteRecipientType         = $msExchRemoteRecipientType
                # WhenCreated                 = $User.WhenCreated
            }
        }

    }
    if ($PerDomain) {
        $Output
    } else {
        $Output.Values
    }
}