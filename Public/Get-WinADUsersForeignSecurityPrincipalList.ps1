function Get-WinADUsersForeignSecurityPrincipalList {
    [alias('Get-WinADUsersFP')]
    param(
        [string] $Domain
    )
    $ForeignSecurityPrincipalList = Get-ADObject -Filter { ObjectClass -eq 'ForeignSecurityPrincipal' } -Properties * -Server $Domain
    foreach ($FSP in $ForeignSecurityPrincipalList) {
        Try {
            $Translated = (([System.Security.Principal.SecurityIdentifier]::new($FSP.objectSid)).Translate([System.Security.Principal.NTAccount])).Value
        } Catch {
            $Translated = $null
        }
        Add-Member -InputObject $FSP -Name 'TranslatedName' -Value $Translated -MemberType NoteProperty -Force
    }
    $ForeignSecurityPrincipalList
}