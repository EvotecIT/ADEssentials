function Get-WinADForestControllerInformation {
    <#
    .SYNOPSIS
    Retrieves information about domain controllers in a specified Active Directory forest.

    .DESCRIPTION
    This function retrieves detailed information about domain controllers within the specified Active Directory forest.
    It queries the forest for domain controller properties such as PrimaryGroupID, OperatingSystem, LastLogonDate, etc.

    .PARAMETER Forest
    Specifies the target forest to retrieve domain controller information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest for retrieving domain controller details.

    .EXAMPLE
    Get-WinADForestControllerInformation -Forest "example.com" -IncludeDomains @("example.com") -ExcludeDomains @("test.com")

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
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
        $Properties = @(
            'PrimaryGroupID'
            'PrimaryGroup'
            'Enabled'
            'ManagedBy'
            'OperatingSystem'
            'OperatingSystemVersion'
            'PasswordLastSet'
            'PasswordExpired'
            'PasswordNeverExpires'
            'PasswordNotRequired'
            'TrustedForDelegation'
            'UseDESKeyOnly'
            'TrustedToAuthForDelegation'
            'WhenCreated'
            'WhenChanged'
            'LastLogonDate'
            'IPv4Address'
            'IPv6Address'
        )
        $Filter = 'Name -ne "AzureADKerberos" -and DNSHostName -like "*"'
        $DCs = Get-ADComputer -Server $QueryServer -SearchBase $ForestInformation['DomainsExtended'][$Domain].DomainControllersContainer -Filter $Filter -Properties $Properties
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

            $Options = Get-WinADDomainControllerOption -DomainController $DC.DNSHostName
            if ($Options.Options -contains 'DISABLE_OUTBOUND_REPL') {
                $DisabledOutboundReplication = $true
            } else {
                $DisabledOutboundReplication = $false
            }
            if ($Options.Options -contains 'DISABLE_INBOUND_REPL') {
                $DisabledInboundReplication = $true
            } else {
                $DisabledInboundReplication = $false
            }
            if ($Options.Options -contains "IS_GC") {
                $IsGlobalCatalog = $true
            } else {
                $IsGlobalCatalog = $false
            }
            if ($Options.Options -contains 'IS_RODC') {
                $IsReadOnlyDomainController = $true
            } else {
                $IsReadOnlyDomainController = $false
            }

            $Roles = [ordered] @{}
            $Roles['SchemaMaster'] = $ForestInformation.Forest.SchemaMaster
            $Roles['DomainNamingMaster'] = $ForestInformation.Forest.DomainNamingMaster
            $Roles['InfrastructureMaster'] = $ForestInformation.DomainsExtended[$Domain].InfrastructureMaster
            $Roles['RIDMaster'] = $ForestInformation.DomainsExtended[$Domain].RIDMaster
            $Roles['PDCEmulator'] = $ForestInformation.DomainsExtended[$Domain].PDCEmulator


            $DNS = Resolve-DnsName -DnsOnly -Name $DC.DNSHostName -ErrorAction SilentlyContinue -QuickTimeout -Verbose:$false
            if ($DNS) {
                $ResolvedIP4 = ($DNS | Where-Object { $_.Section -eq 'Answer' -and $_.Type -eq 'A' }).IPAddress
                $ResolvedIP6 = ($DNS | Where-Object { $_.Section -eq 'Answer' -and $_.Type -eq 'AAAA' }).IPAddress
                $DNSStatus = $true
            } else {
                $ResolvedIP4 = $null
                $ResolvedIP6 = $null
                $DNSStatus = $false
            }
            [PSCustomObject] @{
                DNSHostName                 = $DC.DNSHostName
                DomainName                  = $Domain
                Enabled                     = $DC.Enabled
                DNSStatus                   = $DNSStatus
                IsGC                        = $IsGlobalCatalog
                IsRODC                      = $IsReadOnlyDomainController
                IPAddressStatusV4           = if ($ResolvedIP4 -eq $DC.IPv4Address) { $true } else { $false }
                IPAddressStatusV6           = if ($ResolvedIP6 -eq $DC.IPv6Address) { $true } else { $false }
                IPAddressHasOneIpV4         = $ResolvedIP4 -isnot [Array]
                IPAddressHasOneipV6         = $ResolvedIP6 -isnot [Array]
                ManagerNotSet               = $Null -eq $ManagedBy
                OwnerType                   = $Owner.OwnerType
                PasswordLastChangedDays     = $PasswordLastChangedDays
                LastLogonDays               = $LastLogonDays
                Owner                       = $Owner.OwnerName
                OwnerSid                    = $Owner.OwnerSid
                ManagedBy                   = $DC.ManagedBy
                DNSResolvedIPv4             = $ResolvedIP4
                DNSResolvedIPv6             = $ResolvedIP6
                IPv4Address                 = $DC.IPv4Address
                IPv6Address                 = $DC.IPv6Address
                LastLogonDate               = $DC.LastLogonDate
                OperatingSystem             = $DC.OperatingSystem
                OperatingSystemVersion      = $DC.OperatingSystemVersion
                PasswordExpired             = $DC.PasswordExpired
                PasswordLastSet             = $DC.PasswordLastSet
                PasswordNeverExpires        = $DC.PasswordNeverExpires
                PasswordNotRequired         = $DC.PasswordNotRequired
                TrustedForDelegation        = $DC.TrustedForDelegation
                TrustedToAuthForDelegation  = $DC.TrustedToAuthForDelegation
                DisabledOutboundReplication = $DisabledOutboundReplication
                DisabledInboundReplication  = $DisabledInboundReplication
                Options                     = $Options.Options -join ', '
                UseDESKeyOnly               = $DC.UseDESKeyOnly
                SchemaMaster                = if ($Roles['SchemaMaster'] -eq $DC.DNSHostName) { $true } else { $false }
                DomainNamingMaster          = if ($Roles['DomainNamingMaster'] -eq $DC.DNSHostName) { $true } else { $false }
                InfrastructureMaster        = if ($Roles['InfrastructureMaster'] -eq $DC.DNSHostName) { $true } else { $false }
                RIDMaster                   = if ($Roles['RIDMaster'] -eq $DC.DNSHostName) { $true } else { $false }
                PDCEmulator                 = if ($Roles['PDCEmulator'] -eq $DC.DNSHostName) { $true } else { $false }
                WhenCreated                 = $DC.WhenCreated
                WhenChanged                 = $DC.WhenChanged
                DistinguishedName           = $DC.DistinguishedName
            }
        }
    }
}