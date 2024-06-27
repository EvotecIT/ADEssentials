function Request-ChangePasswordAtLogon {
    <#
    .SYNOPSIS
    This command will find all users that have expired password and set them to change password at next logon.

    .DESCRIPTION
    This command will find all users that have expired password and set them to change password at next logon.
    This is useful for example for Azure AD Connect where you want to force users to change password on next logon.
    The password expiration doesn't get synced in specific conditions to Azure AD so you need to do it manually.

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
    $OU = @(
        'OU=Default,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
        'OU=Administrative,OU=Users.NoSync,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
    )

    Request-ChangePasswordAtLogon -OrganizationalUnit $OU -LimitProcessing 1 -PassThru -Verbose -WhatIf | Format-Table

    .NOTES
    Please note that for Azure AD to pickup the change, you may need:

    Get-ADSyncAADCompanyFeature
    Set-ADSyncAADCompanyFeature -ForcePasswordChangeOnLogOn $true

    As described in https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization#synchronizing-temporary-passwords-and-force-password-change-on-next-logon

    The above is not required only for new users without a password set. If the password is set the feature is required.

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
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
                            Get-ADUser -Filter "Enabled -eq '$true'" -Properties DisplayName, SamAccountName, PasswordExpired, PasswordLastSet, pwdLastSet, PasswordNeverExpires -Server $QueryServer -SearchBase $OU
                        }
                    }
                )
                $Users = $Users | Sort-Object -Property DistinguishedName -Unique
            } else {
                $Users = Get-ADUser -Filter "Enabled -eq '$true'" -Properties DisplayName, SamAccountName, PasswordExpired, PasswordLastSet, pwdLastSet, PasswordNeverExpires -Server $QueryServer
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

                if ($User.PasswordExpired -eq $true -and $PasswordAtNextLogon -eq $false -and $User.PasswordNeverExpires -eq $false) {
                    foreach ($I in $IgnoreSamAccountNameTotal) {
                        if ($User.SamAccountName -like $I) {
                            Write-Verbose -Message "Request-ChangePasswordOnExpiry - Ignoring $($User.SamAccountName) / $($User.DistinguishedName)"
                            continue SkipUser
                        }
                    }
                    foreach ($I in $IgnoreDistinguishedNameTotal) {
                        if ($User.DistinguishedName -like $I) {
                            Write-Verbose -Message "Request-ChangePasswordOnExpiry - Ignoring $($User.SamAccountName) / $($User.DistinguishedName)"
                            continue SkipUser
                        }
                    }
                    foreach ($I in $IgnoreDisplayNameTotal) {
                        if ($User.DisplayName -like $I) {
                            Write-Verbose -Message "Request-ChangePasswordOnExpiry - Ignoring $($User.SamAccountName) / $($User.DistinguishedName)"
                            continue SkipUser
                        }
                    }

                    [PSCustomObject] @{
                        SamAccountName       = $User.SamAccountName
                        Domain               = $Domain
                        DisplayName          = $User.DisplayName
                        DistinguishedName    = $User.DistinguishedName
                        PasswordExpired      = $User.PasswordExpired
                        PasswordLastSet      = $User.PasswordLastSet
                        PasswordNeverExpires = $User.PasswordNeverExpires
                    }
                } else {
                    Write-Verbose -Message "Request-ChangePasswordOnExpiry - Skipping $($User.SamAccountName) / $($User.DistinguishedName) - Password already requested at next logon or never expires."
                }
            }
        }
        $Count = 0
        Write-Verbose -Message "Request-ChangePasswordOnExpiry - Found $($UsersFound.Count) expired users. Processing..."
        foreach ($User in $UsersFound) {
            if ($LimitProcessing -and $Count -ge $LimitProcessing) {
                break
            }
            Write-Verbose -Message "Request-ChangePasswordOnExpiry - Setting $($User.SamAccountName) to change password on next logon / $($User.Domain)"
            Set-ADUser -ChangePasswordAtLogon $true -Identity $User.SamAccountName -Server $ForestDetails['QueryServers'][$User.Domain].HostName[0]
            if ($PassThru) {
                $User
            }
            $Count++
        }
    }
}