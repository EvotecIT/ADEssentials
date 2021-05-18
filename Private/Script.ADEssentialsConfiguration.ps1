$Script:ADEssentialsConfiguration = [ordered] @{
    Users            = $Script:ShowWinADUser
    Computers        = $Script:ShowWinADComputer
    Laps             = $Script:ConfigurationLAPS
    LapsAndBitLocker = $Script:ConfigurationLAPSAndBitlocker
    BitLocker        = $Script:ConfigurationBitLocker
    ServiceAccounts  = $Script:ConfigurationServiceAccounts
}