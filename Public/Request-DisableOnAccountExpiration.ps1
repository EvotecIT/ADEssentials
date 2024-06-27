function Request-DisableOnAccountExpiration {
    <#
    .SYNOPSIS
    This command will find all users that have expired account and set them to be disabled.

    .DESCRIPTION
    This command will find all users that have expired account and set them to be disabled.
    This is useful for example for Azure AD Connect where you want to disable users that have expired account.
    The account expiration doesn't get synced in specific conditions to Azure AD so you need to do it manually.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER LimitProcessing
    Provide limit of objects that will be processed in a single run

    .PARAMETER IgnoreDisplayName
    Allow to ignore certain users based on their DisplayName. -It uses -like operator so you can use wildcards.
    This is useful for example for Exchange accounts that have expired password but are not used for anything else.

    .PARAMETER IgnoreDistinguishedName
    Allow to ignore certain users based on their DistinguishedName. It uses -like operator so you can use wildcards.

    .PARAMETER IgnoreSamAccountName
    Allow to ignore certain users based on their SamAccountName. It uses -like operator so you can use wildcards.

    .PARAMETER OrganizationalUnit
    Provide a list of Organizational Units to search for users that have expired password. If not provided, all users in the forest will be searched.

    .PARAMETER PassThru
    Returns objects that were processed.

    .EXAMPLE
    Request-DisableOnAccountExpiration -LimitProcessing 1 -PassThru -Verbose -WhatIf | Format-Table

    .EXAMPLE
    $OU = @(
        'OU=Default,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
        'OU=Administrative,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    )

    Request-DisableOnAccountExpiration -LimitProcessing 1 -PassThru -Verbose -WhatIf -OrganizationalUnit $OU | Format-Table

    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [int] $LimitProcessing,
        [Array] $IgnoreDisplayName,
        [Array] $IgnoreDistinguishedName,
        [Array] $IgnoreSamAccountName,
        [string[]] $OrganizationalUnit,
        [switch] $PassThru
    )
    Begin {
        $Today = Get-Date
        $ForestDetails = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
        $IgnoreDisplayNameTotal = @(
            'Microsoft Exchange*'
            foreach ($I in $IgnoreDisplayName) {
                $I
            }
        )
        $IgnoreDistinguishedNameTotal = @(
            "*,CN=Users,*"
            foreach ($I in $IgnoreDistinguishedName) {
                $I
            }
        )
        $IgnoreSamAccountNameTotal = @(
            'Administrator'
            'Guest'
            'krbtgt*'
            'healthmailbox*'
            foreach ($I in $IgnoreSamAccountName) {
                $I
            }
        )
    }
    Process {
        [Array] $UsersFound = foreach ($Domain in $ForestDetails.Domains) {
            $QueryServer = $ForestDetails['QueryServers'][$Domain].HostName[0]
            if ($OrganizationalUnit) {
                $Users = @(
                    foreach ($OU in $OrganizationalUnit) {
                        $OUDomain = ConvertFrom-DistinguishedName -DistinguishedName $OU -ToDomainCN
                        if ($OUDomain -eq $Domain) {
                            Get-ADUser -Filter "Enabled -eq '$true'" -Properties DisplayName, SamAccountName, PasswordExpired, PasswordLastSet, pwdLastSet, PasswordNeverExpires, AccountExpirationDate -Server $QueryServer -SearchBase $OU
                        }
                    }
                )
                $Users = $Users | Sort-Object -Property DistinguishedName -Unique
            } else {
                $Users = Get-ADUser -Filter "Enabled -eq '$true'" -Properties DisplayName, SamAccountName, PasswordExpired, PasswordLastSet, pwdLastSet, PasswordNeverExpires, AccountExpirationDate -Server $QueryServer
            }
            :SkipUser foreach ($User in $Users) {
                # lets asses if password is set to expire or not
                $DateExpiry = $null
                if ($User."msDS-UserPasswordExpiryTimeComputed" -ne 9223372036854775807) {
                    # This is standard situation where users password is expiring as needed
                    try {
                        $DateExpiry = ([datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed"))
                    } catch {
                        $DateExpiry = $User."msDS-UserPasswordExpiryTimeComputed"
                    }
                }
                if ($User.pwdLastSet -eq 0 -and $DateExpiry.Year -eq 1601) {
                    $PasswordAtNextLogon = $true
                } else {
                    $PasswordAtNextLogon = $false
                }

                if ($User.Enabled -eq $true -and $null -ne $User.AccountExpirationDate) {
                    if ($User.AccountExpirationDate -le $Today) {
                        foreach ($I in $IgnoreSamAccountNameTotal) {
                            if ($User.SamAccountName -like $I) {
                                Write-Verbose -Message "Request-DisableOnAccountExpiration - Ignoring $($User.SamAccountName) / $($User.DistinguishedName)"
                                continue SkipUser
                            }
                        }
                        foreach ($I in $IgnoreDistinguishedNameTotal) {
                            if ($User.DistinguishedName -like $I) {
                                Write-Verbose -Message "Request-DisableOnAccountExpiration - Ignoring $($User.SamAccountName) / $($User.DistinguishedName)"
                                continue SkipUser
                            }
                        }
                        foreach ($I in $IgnoreDisplayNameTotal) {
                            if ($User.DisplayName -like $I) {
                                Write-Verbose -Message "Request-DisableOnAccountExpiration - Ignoring $($User.SamAccountName) / $($User.DistinguishedName)"
                                continue SkipUser
                            }
                        }
                        Write-Verbose -Message "Request-DisableOnAccountExpiration - Found $($User.SamAccountName) / $Domain. Expiration date reached '$($User.AccountExpirationDate)'"
                        [PSCustomObject] @{
                            SamAccountName        = $User.SamAccountName
                            Domain                = $Domain
                            DisplayName           = $User.DisplayName
                            AccountExpirationDate = $User.AccountExpirationDate
                            PasswordAtNextLogon   = $PasswordAtNextLogon
                            PasswordExpired       = $User.PasswordExpired
                            PasswordLastSet       = $User.PasswordLastSet
                            PasswordNeverExpires  = $User.PasswordNeverExpires
                            DistinguishedName     = $User.DistinguishedName
                        }
                    } else {
                        Write-Verbose -Message "Request-DisableOnAccountExpiration - Skipping $($User.SamAccountName) / $Domain. Expiration date not reached '$($User.AccountExpirationDate)'"
                    }
                }
            }
        }
        $Count = 0
        if ($LimitProcessing) {
            Write-Verbose -Message "Request-DisableOnAccountExpiration - Found $($UsersFound.Count) expired users. Processing on disablement with limit of $LimitProcessing..."
        } else {
            Write-Verbose -Message "Request-DisableOnAccountExpiration - Found $($UsersFound.Count) expired users. Processing on disablement..."
        }
        foreach ($User in $UsersFound) {
            if ($LimitProcessing -and $Count -ge $LimitProcessing) {
                break
            }
            Write-Verbose -Message "Request-DisableOnAccountExpiration - Setting $($User.SamAccountName) to be disabled / $($User.Domain)"
            Set-ADUser -Enabled $false -Identity $User.SamAccountName -Server $ForestDetails['QueryServers'][$User.Domain].HostName[0]
            if ($PassThru) {
                $User
            }
            $Count++
        }
    }
}