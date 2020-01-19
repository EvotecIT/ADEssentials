Function Get-WinADForestObjectsConflict {
    [CmdletBinding()]
    Param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains
    )
    # Based on https://gallery.technet.microsoft.com/scriptcenter/Get-ADForestConflictObjects-4667fa37
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains

    #$Forest = Get-ADForest
    foreach ($Domain in $ForestInformation.Domains) {
        $DC = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        #Get conflict objects
        Get-ADObject -LDAPFilter "(|(cn=*\0ACNF:*)(ou=*CNF:*))" -Properties WhenChanged -Server $DC |
        ForEach-Object {
            $LiveObject = $null
            $ConflictObject = [PSCustomObject] @{
                Name                = $_
                ConflictDn          = $_.DistinguishedName
                ConflictWhenChanged = $_.WhenChanged
                LiveDn              = "N/A"
                LiveWhenChanged     = "N/A"
            }
            #See if we are dealing with a 'cn' conflict object
            if (Select-String -SimpleMatch "\0ACNF:" -InputObject $ConflictObject.ConflictDn) {
                #Split the conflict object DN so we can remove the conflict notation
                $SplitConfDN = $ConflictObject.ConflictDn -split "0ACNF:"
                #Remove the conflict notation from the DN and try to get the live AD object
                try {
                    $LiveObject = Get-ADObject -Identity "$($SplitConfDN[0].TrimEnd("\"))$($SplitConfDN[1].Substring(36))" -Properties WhenChanged -Server $DC -erroraction Stop
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
            $ConflictObject
        }
    }
}