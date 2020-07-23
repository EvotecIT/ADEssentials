function Get-WinADSharePermission {
    [cmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory)][string] $Path,
        [Parameter(ParameterSetName = 'ShareType', Mandatory)][validateset('NetLogon', 'SYSVOL')][string[]] $ShareType,
        [switch] $Owner,
        [string[]] $Name,
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    if ($ShareType) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
        foreach ($Domain in $ForestInformation.Domains) {
            $Path = -join ("\\", $Domain, "\$ShareType")
            @(Get-Item -Path $Path) + @(Get-ChildItem -Path $Path -Recurse:$true -Force) | ForEach-Object -Process {
                if ($Owner) {
                    Get-FileOwner -JustPath -Path $_ -Resolve
                } else {
                    Get-FilePermission -Path $_ -ResolveTypes -Extended
                }
            }
        }
    } else {
        if ($Path -and (Test-Path -Path $Path)) {
            @(Get-Item -Path $Path) + @(Get-ChildItem -Path $Path -Recurse:$true -Force) | ForEach-Object -Process {
                if ($Owner) {
                    Get-FileOwner -JustPath -Path $_ -Resolve
                } else {
                    Get-FilePermission -Path $_ -ResolveTypes -Extended
                }
            }
        }
    }
}