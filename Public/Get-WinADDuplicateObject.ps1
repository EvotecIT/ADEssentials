Function Get-WinADDuplicateObject {
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
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $DC = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        #Get conflict objects
        $getADObjectSplat = @{
            LDAPFilter  = "(|(cn=*\0ACNF:*)(ou=*CNF:*))"
            Properties  = 'DistinguishedName', 'ObjectClass', 'DisplayName', 'SamAccountName', 'Name', 'ObjectCategory', 'WhenCreated', 'WhenChanged', 'ProtectedFromAccidentalDeletion', 'ObjectGUID'
            Server      = $DC
            SearchScope = 'Subtree'
        }
        $Objects = Get-ADObject @getADObjectSplat
        foreach ($_ in $Objects) {
            # Lets allow users to filter on it
            if ($ExcludeObjectClass) {
                if ($ExcludeObjectClass -contains $_.ObjectClass) {
                    continue
                }
            }
            if ($IncludeObjectClass) {
                if ($IncludeObjectClass -notcontains $_.ObjectClass) {
                    continue
                }
            }
            if ($PartialMatchDistinguishedName) {
                if ($_.DistinguishedName -notlike $PartialMatchDistinguishedName) {
                    continue
                }
            }
            if ($NoPostProcessing) {
                $_
                continue
            }
            $DomainName = ConvertFrom-DistinguishedName -DistinguishedName $_.DistinguishedName -ToDomainCN
            # Lets create separate objects for different purpoeses
            $ConflictObject = [ordered] @{
                ConflictDN          = $_.DistinguishedName
                ConflictWhenChanged = $_.WhenChanged
                DomainName          = $DomainName
                ObjectClass         = $_.ObjectClass
            }
            $LiveObjectData = [ordered] @{
                LiveDn          = "N/A"
                LiveWhenChanged = "N/A"
            }
            $RestData = [ordered] @{
                DisplayName                     = $_.DisplayName
                Name                            = $_.Name.Replace("`n", ' ')
                SamAccountName                  = $_.SamAccountName
                ObjectCategory                  = $_.ObjectCategory
                WhenCreated                     = $_.WhenCreated
                WhenChanged                     = $_.WhenChanged
                ProtectedFromAccidentalDeletion = $_.ProtectedFromAccidentalDeletion
                ObjectGUID                      = $_.ObjectGUID.Guid
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