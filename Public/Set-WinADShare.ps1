function Set-WinADShare {
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