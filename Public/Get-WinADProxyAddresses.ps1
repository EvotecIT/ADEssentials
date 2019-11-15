function Get-WinADProxyAddresses {
    [CmdletBinding()]
    param(
        [Microsoft.ActiveDirectory.Management.ADAccount] $ADUser,
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
    }

    foreach ($_ in $ADUser.ProxyAddresses) {
        $Proxy = $_
        if ($_.StartsWith('SMTP:')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Primary.Add($Proxy)
        } elseif ($_.StartsWith('smtp:')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Secondary.Add($Proxy)
        } elseif ($_.StartsWith('x500')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.x500.Add($Proxy)
        } elseif ($_.StartsWith('sip:')) {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'SMTP:', ''
            }
            if ($ToLower) {
                $Proxy = $Proxy.ToLower()
            }
            $Summary.Sip.Add($Proxy)
        } else {
            if ($RemovePrefix) {
                $Proxy = $Proxy -replace 'SMTP:', ''
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