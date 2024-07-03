function Rename-WinADUserPrincipalName {
    <#
    .SYNOPSIS
    Renames the UserPrincipalName of one or more Active Directory users based on specified parameters.

    .DESCRIPTION
    This function iterates through an array of users and generates a new UserPrincipalName based on the provided domain name and optional parameters. 
    It then compares the new UserPrincipalName with the existing one and updates it if they differ. The update operation can be simulated with the -WhatIf switch.

    .PARAMETER Users
    An array of user objects to process.

    .PARAMETER DomainName
    The domain name to use for the new UserPrincipalName.

    .PARAMETER ReplaceDomain
    If specified, the existing domain name in the UserPrincipalName will be replaced with the provided DomainName.

    .PARAMETER NameSurname
    If specified, the UserPrincipalName will be generated using the user's name and surname.

    .PARAMETER FixLatinChars
    If specified, Latin characters with diacritics will be replaced with their closest ASCII equivalent.

    .PARAMETER ToLower
    If specified, the UserPrincipalName will be converted to lowercase.

    .PARAMETER WhatIf
    Simulates the renaming operation without making actual changes.

    .EXAMPLE
    Rename-WinADUserPrincipalName -Users $users -DomainName "example.local" -ReplaceDomain -ToLower
    Renames the UserPrincipalName of the users in the $users array to use the "example.local" domain and converts it to lowercase.

    .EXAMPLE
    Rename-WinADUserPrincipalName -Users $users -DomainName "example.local" -NameSurname -FixLatinChars -WhatIf
    Simulates the renaming of the UserPrincipalName of the users in the $users array using their name and surname, replacing Latin characters with diacritics with their closest ASCII equivalent.
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][Array] $Users,
        [Parameter(Mandatory = $true)][string] $DomainName,
        [switch] $ReplaceDomain,
        [switch] $NameSurname,
        [switch] $FixLatinChars,
        [switch] $ToLower,
        [switch] $WhatIf
    )
    foreach ($User in $Users) {
        $NewUserPrincipalName = Get-WinADUserPrincipalName -User $User -DomainName $DomainName -ReplaceDomain:$ReplaceDomain -NameSurname:$NameSurname -FixLatinChars:$FixLatinChars -ToLower:$ToLower
        if ($NewUserPrincipalName -ne $User.UserPrincipalName) {
            Set-ADUser -Identity $User.DistinguishedName -UserPrincipalName $NewUserPrincipalName -WhatIf:$WhatIf
        }
    }
}