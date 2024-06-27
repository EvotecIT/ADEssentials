Function Get-WinADDuplicateObject {
    <#
    .SYNOPSIS
    Get duplicate objects in Active Directory (CNF: and CNF:0ACNF:)

    .DESCRIPTION
    Get duplicate objects in Active Directory (CNF: and CNF:0ACNF:)
    CNF stands for "Conflict". CNF objects are created when there is a naming conflict in the Active Directory.
    This usually happens during the replication process when two objects are created with the same name in different parts of the replication topology,
    and then a replication attempt is made. Active Directory resolves this by renaming one of the objects with a CNF prefix and a GUID.
    The object with the CNF name is usually the loser in the conflict resolution process.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .PARAMETER PartialMatchDistinguishedName
    Limit results to specific DistinguishedName

    .PARAMETER IncludeObjectClass
    Limit results to specific ObjectClass

    .PARAMETER ExcludeObjectClass
    Exclude specific ObjectClass

    .PARAMETER Extended
    Provide extended information about the object

    .PARAMETER NoPostProcessing
    Do not post process the object, return as is from the AD

    .EXAMPLE
    Get-WinADDuplicateObject -Verbose | Format-Table

    .NOTES
    General notes
    #>
    [alias('Get-WinADForestObjectsConflict')]
    [CmdletBinding()]
    Param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [string] $PartialMatchDistinguishedName,
        [string[]] $IncludeObjectClass,
        [string[]] $ExcludeObjectClass,
        [switch] $Extended,
        [switch] $NoPostProcessing
    )
    # Based on https://gallery.technet.microsoft.com/scriptcenter/Get-ADForestConflictObjects-4667fa37
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -Extended
    foreach ($Domain in $ForestInformation.Domains) {
        $DomainInformation = $ForestInformation.DomainsExtended[$Domain]
        Write-Verbose -Message "Get-WinADDuplicateObject - Processing $($Domain)"
        $Partitions = @(
            if ($Domain -eq $ForestInformation.Forest) {
                "CN=Configuration,$($ForestInformation['DomainsExtended'][$Domain].DistinguishedName)"
                if ($DomainInformation.SubordinateReferences -contains "DC=ForestDnsZones,$($ForestInformation['DomainsExtended'][$Domain].DistinguishedName)") {
                    "DC=ForestDnsZones,$($ForestInformation['DomainsExtended'][$Domain].DistinguishedName)"
                } else {
                    Write-Warning -Message "Get-WinADDuplicateObject - ForestDnsZones not found for domain '$Domain'. Skipping"
                }
            }
            # Domain Name
            $ForestInformation['DomainsExtended'][$Domain].DistinguishedName
            # DNS Name
            if ($DomainInformation.SubordinateReferences -contains "DC=DomainDnsZones,$($ForestInformation['DomainsExtended'][$Domain].DistinguishedName)") {
                "DC=DomainDnsZones,$($ForestInformation['DomainsExtended'][$Domain].DistinguishedName)"
            } else {
                Write-Warning -Message "Get-WinADDuplicateObject - DomainDnsZones not found for domain '$Domain'. Skipping"
            }
        )
        $DC = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        #Get conflict objects
        foreach ($Partition in $Partitions) {
            Write-Verbose -Message "Get-WinADDuplicateObject - Processing $($Domain) - $($Partition)"
            $getADObjectSplat = @{
                #Filter      = "*"
                LDAPFilter  = "(|(cn=*\0ACNF:*)(ou=*CNF:*))"
                Properties  = 'DistinguishedName', 'ObjectClass', 'DisplayName', 'SamAccountName', 'Name', 'ObjectCategory', 'WhenCreated', 'WhenChanged', 'ProtectedFromAccidentalDeletion', 'ObjectGUID'
                Server      = $DC
                SearchScope = 'Subtree'
            }
            try {
                $Objects = Get-ADObject @getADObjectSplat -SearchBase $Partition -ErrorAction Stop
            } catch {
                Write-Warning -Message "Get-WinADDuplicateObject - Getting objects from domain '$Domain' / partition: '$Partition' failed. Error: $($Object.Exception.Message)"
                continue
            }
            foreach ($Object in $Objects) {
                # Lets allow users to filter on it
                if ($ExcludeObjectClass) {
                    if ($ExcludeObjectClass -contains $Object.ObjectClass) {
                        continue
                    }
                }
                if ($IncludeObjectClass) {
                    if ($IncludeObjectClass -notcontains $Object.ObjectClass) {
                        continue
                    }
                }
                if ($PartialMatchDistinguishedName) {
                    if ($Object.DistinguishedName -notlike $PartialMatchDistinguishedName) {
                        continue
                    }
                }
                if ($NoPostProcessing) {
                    $Object
                    continue
                }
                $DomainName = ConvertFrom-DistinguishedName -DistinguishedName $Object.DistinguishedName -ToDomainCN
                # Lets create separate objects for different purpoeses
                $ConflictObject = [ordered] @{
                    ConflictDN          = $Object.DistinguishedName
                    ConflictWhenChanged = $Object.WhenChanged
                    DomainName          = $DomainName
                    ObjectClass         = $Object.ObjectClass
                }
                $LiveObjectData = [ordered] @{
                    LiveDn          = "N/A"
                    LiveWhenChanged = "N/A"
                }
                $RestData = [ordered] @{
                    DisplayName                     = $Object.DisplayName
                    Name                            = $Object.Name.Replace("`n", ' ')
                    SamAccountName                  = $Object.SamAccountName
                    ObjectCategory                  = $Object.ObjectCategory
                    WhenCreated                     = $Object.WhenCreated
                    WhenChanged                     = $Object.WhenChanged
                    ProtectedFromAccidentalDeletion = $Object.ProtectedFromAccidentalDeletion
                    ObjectGUID                      = $Object.ObjectGUID.Guid
                    # Server used to query the object
                    Server                          = $DC
                    # Partition used to query the object
                    SearchBase                      = $Partition
                }
                if ($Extended) {
                    $LiveObject = $null
                    $ConflictObject = $ConflictObject + $LiveObjectData + $RestData
                    #See if we are dealing with a 'cn' conflict object
                    if (Select-String -SimpleMatch "\0ACNF:" -InputObject $ConflictObject.ConflictDn) {
                        #Split the conflict object DN so we can remove the conflict notation
                        $SplitConfDN = $ConflictObject.ConflictDn -split "0ACNF:"
                        #Remove the conflict notation from the DN and try to get the live AD object
                        try {
                            $LiveObject = Get-ADObject -Identity "$($SplitConfDN[0].TrimEnd("\"))$($SplitConfDN[1].Substring(36))" -Properties WhenChanged -Server $DC -ErrorAction Stop
                        } catch { }
                        if ($LiveObject) {
                            $ConflictObject.LiveDN = $LiveObject.DistinguishedName
                            $ConflictObject.LiveWhenChanged = $LiveObject.WhenChanged
                        }
                    } else {
                        #Split the conflict object DN so we can remove the conflict notation for OUs
                        $SplitConfDN = $ConflictObject.ConflictDn -split "CNF:"
                        #Remove the conflict notation from the DN and try to get the live AD object
                        try {
                            $LiveObject = Get-ADObject -Identity "$($SplitConfDN[0])$($SplitConfDN[1].Substring(36))" -Properties WhenChanged -Server $DC -ErrorAction Stop
                        } catch { }
                        if ($LiveObject) {
                            $ConflictObject.LiveDN = $LiveObject.DistinguishedName
                            $ConflictObject.LiveWhenChanged = $LiveObject.WhenChanged
                        }
                    }
                } else {
                    $ConflictObject = $ConflictObject + $RestData
                }
                [PSCustomObject] $ConflictObject
            }
        }
    }
}