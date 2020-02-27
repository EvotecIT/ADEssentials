function Rename-WinADUserPrincipalName {
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