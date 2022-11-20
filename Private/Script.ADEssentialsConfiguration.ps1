$Script:ADEssentialsConfiguration = [ordered] @{
    Users            = $Script:ShowWinADUser
    Computers        = $Script:ShowWinADComputer
    Groups           = $Script:ShowWinADGroup
    Laps             = $Script:ConfigurationLAPS
    LapsACL          = $Script:ConfigurationLAPSACL
    LapsAndBitLocker = $Script:ConfigurationLAPSAndBitlocker
    BitLocker        = $Script:ConfigurationBitLocker
    ServiceAccounts  = $Script:ConfigurationServiceAccounts
    ForestACLOwners  = $Script:ConfigurationACLOwners
}