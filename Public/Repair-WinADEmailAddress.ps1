function Repair-WinADEmailAddress {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Microsoft.ActiveDirectory.Management.ADAccount] $ADUser,
        [string] $FromEmail,
        [string] $ToEmail,
        [switch] $Display
    )

    $ProcessUser = Get-WinADProxyAddresses -ADUser $ADUser -RemovePrefix
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
        $RemovePotential = "smtp:$ToEmail"
        $MakePrimary = "SMTP:$ToEmail"
        if ($ProcessUser.EmailAddress -ne $ToEmail) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $ToEmail will be set in EmailAddresss field (3)")) {
                Set-ADUser -Identity $ADUser -EmailAddress $ToEmail
            }
        }
        if ($ProcessUser.Secondary -contains $ToEmail) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $RemovePotential will be removed from proxy addresses (4)")) {
                Set-ADUser -Identity $ADUser -Remove @{ proxyAddresses = $RemovePotential }
            }
        }
        if ($ProcessUser.Primary -notcontains $ToEmail) {
            if ($PSCmdlet.ShouldProcess($ADUser, "Email $MakePrimary will be added to proxy addresses as primary (5)")) {
                Set-ADUser -Identity $ADUser -Add @{ proxyAddresses = $MakePrimary }
            }
        }
    }
    if ($Display) {
        $ProcessUser
    }


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
}