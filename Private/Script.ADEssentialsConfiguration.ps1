$Script:ADEssentialsConfiguration = [ordered] @{
    AccountDelegation       = $Script:ShowWinADAccountDelegation
    Users                   = $Script:ShowWinADUser
    Computers               = $Script:ShowWinADComputer
    DefaultSchemaPermission = $Script:ConfigurationSchemaDefaultPermission
    Groups                  = $Script:ShowWinADGroup
    Laps                    = $Script:ConfigurationLAPS
    LapsACL                 = $Script:ConfigurationLAPSACL
    LapsAndBitLocker        = $Script:ConfigurationLAPSAndBitlocker
    BitLocker               = $Script:ConfigurationBitLocker
    ServiceAccounts         = $Script:ConfigurationServiceAccounts
    ForestACLOwners         = $Script:ConfigurationACLOwners
    PasswordPolicies        = $Script:ConfigurationPasswordPolicies
    GlobalCatalogComparison = $Script:ConfigurationGlobalCatalogObjects
}