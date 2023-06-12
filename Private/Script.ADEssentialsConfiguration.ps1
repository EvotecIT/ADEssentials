$Script:ADEssentialsConfiguration = [ordered] @{
    AccountDelegation = $Script:ShowWinADAccountDelegation
    Users             = $Script:ShowWinADUser
    Computers         = $Script:ShowWinADComputer
    Groups            = $Script:ShowWinADGroup
    Laps              = $Script:ConfigurationLAPS
    LapsACL           = $Script:ConfigurationLAPSACL
    LapsAndBitLocker  = $Script:ConfigurationLAPSAndBitlocker
    BitLocker         = $Script:ConfigurationBitLocker
    ServiceAccounts   = $Script:ConfigurationServiceAccounts
    ForestACLOwners   = $Script:ConfigurationACLOwners
    PasswordPolicies  = $Script:ConfigurationPasswordPolicies
}