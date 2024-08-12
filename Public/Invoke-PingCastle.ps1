function Invoke-PingCastle {
    <#
    .SYNOPSIS
    Executes PingCastle to perform a health check on specified domains and saves the reports.

    .DESCRIPTION
    This cmdlet runs PingCastle to perform a health check on the specified domains and saves the generated reports to a specified location. It supports the option to include specific domains for the health check.

    .PARAMETER FolderPath
    Specifies the path to the folder containing the PingCastle executable.

    .PARAMETER ReportPath
    Specifies the path where the generated reports will be saved.

    .PARAMETER IncludeDomain
    Specifies an array of domain names to include in the health check. If not specified, all domains will be checked.

    .EXAMPLE
    Invoke-PingCastle -FolderPath "C:\PingCastle" -ReportPath "C:\Reports" -IncludeDomain "example.local", "subdomain.example.local"

    This example runs PingCastle to perform a health check on the "example.local" and "subdomain.example.local" domains and saves the reports to "C:\Reports".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FolderPath,
        [Parameter(Mandatory)][string] $ReportPath,
        [string[]] $IncludeDomain
    )
    $PingCastleExecutable = [io.path]::Combine($FolderPath, 'PingCastle.exe')
    if ($FolderPath -and (Test-Path -LiteralPath $FolderPath) -and (Test-Path -LiteralPath $PingCastleExecutable)) {

    } else {
        Write-Warning -Message "Invoke-PingCastle - FolderPath [$FolderPath] doesn't exist. Please provide path with PingCastle.exe"
        return
    }

    if ($ReportPath -and (Test-Path -LiteralPath $ReportPath)) {

    } else {
        Write-Warning -Message "Invoke-PingCastle - ReportPath [$ReportPath] doesn't exist. Please provide path with PingCastle report"
        return
    }

    $TemporaryReportFolder = [io.path]::Combine($Env:TEMP, 'PingCastle')
    if (-not (Test-Path -LiteralPath $TemporaryReportFolder)) {
        $null = New-Item -Path $TemporaryReportFolder -ItemType Directory -Force
    }
    if (Test-Path -LiteralPath $TemporaryReportFolder) {
        $Items = Get-ChildItem -LiteralPath $TemporaryReportFolder -Recurse
        foreach ($Item in $Items) {
            Remove-Item -LiteralPath $Item.FullName -Force
        }
    }

    try {
        Set-Location -LiteralPath $TemporaryReportFolder -ErrorAction Stop
    } catch {
        Write-Warning -Message "Invoke-PingCastle - Error while switch to $TemporaryReportFolder. Error: $($_.Exception.Message)"
        return
    }

    if ($IncludeDomain) {
        foreach ($Domain in $IncludeDomain) {
            & $PingCastleExecutable --healthcheck --server $Domain --reachable
        }
    } else {
        & $PingCastleExecutable --healthcheck --server * --reachable
    }
    $AllFiles = Get-ChildItem -LiteralPath $TemporaryReportFolder
    foreach ($File in $AllFiles) {
        $DomainName = $File.BaseName.Replace("ad_hc_", '')
        $Name = "PingCastle-Domain-$($DomainName)_$(Get-Date -f yyyy-MM-dd_HHmmss -Date $File.CreationTime)$($File.Extension)"
        $DestinationPath = [io.path]::Combine($ReportPath, $Name)
        try {
            Move-Item -LiteralPath $File.FullName -Destination $DestinationPath -Force -ErrorAction Stop
            [PSCustomObject] @{
                DomainName = $DomainName
                FilePath   = $DestinationPath
                Error      = $null
            }
        } catch {
            Write-Warning -Message "Invoke-PingCastle - Error while moving file $File to $DestinationPath. Error: $($_.Exception.Message)"
            [PSCustomObject] @{
                DomainName = $DomainName
                FilePath   = $DestinationPath
                Error      = $_.Exception.Message
            }
        }
    }

}

