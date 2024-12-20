﻿$Script:ADEssentialsConfiguration = [ordered] @{
    AccountDelegation           = $Script:ShowWinADAccountDelegation
    Users                       = $Script:ShowWinADUser
    BrokenProtectedFromDeletion = $Script:ShowWinADBrokenProtectedFromDeletion
    Computers                   = $Script:ShowWinADComputer
    Groups                      = $Script:ShowWinADGroup
    Schema                      = $Script:ConfigurationSchema
    Laps                        = $Script:ConfigurationLAPS
    LapsACL                     = $Script:ConfigurationLAPSACL
    LapsAndBitLocker            = $Script:ConfigurationLAPSAndBitlocker
    BitLocker                   = $Script:ConfigurationBitLocker
    ServiceAccounts             = $Script:ConfigurationServiceAccounts
    ForestACLOwners             = $Script:ConfigurationACLOwners
    PasswordPolicies            = $Script:ConfigurationPasswordPolicies
    GlobalCatalogComparison     = $Script:ConfigurationGlobalCatalogObjects
}