function Get-WinADProxyAddresses {
    <#
    .SYNOPSIS
    Retrieves and organizes proxy addresses for an Active Directory user.

    .DESCRIPTION
    This function retrieves and organizes the proxy addresses associated with an Active Directory user. It categorizes the addresses into primary, secondary, SIP, X500, and other types based on their prefixes. It also provides options to remove prefixes, convert data to lowercase, and format the output for display purposes.

    .PARAMETER ADUser
    Specifies the Active Directory user object for which to retrieve proxy addresses.

    .PARAMETER RemovePrefix
    Indicates whether to remove the prefix (e.g., SMTP:, smtp:) from the proxy addresses.

    .PARAMETER ToLower
    Specifies whether to convert all returned data to lowercase.

    .PARAMETER Formatted
    Indicates whether the data should be formatted for display purposes rather than for working with objects.

    .PARAMETER Splitter
    Specifies the character used to join multiple data elements together, such as an array of aliases.

    .EXAMPLE
    $ADUsers = Get-ADUser -Filter "*" -Properties ProxyAddresses
    foreach ($User in $ADUsers) {
        Get-WinADProxyAddresses -ADUser $User
    }

    .EXAMPLE
    $ADUsers = Get-ADUser -Filter "*" -Properties ProxyAddresses
    foreach ($User in $ADUsers) {
        Get-WinADProxyAddresses -ADUser $User -RemovePrefix
    }

    .NOTES
    This function requires the Active Directory module to be available. It provides a structured view of proxy addresses for an AD user.
    #>
    [CmdletBinding()]
    param(
        [Object] $ADUser,
        [switch] $RemovePrefix,
        [switch] $ToLower,
        [switch] $Formatted,
        [alias('Joiner')][string] $Splitter = ','
    )
    $Summary = [PSCustomObject] @{
        EmailAddress = $ADUser.EmailAddress
        Primary      = [System.Collections.Generic.List[string]]::new()
        Secondary    = [System.Collections.Generic.List[string]]::new()
        Sip          = [System.Collections.Generic.List[string]]::new()
        x500         = [System.Collections.Generic.List[string]]::new()
        Other        = [System.Collections.Generic.List[string]]::new()
        Broken       = [System.Collections.Generic.List[string]]::new()
       # MailNickname = $ADUser.mailNickName
    }
    foreach ($Proxy in $ADUser.ProxyAddresses) {
        if ($Proxy -like '*,*') {
            # Most likely someone added proxy address with comma instead of each email address separatly
            $Summary.Broken.Add($Proxy)
        } elseif ($Proxy.StartsWith('SMTP:')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Primary.Add($Proxy)
        } elseif ($Proxy.StartsWith('smtp:') -or $Proxy -notlike "*:*") {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'smtp:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Secondary.Add($Proxy)
        } elseif ($Proxy.StartsWith('x500')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy #-replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.x500.Add($Proxy)
        } elseif ($Proxy.StartsWith('sip:')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy #-replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Sip.Add($Proxy)
        } else {
            if ($RemovePrefix) {
                $Proxy = $Proxy #-replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Other.Add($Proxy)
        }
    }
    if ($Formatted) {
        $Summary.Primary = $Summary.Primary -join $Splitter
        $Summary.Secondary = $Summary.Secondary -join $Splitter
        $Summary.Sip = $Summary.Sip -join $Splitter
        $Summary.x500 = $Summary.x500 -join $Splitter
        $Summary.Other = $Summary.Other -join $Splitter
    }
    $Summary
}