function Get-WinADForestControllerInformation {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers'][$Domain]['HostName'][0]
        $DCs = Get-ADComputer -Server $QueryServer -SearchBase $ForestInformation['DomainsExtended'][$Domain].DomainControllersContainer -Filter * -Properties PrimaryGroupID, PrimaryGroup, Enabled, ManagedBy, OperatingSystem, OperatingSystemVersion, PasswordLastSet, PasswordExpired, PasswordNeverExpires, PasswordNotRequired, TrustedForDelegation, UseDESKeyOnly, TrustedToAuthForDelegation, WhenCreated, WhenChanged, LastLogonDate, IPv4Address, IPv6Address
        $Count = 0
        foreach ($DC in $DCs) {
            $Count++
            Write-Verbose -Message "Get-WinADForestControllerInformation - Processing [$($Domain)]($Count/$($DCs.Count)) $($DC.DNSHostName)"
            $Owner = Get-ADACLOwner -ADObject $DC.DistinguishedName -Resolve

            if ($null -ne $DC.LastLogonDate) {
                [int] $LastLogonDays = "$(-$($DC.LastLogonDate - $Today).Days)"
            } else {
                $LastLogonDays = $null
            }
            if ($null -ne $DC.PasswordLastSet) {
                [int] $PasswordLastChangedDays = "$(-$($DC.PasswordLastSet - $Today).Days)"
            } else {
                $PasswordLastChangedDays = $null
            }

            [PSCustomObject] @{
                DNSHostName                = $DC.DNSHostName
                DomainName                 = $Domain
                Enabled                    = $DC.Enabled
                #PrimaryGroup               = $DC.PrimaryGroup
                #PrimaryGroupID             = $DC.PrimaryGroupID
                Owner                      = $Owner.OwnerName
                OwnerSid                   = $Owner.OwnerSid
                OwnerType                  = $Owner.OwnerType
                ManagedBy                  = $DC.ManagedBy
                PasswordLastChangedDays    = $PasswordLastChangedDays
                LastLogonDays              = $LastLogonDays
                IPv4Address                = $DC.IPv4Address
                IPv6Address                = $DC.IPv6Address
                LastLogonDate              = $DC.LastLogonDate
                OperatingSystem            = $DC.OperatingSystem
                OperatingSystemVersion     = $DC.OperatingSystemVersion
                PasswordExpired            = $DC.PasswordExpired
                PasswordLastSet            = $DC.PasswordLastSet
                PasswordNeverExpires       = $DC.PasswordNeverExpires
                PasswordNotRequired        = $DC.PasswordNotRequired
                TrustedForDelegation       = $DC.TrustedForDelegation
                TrustedToAuthForDelegation = $DC.TrustedToAuthForDelegation
                UseDESKeyOnly              = $DC.UseDESKeyOnly
                WhenCreated                = $DC.WhenCreated
                WhenChanged                = $DC.WhenChanged
                DistinguishedName          = $DC.DistinguishedName
            }
        }
    }
}