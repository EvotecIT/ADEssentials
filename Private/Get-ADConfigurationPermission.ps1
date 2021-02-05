function Get-ADConfigurationPermission {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary]$ADObjectSplat,
        [string] $ObjectType,
        [switch] $FilterOut,
        [switch] $Owner
    )
    $Objects = Get-ADObject @ADObjectSplat
    foreach ($O in $Objects) {
        if ($FilterOut) {
            if ($ObjectType -eq 'site') {
                if ($O.DistinguishedName -like '*CN=Subnets,CN=Sites,CN=Configuration*') {
                    continue
                }
                if ($O.DistinguishedName -like '*CN=Inter-Site Transports,CN=Sites,CN=Configuration*') {
                    continue
                }
            }
        }
        if ($Owner) {
            $OwnerACL = Get-ADACLOwner -ADObject $O.DistinguishedName -Resolve
            [PSCustomObject] @{
                Name              = $O.Name
                CanonicalName     = $O.CanonicalName
                ObjectType        = $ObjectType
                ObjectClass       = $O.ObjectClass
                Owner             = $OwnerACL.Owner
                OwnerName         = $OwnerACL.OwnerName
                OwnerType         = $OwnerACL.OwnerType
                WhenCreated       = $O.WhenCreated
                WhenChanged       = $O.WhenChanged
                DistinguishedName = $O.DistinguishedName
            }
        } else {
            Get-ADACL -ADObject $O.DistinguishedName -ResolveTypes
        }
    }
}