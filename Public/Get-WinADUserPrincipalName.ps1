function Get-WinADUserPrincipalName {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][Object] $User,
        [Parameter(Mandatory = $true)][string] $DomainName,
        [switch] $ReplaceDomain,
        [switch] $NameSurname,
        [switch] $FixLatinChars,
        [switch] $ToLower
    )
    if ($User.UserPrincipalName) {
        $NewUserName = $User.UserPrincipalName

        if ($ReplaceDomain) {
            $NewUserName = ($User.UserPrincipalName -split '@')[0]
            $NewUserName = -join ($NewUserName, '@', $DomainName)
        }
        if ($NameSurname) {
            if ($User.GivenName -and $User.Surname) {
                $NewUsername = -join ($User.GivenName, '.', $User.Surname, '@', $DomainName)
            } else {
                Write-Warning "Get-WinADUserPrincipalName - UserPrincipalName couldn't be changed to GivenName.SurName@$DomainName"
            }
        }

        if ($FixLatinChars) {
            $NewUsername = Remove-StringLatinCharacters -String $NewUsername
        }
        if ($ToLower) {
            $NewUsername = $NewUserName.ToLower()
        }

        if ($NewUserName -eq $User.UserPrincipalName) {
            Write-Warning "Get-WinADUserPrincipalName - UserPrincipalName didn't change. Stays as $NewUserName"
        }
        $NewUsername
    }
}