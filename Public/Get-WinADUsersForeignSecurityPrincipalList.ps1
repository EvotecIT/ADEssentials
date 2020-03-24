function Get-WinADUsersForeignSecurityPrincipalList {
    [alias('Get-WinADUsersFP')]
    param(
        [alias('ForestName')][string] $Forest,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $ForeignSecurityPrincipalList = Get-ADObject -Filter { ObjectClass -eq 'ForeignSecurityPrincipal' } -Properties * -Server $QueryServer
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
}