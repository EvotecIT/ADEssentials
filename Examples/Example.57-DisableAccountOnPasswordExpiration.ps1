Import-Module .\ADEssentials.psd1 -Force


# Disable accounts on account expiration (not password expiration)
# Disable all of them
Request-DisableOnAccountExpiration -LimitProcessing 1 -PassThru -Verbose -WhatIf | Format-Table

# Disable accounts on account expiration (not password expiration)
# Disable only from specific OU
$OU = @(
    'OU=Default,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    'OU=Administrative,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
)

Request-DisableOnAccountExpiration -LimitProcessing 1 -PassThru -Verbose -WhatIf -OrganizationalUnit $OU | Format-Table