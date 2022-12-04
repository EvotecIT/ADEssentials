function Get-PrivateACL {
    <#
    .SYNOPSIS
    Get ACL from AD Object

    .DESCRIPTION
    Get ACL from AD Object

    .PARAMETER ADObject
    AD Object to get ACL from

    .PARAMETER FullObject
    Returns full object instead of just ACL

    .EXAMPLE
    Get-PrivateACL -ADObject 'DC=ad,DC=evotec,DC=xyz'

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('DistinguishedName')][string] $ADObject,
        [switch] $FullObject
    )
    try {
        $ADObjectData = Get-ADObject -Identity $ADObject -Properties ntSecurityDescriptor, CanonicalName -ErrorAction Stop
    } catch {
        Write-Warning -Message "Get-PrivateACL - Unable to get ADObject data for $ADObject. Error: $($_.Exception.Message)"
        return
    }
    if ($FullObject) {
        $ADObjectData
    } else {
        $ADObjectData.ntSecurityDescriptor
    }
}