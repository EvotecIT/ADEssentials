function Get-WinADGroups {
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
    $CacheUsersReport = [ordered] @{}
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'SamAccountName', 'ObjectSID'
            #'Description',
            #'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword',
            #'TrustedForDelegation', 'TrustedToAuthForDelegation', 'msExchMailboxGuid', 'msExchRemoteRecipientType', 'msExchRecipientTypeDetails',
            # 'msExchRecipientDisplayType', 'pwdLastSet', "msDS-UserPasswordExpiryTimeComputed",
            # 'WhenCreated', 'WhenChanged'
        )

        $AllUsers[$Domain] = Get-ADUser -Filter * -Properties $Properties -Server $QueryServer #$ForestInformation['QueryServers'][$Domain].HostName[0]
        $AllContacts[$Domain] = Get-ADObject -Filter 'objectClass -eq "contact"' -Properties SamAccountName, Mail, Name, DistinguishedName, WhenChanged, Whencreated, DisplayName, ObjectSID -Server $QueryServer

        $Properties = @(
            'SamAccountName', 'msExchRecipientDisplayType', 'msExchRecipientTypeDetails', 'CanonicalName', 'Mail', 'Description', 'Name',
            'GroupScope', 'GroupCategory', 'DistinguishedName', 'isCriticalSystemObject', 'adminCount', 'WhenChanged', 'Whencreated', 'DisplayName',
            'ManagedBy', 'member', 'memberof', 'ProtectedFromAccidentalDeletion', 'nTSecurityDescriptor', 'groupType'
            'SID', 'SIDHistory', 'proxyaddresses', 'ObjectSID'
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
            $UserLocation = ($Group.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
            $Region = $UserLocation[-4]
            $Country = $UserLocation[-5]
            if ($Group.ManagedBy) {
                $ManagerAll = $CacheUsersReport[$Group.ManagedBy]
                $Manager = $CacheUsersReport[$Group.ManagedBy].Name
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
            $msExchRecipientTypeDetails = Convert-ExchangeRecipient -msExchRecipientTypeDetails $Group.msExchRecipientTypeDetails
            $msExchRecipientDisplayType = Convert-ExchangeRecipient -msExchRecipientDisplayType $Group.msExchRecipientDisplayType
            #$msExchRemoteRecipientType = Convert-ExchangeRecipient -msExchRemoteRecipientType $Group.msExchRemoteRecipientType
            if ($ManagerAll.ObjectSID) {
                $ACL = Get-ADACL -ADObject $Group -Resolve -Principal $ManagerAll.ObjectSID -IncludeObjectTypeName 'Self-Membership' -IncludeActiveDirectoryRights WriteProperty
            } else {
                $ACL = $null
            }

            # $GroupWriteback = $false
            # # https://practical365.com/azure-ad-connect-group-writeback-deep-dive/
            # if ($Group.msExchRecipientDisplayType -eq 17) {
            #     # M365 Security Group and M365 Mail-Enabled security Group
            #     $GroupWriteback = $true
            # } else {
            #     # if ($Group.GroupType -eq -2147483640 -and $Group.GroupCategory -eq 'Security' -and $Group.GroupScope -eq 'Universal') {
            #     #     $GroupWriteback = $true
            #     # } else {
            #     #     $GroupWriteback = $false
            #     #  }
            # }
            if ($AddOwner) {
                $Owner = Get-ADACLOwner -ADObject $Group -Verbose -Resolve
                [PSCustomObject] @{
                    Name                            = $Group.Name
                    #DisplayName                     = $Group.DisplayName
                    CanonicalName                   = $Group.CanonicalName
                    Domain                          = $Domain
                    SamAccountName                  = $Group.SamAccountName
                    MemberCount                     = if ($Group.member) { $Group.member.Count } else { 0 }
                    GroupScope                      = $Group.GroupScope
                    GroupCategory                   = $Group.GroupCategory
                    #GroupWriteBack                  = $GroupWriteBack
                    #ManagedBy                       = $Group.ManagedBy
                    msExchRecipientTypeDetails      = $msExchRecipientTypeDetails
                    msExchRecipientDisplayType      = $msExchRecipientDisplayType
                    #msExchRemoteRecipientType       = $msExchRemoteRecipientType
                    Manager                         = $Manager
                    ManagerCanUpdateGroupMembership = if ($ACL) { $true } else { $false }
                    ManagerSamAccountName           = $ManagerSamAccountName
                    ManagerEmail                    = $ManagerEmail
                    ManagerEnabled                  = $ManagerEnabled
                    ManagerLastLogon                = $ManagerLastLogon
                    ManagerLastLogonDays            = $ManagerLastLogonDays
                    ManagerStatus                   = $ManagerStatus
                    OwnerName                       = $Owner.OwnerName
                    OwnerSID                        = $Owner.OwnerSID
                    OwnerType                       = $Owner.OwnerType
                    WhenCreated                     = $Group.WhenCreated
                    WhenChanged                     = $Group.WhenChanged
                    ProtectedFromAccidentalDeletion = $Group.ProtectedFromAccidentalDeletion
                    ProxyAddresses                  = Convert-ExchangeEmail -Emails $Group.ProxyAddresses -RemoveDuplicates -RemovePrefix
                    Description                     = $Group.Description
                    DistinguishedName               = $Group.DistinguishedName
                    Level0                          = $Region
                    Level1                          = $Country
                    ManagerDN                       = $Group.ManagedBy
                }
            } else {
                [PSCustomObject] @{
                    Name                            = $Group.Name
                    #DisplayName                     = $Group.DisplayName
                    CanonicalName                   = $Group.CanonicalName
                    Domain                          = $Domain
                    SamAccountName                  = $Group.SamAccountName
                    MemberCount                     = if ($Group.member) { $Group.member.Count } else { 0 }
                    GroupScope                      = $Group.GroupScope
                    GroupCategory                   = $Group.GroupCategory
                    #GroupWriteBack                  = $GroupWriteBack
                    #ManagedBy                       = $Group.ManagedBy
                    msExchRecipientTypeDetails      = $msExchRecipientTypeDetails
                    msExchRecipientDisplayType      = $msExchRecipientDisplayType
                    #msExchRemoteRecipientType       = $msExchRemoteRecipientType
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
                    Level0                          = $Region
                    Level1                          = $Country
                    ManagerDN                       = $Group.ManagedBy
                }
            }
        }
    }
    if ($PerDomain) {
        $Output
    } else {
        $Output.Values
    }
}