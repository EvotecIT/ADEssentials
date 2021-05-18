function Get-WinADServiceAccount {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $PerDomain
    )
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    $Output = [ordered] @{}
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $Properties = @(
            'Name', 'ObjectClass', 'PasswordLastSet', 'PasswordNeverExpires', 'PasswordNotRequired', 'UserPrincipalName', 'SamAccountName', 'LastLogonDate' #,'PrimaryGroup', 'PrimaryGroupID',
            'AccountExpirationDate', 'AccountNotDelegated',
            #'AllowReversiblePasswordEncryption', 'CannotChangePassword',
            'CanonicalName', 'WhenCreated', 'WhenChanged', 'DistinguishedName', 'Enabled', 'Description'
            'msDS-HostServiceAccountBL', 'msDS-SupportedEncryptionTypes', 'msDS-User-Account-Control-Computed', 'TrustedForDelegation', 'TrustedToAuthForDelegation'
            'msDS-AuthenticatedAtDC', 'msDS-AllowedToActOnBehalfOfOtherIdentity', 'msDS-AllowedToDelegateTo', 'PrincipalsAllowedToRetrieveManagedPassword', 'PrincipalsAllowedToDelegateToAccount'
            'msDS-ManagedPasswordInterval', 'msDS-GroupMSAMembership', 'ManagedPasswordIntervalInDays', 'msDS-RevealedDSAs', 'servicePrincipalName'
            #'msDS-ManagedPasswordId', 'msDS-ManagedPasswordPreviousId'
        )
        $Accounts = Get-ADServiceAccount -Filter * -Server $QueryServer -Properties $Properties
        $Output[$Domain] = foreach ($Account in $Accounts) {
            #$Account

            if ($null -ne $Account.LastLogonDate) {
                [int] $LastLogonDays = "$(-$($Account.LastLogonDate - $Today).Days)"
            } else {
                $LastLogonDays = $null
            }
            if ($null -ne $Account.PasswordLastSet) {
                [int] $PasswordLastChangedDays = "$(-$($Account.PasswordLastSet - $Today).Days)"
            } else {
                $PasswordLastChangedDays = $null
            }

            [PSCUstomObject] @{
                Name                                         = $Account.Name
                Enabled                                      = $Account.Enabled                              # : True                     # : WO_SVC_Delete$
                ObjectClass                                  = $Account.ObjectClass                          # : msDS-ManagedServiceAccount
                CanonicalName                                = $Account.CanonicalName                        # : ad.evotec.xyz/Managed Service Accounts/WO_SVC_Delete
                DomainName                                   = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $Account.DistinguishedName
                Description                                  = $Account.Description
                PasswordLastChangedDays                      = $PasswordLastChangedDays
                LastLogonDays                                = $LastLogonDays
                'ManagedPasswordIntervalInDays'              = $Account.'ManagedPasswordIntervalInDays'
                'msDS-AllowedToDelegateTo'                   = $Account.'msDS-AllowedToDelegateTo'            # : {CN=EVOWIN,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz}
                'msDS-HostServiceAccountBL'                  = $Account.'msDS-HostServiceAccountBL'            # : {CN=EVOWIN,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz}
                'msDS-AuthenticatedAtDC'                     = $Account.'msDS-AuthenticatedAtDC'
                'msDS-AllowedToActOnBehalfOfOtherIdentity'   = $Account.'msDS-AllowedToActOnBehalfOfOtherIdentity'
                'PrincipalsAllowedToRetrieveManagedPassword' = $Account.'PrincipalsAllowedToRetrieveManagedPassword'
                'PrincipalsAllowedToDelegateToAccount'       = $Account.'PrincipalsAllowedToDelegateToAccount'

                #'msDS-ManagedPasswordId'                     = $Account.'msDS-ManagedPasswordId'
                'msDS-GroupMSAMembershipAccess'              = $Account.'msDS-GroupMSAMembership'.Access.IdentityReference.Value
                'msDS-GroupMSAMembershipOwner'               = $Account.'msDS-GroupMSAMembership'.Owner
                #'msDS-ManagedPasswordPreviousId'             = $Account.'msDS-ManagedPasswordPreviousId'

                'msDS-RevealedDSAs'                          = $Account.'msDS-RevealedDSAs'
                'servicePrincipalName'                       = $Account.servicePrincipalName
                AccountNotDelegated                          = $Account.AccountNotDelegated                  # : False
                TrustedForDelegation                         = $Account.TrustedForDelegation                 # : False
                TrustedToAuthForDelegation                   = $Account.TrustedToAuthForDelegation           # : False
                AccountExpirationDate                        = $Account.AccountExpirationDate
                #AllowReversiblePasswordEncryption = $Account.AllowReversiblePasswordEncryption    # : False
                #CannotChangePassword              = $Account.CannotChangePassword                 # : False
                #'msDS-SupportedEncryptionTypes'      = $Account.'msDS-SupportedEncryptionTypes'        # : 28
                msDSSupportedEncryptionTypes                 = Get-ADEncryptionTypes -Value $Account.'msds-supportedencryptiontypes'
                # 'msDS-User-Account-Control-Computed' = $Account.'msDS-User-Account-Control-Computed'   # : 0
                #ObjectGUID                        = $Account.ObjectGUID                           # : 573ff95e-c1f8-45e2-9b64-662fb9cb0615
                PasswordNeverExpires                         = $Account.PasswordNeverExpires                 # : False
                PasswordNotRequired                          = $Account.PasswordNotRequired                  # : False
                #PrimaryGroup                      = $Account.PrimaryGroup                         # : CN=Domain Computers,CN=Users,DC=ad,DC=evotec,DC=xyz
                #PrimaryGroupID                    = $Account.PrimaryGroupID                       # : 515
                #SID                               = $Account.SID                                  # : S-1-5-21-853615985-2870445339-3163598659-4607
                #UserPrincipalName                 = $Account.UserPrincipalName                    # :
                LastLogonDate                                = $Account.LastLogonDate                        # :
                PasswordLastSet                              = $Account.PasswordLastSet                      # : 15.04.2021 22:47:40
                WhenChanged                                  = $Account.WhenChanged                          # : 15.04.2021 22:47:40
                WhenCreated                                  = $Account.WhenCreated                          # : 15.04.2021 22:47:40
                SamAccountName                               = $Account.SamAccountName
                DistinguishedName                            = $Account.DistinguishedName                    # : CN=WO_SVC_Delete,CN=Managed Service Accounts,DC=ad,DC=evotec,DC=xyz
                'msDS-GroupMSAMembership'                    = $Account.'msDS-GroupMSAMembership'
                # 'msDS-ManagedPasswordInterval'               = $Account.'msDS-ManagedPasswordInterval'
            }
        }

    }
    if ($PerDomain) {
        $Output
    } else {
        $Output.Values
    }
}