function Get-WinADBrokenProtectedFromDeletion {
    <#
    .SYNOPSIS
    Identifies Active Directory objects with inconsistent protection from accidental deletion settings.

    .DESCRIPTION
    This cmdlet scans Active Directory for objects where the ProtectedFromAccidentalDeletion flag doesn't match
    the actual ACL settings. It helps identify objects that might be at risk of accidental deletion despite
    appearing to be protected, or vice versa.

    .PARAMETER Forest
    The name of the forest to scan. If not specified, the current forest is used.

    .PARAMETER ExcludeDomains
    Array of domain names to exclude from scanning.

    .PARAMETER IncludeDomains
    Array of domain names to include in scanning. If not specified, all domains are scanned.

    .PARAMETER ExtendedForestInformation
    Dictionary containing cached forest information to improve performance.

    .PARAMETER Type
    Required. Specifies the types of objects to scan. Valid values are:
    - Computer
    - Group
    - User
    - ManagedServiceAccount
    - GroupManagedServiceAccount
    - Contact
    - All

    .PARAMETER Resolve
    Switch to enable name resolution for Everyone permission.
    This is only nessecary if you have non-english AD, as Everyone is not Everyone in all languages.

    .PARAMETER ReturnBrokenOnly
    Switch to return only objects with inconsistent protection settings.

    .PARAMETER LimitProcessing
    Limits the number of objects to process.

    .EXAMPLE
    Get-WinADBrokenProtectedFromDeletion -Type All
    Scans all supported object types in the current forest for broken protection settings.

    .EXAMPLE
    Get-WinADBrokenProtectedFromDeletion -Type User,Computer -Forest "contoso.com" -ReturnBrokenOnly
    Scans user and computer objects in the specified forest and returns only those with broken protection settings.

    .NOTES
    This cmdlet performs ACL checks against the Everyone group (S-1-1-0) to determine if delete permissions
    are properly denied.
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [ValidateSet(
            'Computer',
            'Group',
            'User',
            'ManagedServiceAccount',
            'GroupManagedServiceAccount',
            'Contact',
            'All'
        )][Parameter(Mandatory)][string[]] $Type,
        [switch] $Resolve,
        [switch] $ReturnBrokenOnly,
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