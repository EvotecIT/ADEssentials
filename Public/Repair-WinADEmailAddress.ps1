function Repair-WinADEmailAddress {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Microsoft.ActiveDirectory.Management.ADAccount] $ADUser,
        #[string] $FromEmail,
        [string] $ToEmail,
        [switch] $Display,
        [Array] $AddSecondary #,
        # [switch] $UpdateMailNickName
    )
    $Summary = [ordered] @{
        SamAccountName       = $ADUser.SamAccountName
        UserPrincipalName    = $ADUser.UserPrincipalName
        EmailAddress         = ''
        ProxyAddresses       = ''
        EmailAddressStatus   = 'Not required'
        ProxyAddressesStatus = 'Not required'
        EmailAddressError    = ''
        ProxyAddressesError  = ''
    }
    $RequiredProperties = @(
        'EmailAddress'
        'proxyAddresses'
        #'mailNickName'
    )
    foreach ($Property in $RequiredProperties) {
        if ($ADUser.PSObject.Properties.Name -notcontains $Property) {
            Write-Warning "Repair-WinADEmailAddress - User $($ADUser.SamAccountName) is missing properties ($($RequiredProperties -join ',')) which are required. Try again."
            return
        }
    }
    $ProcessUser = Get-WinADProxyAddresses -ADUser $ADUser -RemovePrefix
    $EmailAddresses = [System.Collections.Generic.List[string]]::new()
    $ProxyAddresses = [System.Collections.Generic.List[string]]::new()

    $ExpectedUser = [ordered] @{
        EmailAddress = $ToEmail
        Primary      = $ToEmail
        Secondary    = ''
        Sip          = $ProcessUser.Sip
        x500         = $ProcessUser.x500
        Other        = $ProcessUser.Other
        #MailNickName = $ProcessUser.mailNickName
    }

    if (-not $ToEmail) {
        # We didn't wanted to change primary email address so we use whatever is set
        $ExpectedUser.EmailAddress = $ProcessUser.EmailAddress
        $ExpectedUser.Primary = $ProcessUser.Primary
        # this is case where Proxy Addresses of current user don't have email address set as primary
        # we want to fix the user right?
        if (-not $ExpectedUser.Primary -and $ExpectedUser.EmailAddress) {
            $ExpectedUser.Primary = $ExpectedUser.EmailAddress
        }
    }
    # if ($UpdateMailNickName) {

    #}

    # Lets add expected primary to proxy addresses we need
    $MakePrimary = "SMTP:$($ExpectedUser.EmailAddress)"
    $ProxyAddresses.Add($MakePrimary)

    # Lets add expected secondary to proxy addresses we need
    $Types = @('Sip', 'x500', 'Other')
    foreach ($Type in $Types) {
        foreach ($Address in $ExpectedUser.$Type) {
            $ProxyAddresses.Add($Address)
        }
    }

    $TypesEmails = @('Primary', 'Secondary')
    foreach ($Type in $TypesEmails) {
        foreach ($Address in $ProcessUser.$Type) {
            if ($Address -ne $ToEmail) {
                $EmailAddresses.Add($Address)
            }
        }
    }
    foreach ($Email in $EmailAddresses) {
        $ProxyAddresses.Add("smtp:$Email".ToLower())
    }
    foreach ($Email in $AddSecondary) {
        if ($Email -like 'smtp:*') {
            $ProxyAddresses.Add($Email.ToLower())
        } else {
            $ProxyAddresses.Add("smtp:$Email".ToLower())
        }
    }


    # Lets fix primary email address
    $Summary['EmailAddress'] = $ExpectedUser.EmailAddress
    if ($ProcessUser.EmailAddress -ne $ExpectedUser.EmailAddress) {
        if ($PSCmdlet.ShouldProcess($ADUser, "Email $ToEmail will be set in EmailAddresss field (1)")) {
            try {
                Set-ADUser -Identity $ADUser -EmailAddress $ExpectedUser.EmailAddress -ErrorAction Stop
                $Summary['EmailAddressStatus'] = 'Success'
                $Summary['EmailAddressError'] = ''
            } catch {
                $Summary['EmailAddressStatus'] = 'Failed'
                $Summary['EmailAddressError'] = $_.Exception.Message
            }
        } else {
            $Summary['EmailAddressStatus'] = 'Whatif'
            $Summary['EmailAddressError'] = ''
        }
    }

    # lets compare Expected Proxy Addresses, against current list
    # lets make sure in new proxy list we have only unique addresses, so if there are duplicates in existing one it will be replaced
    # We need to also convert it to [string[]] as Set-ADUser with -Replace is very picky about it

    # Replacement for Sort-Object -Unique which removes primary SMTP: if it's duplicate of smtp:
    $UniqueProxyList = [System.Collections.Generic.List[string]]::new()
    foreach ($Proxy in $ProxyAddresses) {
        if ($UniqueProxyList -notcontains $Proxy) {
            $UniqueProxyList.Add($Proxy)
        }
    }

    [string[]] $ExpectedProxyAddresses = ($UniqueProxyList | Sort-Object | ForEach-Object { $_ })
    [string[]] $CurrentProxyAddresses = ($ADUser.ProxyAddresses | Sort-Object | ForEach-Object { $_ })
    $Summary['ProxyAddresses'] = $ExpectedProxyAddresses -join ';'
    # we need to compare case sensitive
    if (Compare-Object -ReferenceObject $ExpectedProxyAddresses -DifferenceObject $CurrentProxyAddresses -CaseSensitive) {
        if ($PSCmdlet.ShouldProcess($ADUser, "Email $ExpectedProxyAddresses will replace proxy addresses (2)")) {
            try {
                Set-ADUser -Identity $ADUser -Replace @{ proxyAddresses = $ExpectedProxyAddresses } -ErrorAction Stop
                $Summary['ProxyAddressesStatus'] = 'Success'
                $Summary['ProxyAddressesError'] = ''
            } catch {
                $Summary['ProxyAddressesStatus'] = 'Failed'
                $Summary['ProxyAddressesError'] = $_.Exception.Message
            }
        } else {
            $Summary['ProxyAddressesStatus'] = 'WhatIf'
            $Summary['ProxyAddressesError'] = ''
        }
    }
    if ($Display) {
        [PSCustomObject] $Summary
    }
}


<#
    if ($FromEmail -and $FromEmail -like '*@*') {
        if ($FromEmail -ne $ToEmail) {
            $FindSecondary = "SMTP:$FromEmail"
            if ($ProcessUser.Primary -contains $FromEmail) {
                if ($PSCmdlet.ShouldProcess($ADUser, "Email $FindSecondary will be removed from proxy addresses as primary (1)")) {
                    Set-ADUser -Identity $ADUser -Remove @{ proxyAddresses = $FindSecondary }
                }
            }
            $MakeSecondary = "smtp:$FromEmail"
            if ($ProcessUser.Secondary -notcontains $FromEmail) {
                if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakeSecondary will be added to proxy addresses as secondary (2)")) {
                    Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakeSecondary }
                }
            }
        }
    }
    if ($ToEmail -and $ToEmail -like '*@*') {
        if ($ProcessUser.EmailAddress -ne $ToEmail) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $ToEmail will be set in EmailAddresss field (3)")) {
                Set-ADUser -Identity $ADUser -EmailAddress $ToEmail
            }
        }
        if ($ProcessUser.Secondary -contains $ToEmail) {
            $RemovePotential = "smtp:$ToEmail"
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $RemovePotential will be removed from proxy addresses (4)")) {
                Set-ADUser -Identity $ADUser -Remove @{ proxyAddresses = $RemovePotential }
            }
        }
        $MakePrimary = "SMTP:$ToEmail"
        if ($ProcessUser.Primary.Count -in @(0, 1) -and $ProcessUser.Primary -notcontains $ToEmail) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakePrimary will be added to proxy addresses as primary (5)")) {
                Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakePrimary }
            }
        } elseif ($ProcessUser.Primary.Count -gt 1) {
            [Array] $PrimaryEmail = $ProcessUser.Primary | Sort-Object -Unique
            if ($PrimaryEmail.Count -eq 1) {
                if ($PrimaryEmail -ne $ToEmail) {
                    if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakePrimary will be added to proxy addresses as primary (6)")) {
                        Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakePrimary }
                    }
                } else {
                    if ($ProcessUser.Secondary -notcontains $PrimaryEmail) {
                        $MakeSecondary = "smtp:$PrimaryEmail"
                        if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakeSecondary will be added to proxy addresses as secondary (7)")) {
                            Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakeSecondary }
                        }
                    }
                }
            } else {
                foreach ($Email in $PrimaryEmail) {

                }
            }
        }

        if ($ProcessUser.Primary -notcontains $ToEmail) {
            #if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakePrimary will be added to proxy addresses as primary (6)")) {
            #    Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakePrimary }
            #}
        }

    }
    if ($Display) {
        $ProcessUser
    }
    #>


<#
    if ($FromEmail -and $FromEmail -like '*@*') {
        if ($FromEmail -ne $ToEmail) {
            $FindSecondary = "SMTP:$FromEmail"
            if ($ADUser.ProxyAddresses -ccontains $FindSecondary) {
                if ($PSCmdlet.ShouldProcess($ADUser, "Email $FindSecondary will be removed from proxy addresses as primary (1)")) {
                    Set-ADUser -Identity $ADUser -Remove @{ proxyAddresses = $FindSecondary }
                }
            }
            $MakeSecondary = "smtp:$FromEmail"
            if ($ADUser.ProxyAddresses -cnotcontains $MakeSecondary) {
                if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakeSecondary will be added to proxy addresses as secondary (2)")) {
                    Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakeSecondary }
                }
            }
        }
    }
    if ($ToEmail -and $ToEmail -like '*@*') {
        $RemovePotential = "smtp:$ToEmail"
        $MakePrimary = "SMTP:$ToEmail"
        if ($ADUser.EmailAddress -ne $ToEmail) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $ToEmail will be set in EmailAddresss field (3)")) {
                Set-ADUser -Identity $ADUser -EmailAddress $ToEmail
            }
        }
        if ($ADUser.ProxyAddresses -ccontains $RemovePotential) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $RemovePotential will be removed from proxy addresses (4)")) {
                Set-ADUser -Identity $ADUser -Remove @{ proxyAddresses = $RemovePotential }
            }
        }
        if ($ADUser.ProxyAddresses -cnotcontains $MakePrimary) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakePrimary will be added to proxy addresses as primary (5)")) {
                Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakePrimary }
            }
        }
    }
    #>
#}