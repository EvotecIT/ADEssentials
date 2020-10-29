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
            @(Get-Item -Path $Path -Force) + @(Get-ChildItem -Path $Path -Recurse:$true -Force -ErrorAction SilentlyContinue -ErrorVariable Err) | ForEach-Object -Process {
                if ($Owner) {
                    $Output = Get-FileOwner -JustPath -Path $_ -Resolve -AsHashTable
                    $Output['Attributes'] = $_.Attributes
                    [PSCustomObject] $Output
                } else {
                    $Output = Get-FilePermission -Path $_ -ResolveTypes -Extended -AsHashTable
                    foreach ($O in $Output) {
                        $O['Attributes'] = $_.Attributes
                        [PSCustomObject] $O
                    }
                }
            }
        }
    } else {
        if ($Path -and (Test-Path -Path $Path)) {
            @(Get-Item -Path $Path -Force) + @(Get-ChildItem -Path $Path -Recurse:$true -Force -ErrorAction SilentlyContinue -ErrorVariable Err) | ForEach-Object -Process {
                if ($Owner) {
                    $Output = Get-FileOwner -JustPath -Path $_ -Resolve -AsHashTable -Verbose
                    $Output['Attributes'] = $_.Attributes
                    [PSCustomObject] $Output
                } else {
                    $Output = Get-FilePermission -Path $_ -ResolveTypes -Extended -AsHashTable
                    foreach ($O in $Output) {
                        $O['Attributes'] = $_.Attributes
                        [PSCustomObject] $O
                    }
                }
            }
        }
    }
    foreach ($e in $err) {
        Write-Warning "Get-WinADSharePermission - $($e.Exception.Message) ($($e.CategoryInfo.Reason))"
    }
}