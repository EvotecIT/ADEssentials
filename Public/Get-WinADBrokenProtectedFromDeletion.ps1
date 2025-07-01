function Get-WinADBrokenProtectedFromDeletion {
    <#
    .SYNOPSIS
    Identifies Active Directory objects with inconsistent protection from accidental deletion settings.    .DESCRIPTION
    This cmdlet scans Active Directory for objects where the ProtectedFromAccidentalDeletion flag doesn't match
    the actual ACL settings. It helps identify objects that might be at risk of accidental deletion despite
    appearing to be protected, or vice versa.

    The cmdlet supports two modes of operation:
    1. Domain/Forest-wide scanning using the Type parameter to specify object types
    2. Targeted scanning using the DistinguishedName parameter to check specific objects

    .PARAMETER Forest
    The name of the forest to scan. If not specified, the current forest is used.

    .PARAMETER ExcludeDomains
    Array of domain names to exclude from scanning.

    .PARAMETER IncludeDomains
    Array of domain names to include in scanning. If not specified, all domains are scanned.

    .PARAMETER ExtendedForestInformation
    Dictionary containing cached forest information to improve performance.    .PARAMETER DistinguishedName
    Array of Distinguished Names to check for broken protection settings.
    When specified, only these specific objects will be checked instead of scanning entire domains.

    .PARAMETER Type
    Specifies the types of objects to scan when doing domain-wide scans. Valid values are:
    - Computer
    - Group
    - User
    - ManagedServiceAccount
    - GroupManagedServiceAccount
    - Contact
    - All
    This parameter is ignored when DistinguishedName is specified.

    .PARAMETER Resolve
    Switch to enable name resolution for Everyone permission.
    This is only nessecary if you have non-english AD, as Everyone is not Everyone in all languages.

    .PARAMETER ReturnBrokenOnly
    Switch to return only objects with inconsistent protection settings.

    .PARAMETER LimitProcessing
    Limits the number of objects to process.    .EXAMPLE
    Get-WinADBrokenProtectedFromDeletion -DistinguishedName "CN=TestUser,CN=Users,DC=contoso,DC=com"
    Checks a specific user object for broken protection settings.

    .EXAMPLE
    Get-WinADBrokenProtectedFromDeletion -DistinguishedName @("CN=TestUser,CN=Users,DC=contoso,DC=com", "CN=TestComputer,CN=Computers,DC=contoso,DC=com") -ReturnBrokenOnly
    Checks multiple specific objects and returns only those with broken protection settings.

    .EXAMPLE
    Get-WinADBrokenProtectedFromDeletion -Type All
    Scans all supported object types in the current forest for broken protection settings.

    .EXAMPLE
    Get-WinADBrokenProtectedFromDeletion -Type User,Computer -Forest "contoso.com" -ReturnBrokenOnly
    Scans user and computer objects in the specified forest and returns only those with broken protection settings.    .NOTES
    This cmdlet performs ACL checks against the Everyone group (S-1-1-0) to determine if delete permissions
    are properly denied.

    When using DistinguishedName parameter, the cmdlet automatically determines the appropriate domain
    controllers to query based on the DN structure, making it efficient for cross-domain queries.
    #>
    [CmdletBinding(DefaultParameterSetName = 'DomainScan')]
    param(
        [Parameter(ParameterSetName = 'DomainScan')]
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [alias('ForestName')][string] $Forest,

        [Parameter(ParameterSetName = 'DomainScan')]
        [string[]] $ExcludeDomains,

        [Parameter(ParameterSetName = 'DomainScan')]
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,

        [Parameter(ParameterSetName = 'DomainScan')]
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [System.Collections.IDictionary] $ExtendedForestInformation,

        [Parameter(ParameterSetName = 'DistinguishedName', Mandatory)]
        [string[]] $DistinguishedName,

        [Parameter(ParameterSetName = 'DomainScan')]
        [ValidateSet(
            'Computer',
            'Group',
            'User',
            'ManagedServiceAccount',
            'GroupManagedServiceAccount',
            'Contact',
            'All'
        )][string[]] $Type = 'All',

        [Parameter(ParameterSetName = 'DomainScan')]
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [switch] $Resolve,

        [Parameter(ParameterSetName = 'DomainScan')]
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [switch] $ReturnBrokenOnly,

        [Parameter(ParameterSetName = 'DomainScan')]
        [Parameter(ParameterSetName = 'DistinguishedName')]
        [int] $LimitProcessing
    )

    # Available objectClasses
    # builtinDomain, classStore, computer, contact, container, dfsConfiguration, dnsNode, dnsZone, domainDNS, domainPolicy, fileLinkTracking, foreignSecurityPrincipal, group, groupPolicyContainer, inetOrgPerson, infrastructureUpdate, ipsecFilter, ipsecISAKMPPolicy, ipsecNegotiationPolicy, ipsecNFA, ipsecPolicy, linkTrackObjectMoveTable, linkTrackVolumeTable, lostAndFound, msDFSR-Connection, msDFSR-Content, msDFSR-ContentSet, msDFSR-GlobalSettings, msDFSR-LocalSettings, msDFSR-Member, msDFSR-ReplicationGroup, msDFSR-Subscriber, msDFSR-Subscription, msDFSR-Topology, msDS-GroupManagedServiceAccount, msDS-ManagedServiceAccount, msDS-PasswordSettings, msDS-PasswordSettingsContainer, msDS-QuotaContainer, msExchActiveSyncDevice, msExchActiveSyncDevices, msExchSystemMailbox, msExchSystemObjectsContainer, msFVE-RecoveryInformation, msImaging-PSPs, msPrint-ConnectionPolicy, msTPM-InformationObjectsContainer, msWMI-Som, nTFRSSettings, packageRegistration, rIDManager, rIDSet, rpcContainer, samServer, secret, serviceConnectionPoint, trustedDomain, user
    $Today = Get-Date
    $Properties = @(
        'ProtectedFromAccidentalDeletion'
        'NTSecurityDescriptor'
        'SamAccountName'
        'objectSid'
        'ObjectClass'
        'whenChanged'
        'whenCreated'
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    $CountGlobalBroken = 0

    # If DistinguishedName is specified, process those specific objects
    if ($DistinguishedName) {
        Write-Verbose "Get-WinADBrokenProtectedFromDeletion - Processing $($DistinguishedName.Count) specific objects by Distinguished Name"        # Group DNs by domain for efficient processing
        $DomainGroups = @{}
        foreach ($DN in $DistinguishedName) {
            $DomainFromDN = ConvertFrom-DistinguishedName -DistinguishedName $DN -ToDomainCN
            if (-not $DomainGroups.ContainsKey($DomainFromDN)) {
                $DomainGroups[$DomainFromDN] = @()
            }
            $DomainGroups[$DomainFromDN] += $DN
        }

        foreach ($DomainName in $DomainGroups.Keys) {
            Write-Verbose "Get-WinADBrokenProtectedFromDeletion - Processing $($DomainGroups[$DomainName].Count) objects in domain $DomainName"

            # Find the appropriate server for this domain
            $Server = $null
            if ($ForestInformation.QueryServers.ContainsKey($DomainName)) {
                $Server = $ForestInformation.QueryServers[$DomainName].HostName[0]
            } else {
                Write-Warning "Get-WinADBrokenProtectedFromDeletion - Unable to find server for domain $DomainName, using default"
            }

            [Array] $Objects = @(
                foreach ($DN in $DomainGroups[$DomainName]) {
                    try {
                        if ($Server) {
                            Get-ADObject -Identity $DN -Properties $Properties -Server $Server -ErrorAction Stop
                        } else {
                            Get-ADObject -Identity $DN -Properties $Properties -ErrorAction Stop
                        }
                    } catch {
                        Write-Warning "Get-WinADBrokenProtectedFromDeletion - Failed to retrieve object: $DN. Error: $($_.Exception.Message)"
                    }
                }
            )

            if ($Objects.Count -gt 0) {
                $ProcessedCount = 0
                foreach ($Object in $Objects) {
                    $ProcessedCount++
                    Write-Verbose "Get-WinADBrokenProtectedFromDeletion - Processing object $ProcessedCount of $($Objects.Count): $($Object.DistinguishedName)"

                    if ($Resolve) {
                        # If we want to resolve because of non-english AD
                        $ACL = Get-ADACL -ADObject $Object -AccessControlType Deny -Resolve -Principal 'S-1-1-0' -IncludeActiveDirectoryRightsExactMatch 'DeleteTree', 'Delete'
                    } else {
                        $ACL = Get-ADACL -ADObject $Object -AccessControlType Deny -Principal 'Everyone' -IncludeActiveDirectoryRightsExactMatch 'DeleteTree', 'Delete'
                    }
                    if ($ACL) {
                        $ACLContainsDenyDeleteTree = $true
                    } else {
                        $ACLContainsDenyDeleteTree = $false
                    }
                    if ($ACLContainsDenyDeleteTree -eq $true -and $Object.ProtectedFromAccidentalDeletion -eq $false) {
                        $HasBrokenPermissions = $true
                    } else {
                        $HasBrokenPermissions = $false
                    }
                    if ($ReturnBrokenOnly -and $HasBrokenPermissions -eq $false) {
                        continue
                    }
                    if ($HasBrokenPermissions) {
                        $CountGlobalBroken++
                    }

                    [PSCustomObject] @{
                        Name                            = $Object.Name
                        SamAccountName                  = $Object.SamAccountName
                        Domain                          = $DomainName
                        HasBrokenPermissions            = $HasBrokenPermissions
                        ProtectedFromAccidentalDeletion = $Object.ProtectedFromAccidentalDeletion
                        ACLContainsDenyDeleteTree       = $ACLContainsDenyDeleteTree
                        ObjectSID                       = $Object.objectSid
                        ObjectClass                     = $Object.ObjectClass
                        DistinguishedName               = $Object.DistinguishedName
                        ParentContainer                 = ConvertFrom-DistinguishedName -ToOrganizationalUnit -DistinguishedName $Object.DistinguishedName
                        WhenChanged                     = $Object.whenChanged
                        WhenCreated                     = $Object.whenCreated
                        WhenCreatedDays                 = if ($Object.Whencreated) { (($Today) - $Object.whenCreated).Days } else { $null }
                        WhenChangedDays                 = if ($Object.WhenChanged) { (($Today) - $Object.whenChanged).Days } else { $null }
                    }

                    if ($ReturnBrokenOnly -and $LimitProcessing -and $CountGlobalBroken -ge $LimitProcessing) {
                        return
                    }
                }
            }
        }
        return
    }

    # Original domain-wide scanning logic
    $CountDomain = 0
    :fullBreak foreach ($Domain in $ForestInformation.Domains) {
        $CountDomain++
        Write-Verbose "Get-WinADBrokenProtectedFromDeletion - Processing $Domain [$CountDomain of $($ForestInformation.Domains.Count)]"

        $Server = $ForestInformation.QueryServers[$Domain].HostName[0]
        [Array] $Objects = @(
            if ($Type -contains 'All') {
                Get-ADObject -Filter { ObjectClass -eq 'user' -or ObjectClass -eq 'computer' -or ObjectClass -eq 'group' -or ObjectClass -eq 'contact' -or ObjectClass -eq 'msDS-GroupManagedServiceAccount' -or ObjectClass -eq 'msDS-ManagedServiceAccount' } -Properties $Properties -Server $Server
            } else {
                if ($Type -contains 'User') {
                    Get-ADObject -Filter { ObjectClass -eq 'user' } -Properties $Properties -Server $Server
                }
                if ($Type -contains 'Group') {
                    Get-ADObject -Filter { ObjectClass -eq 'group' } -Properties $Properties -Server $Server
                }
                if ($Type -contains 'Computer') {
                    Get-ADObject -Filter { ObjectClass -eq 'computer' } -Properties $Properties -Server $Server
                }
                if ($Type -contains 'contact') {
                    Get-ADObject -Filter { ObjectClass -eq 'contact' } -Properties $Properties -Server $Server
                }
                if ($Type -contains 'GroupManagedServiceAccount') {
                    Get-ADObject -Filter { ObjectClass -eq 'msDS-GroupManagedServiceAccount' } -Properties $Properties -Server $Server
                }
                if ($Type -contains 'ManagedServiceAccount') {
                    Get-ADObject -Filter { ObjectClass -eq 'msDS-ManagedServiceAccount' } -Properties $Properties -Server $Server
                }
            }
        )
        if ($Objects.Count -gt 0) {
            Write-Verbose -Message "Get-WinADBrokenProtectedFromDeletion - Processing $($Objects.Count) objects in $Domain"
            $ProcessedCount = 0
            $LastReportedPercent = 0

            foreach ($Object in $Objects) {
                $ProcessedCount++
                $CurrentPercent = [math]::Floor(($ProcessedCount / $Objects.Count) * 100)

                # Report every 5%
                if ($CurrentPercent - $LastReportedPercent -ge 5) {
                    Write-Verbose "Get-WinADBrokenProtectedFromDeletion - Processed $ProcessedCount of $($Objects.Count) objects ($CurrentPercent%)"
                    $LastReportedPercent = $CurrentPercent
                }

                if ($Resolve) {
                    # If we want to resolve because of non-english AD
                    $ACL = Get-ADACL -ADObject $Object -AccessControlType Deny -Resolve -Principal 'S-1-1-0' -IncludeActiveDirectoryRightsExactMatch 'DeleteTree', 'Delete'
                } else {
                    $ACL = Get-ADACL -ADObject $Object -AccessControlType Deny -Principal 'Everyone' -IncludeActiveDirectoryRightsExactMatch 'DeleteTree', 'Delete'
                }
                if ($ACL) {
                    $ACLContainsDenyDeleteTree = $true
                } else {
                    $ACLContainsDenyDeleteTree = $false
                }
                if ($ACLContainsDenyDeleteTree -eq $true -and $Object.ProtectedFromAccidentalDeletion -eq $false) {
                    $HasBrokenPermissions = $true
                } else {
                    $HasBrokenPermissions = $false
                }
                if ($ReturnBrokenOnly -and $HasBrokenPermissions -eq $false) {
                    continue
                }
                if ($HasBrokenPermissions) {
                    $CountGlobalBroken++
                }

                [PSCustomObject] @{
                    Name                            = $Object.Name
                    SamAccountName                  = $Object.SamAccountName
                    Domain                          = $Domain
                    HasBrokenPermissions            = $HasBrokenPermissions
                    ProtectedFromAccidentalDeletion = $Object.ProtectedFromAccidentalDeletion
                    ACLContainsDenyDeleteTree       = $ACLContainsDenyDeleteTree
                    ObjectSID                       = $Object.objectSid
                    ObjectClass                     = $Object.ObjectClass
                    DistinguishedName               = $Object.DistinguishedName
                    ParentContainer                 = ConvertFrom-DistinguishedName -ToOrganizationalUnit -DistinguishedName $Object.DistinguishedName
                    WhenChanged                     = $Object.whenChanged
                    WhenCreated                     = $Object.whenCreated
                    WhenCreatedDays                 = if ($Object.Whencreated) { (($Today) - $Object.whenCreated).Days } else { $null }
                    WhenChangedDays                 = if ($Object.WhenChanged) { (($Today) - $Object.whenChanged).Days } else { $null }
                }
                if ($ReturnBrokenOnly -and $LimitProcessing -and $CountGlobalBroken -ge $LimitProcessing) {
                    break fullBreak
                }
            }
        }
    }
}