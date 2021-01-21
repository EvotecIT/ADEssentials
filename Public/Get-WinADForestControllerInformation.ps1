function Get-WinADForestControllerInformation {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -Verbose:$false
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

            $DNS = Resolve-DnsName -DnsOnly -Name $DC.DNSHostName -ErrorAction SilentlyContinue -QuickTimeout -Verbose:$false
            if ($DNS) {
                $ResolvedIP = $DNS.IPAddress
                $DNSStatus = $true
            } else {
                $ResolvedIP = ''
                $DNSStatus = $false
            }

            [PSCustomObject] @{
                DNSHostName                = $DC.DNSHostName
                DomainName                 = $Domain
                Enabled                    = $DC.Enabled
                DNSStatus                  = $DNSStatus
                IPAddressStatus            = $ResolvedIP -eq $DC.IPv4Address
                ManagerNotSet              = $Null -eq $ManagedBy
                OwnerType                  = $Owner.OwnerType
                PasswordLastChangedDays    = $PasswordLastChangedDays
                LastLogonDays              = $LastLogonDays
                Owner                      = $Owner.OwnerName
                OwnerSid                   = $Owner.OwnerSid
                ManagedBy                  = $DC.ManagedBy
                DNSResolvedIP              = $ResolvedIP
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