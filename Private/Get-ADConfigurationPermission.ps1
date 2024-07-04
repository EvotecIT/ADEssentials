function Get-ADConfigurationPermission {
    <#
    .SYNOPSIS
    Retrieves AD configuration permissions based on specified criteria.

    .DESCRIPTION
    This function retrieves AD configuration permissions based on the provided AD object splat, object type, and optional filters.

    .PARAMETER ADObjectSplat
    The AD object splat containing LDAP filter and search base information.

    .PARAMETER ObjectType
    Specifies the type of object to retrieve permissions for.

    .PARAMETER FilterOut
    If specified, filters out specific object types.

    .PARAMETER Owner
    If specified, retrieves the owner information for each object.

    .EXAMPLE
    Get-ADConfigurationPermission -ADObjectSplat $ADObjectSplat -ObjectType "site" -FilterOut -Owner
    Retrieves AD configuration permissions for site objects, filters out specific object types, and retrieves owner information.

    .NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary]$ADObjectSplat,
        [string] $ObjectType,
        [switch] $FilterOut,
        [switch] $Owner
    )
    try {
        $Objects = Get-ADObject @ADObjectSplat -ErrorAction Stop
    } catch {
        Write-Warning "Get-ADConfigurationPermission - LDAP Filter: $($ADObjectSplat.LDAPFilter), SearchBase: $($ADObjectSplat.SearchBase)), Error: $($_.Exception.Message)"
    }
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
            Write-Verbose "Get-ADConfigurationPermission - Getting Owner from $($O.DistinguishedName)"
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