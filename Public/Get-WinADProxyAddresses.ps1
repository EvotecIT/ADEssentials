function Get-WinADProxyAddresses {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER ADUser
    ADUser Object

    .PARAMETER RemovePrefix
    Removes prefix from proxy address such as SMTP: or smtp:

    .PARAMETER ToLower
    Makes sure all returned data is lower case

    .PARAMETER Formatted
    Makes sure data is formatted for display, rather than for working with objects

    .PARAMETER Splitter
    Splitter or Joiner that connects data together such as an array of 3 aliases

    .EXAMPLE
    $ADUsers = Get-ADUser -Filter * -Properties ProxyAddresses
    foreach ($User in $ADUsers) {
        Get-WinADProxyAddresses -ADUser $User
    }

    .EXAMPLE
    $ADUsers = Get-ADUser -Filter * -Properties ProxyAddresses
    foreach ($User in $ADUsers) {
        Get-WinADProxyAddresses -ADUser $User -RemovePrefix
    }

    .NOTES
    General notes
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