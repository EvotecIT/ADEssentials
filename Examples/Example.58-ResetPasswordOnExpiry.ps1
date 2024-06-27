Import-Module .\ADEssentials.psd1 -Force

#
$OU = @(
    'OU=Default,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'OU=Administrative,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
)

Request-ChangePasswordAtLogon -OrganizationalUnit $OU -LimitProcessing 1 -PassThru -Verbose -WhatIf


# Disable accounts on account expiration (not password expiration), without limits of OU
#Request-ChangePasswordAtLogon -LimitProcessing 1 -PassThru -Verbose -WhatIf | Format-Table