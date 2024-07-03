function Set-WinADShare {
    <#
    .SYNOPSIS
    Sets the owner or displays permissions for a specified Windows Active Directory share.

    .DESCRIPTION
    This cmdlet sets the owner or displays permissions for a specified Windows Active Directory share. It can target a specific share type across multiple domains or a single path. It also supports setting the owner to a specific principal or to the default owner.

    .PARAMETER Path
    The path to the share to set the owner or display permissions for. This parameter is required if the ShareType parameter is not specified.

    .PARAMETER ShareType
    The type of share to target. This parameter is required if the Path parameter is not specified. Valid values are 'NetLogon'.

    .PARAMETER Owner
    Switch parameter to indicate that the owner of the share should be set. If this parameter is not specified, the cmdlet will display the permissions of the share instead.

    .PARAMETER Principal
    The principal to set as the owner of the share. This parameter is required if the Owner parameter is specified and the ParameterSetName is 'Principal'.

    .PARAMETER Type
    The type of share to set the owner for. This parameter is required if the Owner parameter is specified and the ParameterSetName is 'Type'. Valid values are 'Default'.

    .EXAMPLE
    Set-WinADShare -Path "\\example.com\NetLogon" -Owner -Principal "Domain Admins"
    This example sets the owner of the NetLogon share on the example.com domain to "Domain Admins".

    .EXAMPLE
    Set-WinADShare -ShareType NetLogon -Owner -Type Default
    This example sets the owner of all NetLogon shares across all domains to the default owner.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and configured.
    #>
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Type')]
    param(
        [string] $Path,
        [validateset('NetLogon')][string[]] $ShareType,
        [switch] $Owner,
        [Parameter(ParameterSetName = 'Principal', Mandatory)][string] $Principal,
        [Parameter(ParameterSetName = 'Type', Mandatory)]
        [validateset('Default')][string[]] $Type
    )
    if ($ShareType) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
        foreach ($Domain in $ForestInformation.Domains) {
            $Path = -join ("\\", $Domain, "\$ShareType")
            @(Get-Item -Path $Path) + @(Get-ChildItem -Path $Path -Recurse:$true) | ForEach-Object -Process {
                if ($Owner) {
                    Get-FileOwner -JustPath -Path $_ -Resolve
                } else {
                    Get-FilePermission -Path $_ -ResolveTypes -Extended
                }
            }
        }
    } else {
        if ($Path -and (Test-Path -Path $Path)) {
            @(Get-Item -Path $Path) + @(Get-ChildItem -Path $Path -Recurse:$true) | ForEach-Object -Process {
                if ($Owner) {
                    $IdentityOwner = Get-FileOwner -JustPath -Path $_.FullName -Resolve
                    if ($PSCmdlet.ParameterSetName -eq 'Principal') {

                    } else {
                        if ($IdentityOwner.OwnerSid -ne 'S-1-5-32-544') {
                            Set-FileOwner -Path $Path -JustPath -Owner 'S-1-5-32-544'
                        } else {
                            Write-Verbose "Set-WinADShare - Owner of $($_.FullName) already set to $($IdentityOwner.OwnerName). Skipping."
                        }
                    }
                } else {
                    Get-FilePermission -Path $_ -ResolveTypes -Extended
                }
            }
        }
    }

}