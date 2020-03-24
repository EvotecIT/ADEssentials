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
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [validateset('AuthenticatedUsers', 'DomainComputers', 'Either')][string] $Mode = 'Either',
        [switch] $Extended
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        if ($Extended) {
            $GPOs = Get-GPO -All -Domain $Domain -Server $QueryServer | ForEach-Object {
                [xml] $XMLContent = Get-GPOReport -ID $_.ID.Guid -ReportType XML -Server $ForestInformation.QueryServers[$Domain].HostName[0] -Domain $Domain
                Add-Member -InputObject $_ -MemberType NoteProperty -Name 'LinksTo' -Value $XMLContent.GPO.LinksTo
                if ($XMLContent.GPO.LinksTo) {
                    Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Linked' -Value $true
                } else {
                    Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Linked' -Value $false
                }
                $_ | Select-Object -Property Id, DisplayName, DomainName, Owner, Linked, GpoStatus, CreationTime, ModificationTime,
                @{
                    label      = 'UserVersion'
                    expression = { "AD Version: $($_.User.DSVersion), SysVol Version: $($_.User.SysvolVersion)" }
                },
                @{
                    label      = 'ComputerVersion'
                    expression = { "AD Version: $($_.Computer.DSVersion), SysVol Version: $($_.Computer.SysvolVersion)" }
                }, WmiFilter, Description, User, Computer, LinksTo
            }
        } else {
            $GPOs = Get-GPO -All -Domain $Domain -Server $QueryServer
        }

        $DomainInformation = Get-ADDomain -Server $QueryServer
        $DomainComputersSID = $('{0}-515' -f $DomainInformation.DomainSID.Value)

        $MissingPermissions = @(
            foreach ($GPO in $GPOs) {
                $Permissions = Get-GPPermission -Guid $GPO.Id -All -Server $QueryServer -DomainName $Domain | Select-Object -ExpandProperty Trustee
                if ($Mode -eq 'Either' -or $Mode -eq 'AuthenticatedUsers') {
                    $GPOPermissionForAuthUsers = $Permissions | Where-Object { $_.Sid.Value -eq 'S-1-5-11' }
                }
                if ($Mode -eq 'Either' -or $Mode -eq 'DomainComputers') {
                    $GPOPermissionForDomainComputers = $Permissions | Where-Object { $_.Sid.Value -eq $DomainComputersSID }
                }
                if ($Mode -eq 'Either') {
                    If (-not $GPOPermissionForAuthUsers -and -not $GPOPermissionForDomainComputers) {
                        $GPO
                    }
                } elseif ($Mode -eq 'AuthenticatedUsers') {
                    If (-not $GPOPermissionForAuthUsers) {
                        $GPO
                    }
                } elseif ($Mode -eq 'DomainComputers') {
                    If (-not $GPOPermissionForDomainComputers) {
                        $GPO
                    }
                }
            }
        )
        $MissingPermissions
    }
}