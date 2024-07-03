function Get-WinADUserPrincipalName {
    <#
    .SYNOPSIS
    Modifies the UserPrincipalName of a user object based on specified parameters.

    .DESCRIPTION
    This function takes a user object and a domain name as input. It can modify the UserPrincipalName of the user object based on the following options:
    - Replace the domain part of the UserPrincipalName with the specified domain name.
    - Construct a new UserPrincipalName in the format GivenName.Surname@DomainName.
    - Remove Latin characters from the UserPrincipalName.
    - Convert the UserPrincipalName to lowercase.

    .PARAMETER User
    The user object whose UserPrincipalName is to be modified.

    .PARAMETER DomainName
    The domain name to be used for replacing the domain part of the UserPrincipalName or constructing a new UserPrincipalName.

    .PARAMETER ReplaceDomain
    Switch to replace the domain part of the UserPrincipalName with the specified domain name.

    .PARAMETER NameSurname
    Switch to construct a new UserPrincipalName in the format GivenName.Surname@DomainName.

    .PARAMETER FixLatinChars
    Switch to remove Latin characters from the UserPrincipalName.

    .PARAMETER ToLower
    Switch to convert the UserPrincipalName to lowercase.

    .EXAMPLE
    Get-WinADUserPrincipalName -User $userObject -DomainName "example.com" -ReplaceDomain
    Replaces the domain part of the UserPrincipalName with "example.com".

    .EXAMPLE
    Get-WinADUserPrincipalName -User $userObject -DomainName "example.com" -NameSurname
    Constructs a new UserPrincipalName in the format GivenName.Surname@example.com.

    .EXAMPLE
    Get-WinADUserPrincipalName -User $userObject -DomainName "example.com" -FixLatinChars
    Removes Latin characters from the UserPrincipalName.

    .EXAMPLE
    Get-WinADUserPrincipalName -User $userObject -DomainName "example.com" -ToLower
    Converts the UserPrincipalName to lowercase.
    #>
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