Function Set-WinADGPOMissingPermissions {
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
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [validateset('AuthenticatedUsers', 'DomainComputers', 'Either')][string] $Mode = 'Either'
    )
    if (-not $ExtendedForestInformation) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC
    } else {
        $ForestInformation = $ExtendedForestInformation
    }
    foreach ($Domain in $ForestInformation.Domains) {
        $DomainInformation = Get-ADDomain -Server $QueryServer
        $DomainComputersSID = $('{0}-515' -f $DomainInformation.DomainSID.Value)


        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $GPOs = Get-GPO -All -Domain $Domain -Server $QueryServer
        $MissingPermissions = @(
            foreach ($GPO in $GPOs) {
                $Permissions = Get-GPPermission -Guid $GPO.Id -All -Server $QueryServer -DomainName $Domain | Select-Object -ExpandProperty Trustee
                if ($Mode -eq 'Either') {
                    if ($Permissions.Sid.Value -notcontains 'S-1-5-11' -and $Permissions.Sid.Value -notcontains $DomainComputersSID) {
                        $GPO
                        #$GPO | Set-GPPermission -PermissionLevel GpoRead -TargetName 'Authenticated Users' -TargetType Group -Verbose
                    }
                } elseif ($Mode -eq 'AuthenticatedUsers') {
                    if ($Permissions.Sid.Value -notcontains 'S-1-5-11') {
                        $GPO
                        #$GPO | Set-GPPermission -PermissionLevel GpoRead -TargetName 'Authenticated Users' -TargetType Group -Verbose
                    }
                } elseif ($Mode -eq 'DomainComputers') {
                    if ($Permissions.Sid.Value -notcontains $DomainComputersSID) {
                        $GPO
                        #$GPO | Set-GPPermission -PermissionLevel GpoRead -TargetName 'Domain Computers' -TargetType Group -Verbose
                    }
                }

                #if ('S-1-5-11' -notin ($_ | Get-GPPermission -All).Trustee.Sid.Value) {
                #    $_ | Set-GPPermission -PermissionLevel GpoRead -TargetName 'Authenticated Users' -TargetType Group -Verbose
                #}
                #Write-Host 'Test'
            }
        )
        $MissingPermissions
    }
}