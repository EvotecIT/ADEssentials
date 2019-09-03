Function Get-WinADGPOMissingPermissions {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Domain
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    Based on https://secureinfra.blog/2018/12/31/most-common-mistakes-in-active-directory-and-domain-services-part-1/
    #>

    [cmdletBinding()]
    param(
        [string] $Domain = $Env:USERDNSDOMAIN
    )
    $GPOs = Get-GPO -All -Domain $Domain
    $MissingPermissions = @(
        foreach ($GPO in $GPOs) {
            If ($GPO.User.Enabled) {
                $GPOPermissionForAuthUsers = Get-GPPermission -Guid $GPO.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.Name -eq "Authenticated Users" }
                $GPOPermissionForDomainComputers = Get-GPPermission -Guid $GPO.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.Name -eq "Domain Computers" }
                If (-not $GPOPermissionForAuthUsers -and -not $GPOPermissionForDomainComputers) {
                    $GPO
                }
            }
        }
    )
    $MissingPermissions
}
