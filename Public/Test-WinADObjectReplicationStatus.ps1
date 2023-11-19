function Test-WinADObjectReplicationStatus {
    [CmdletBinding(DefaultParameterSetName = 'Standard')]
    param(
        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'Analysis')]
        [string] $Identity,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'Analysis')]
        [alias('ForestName')][string] $Forest,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'Analysis')]
        [string[]] $ExcludeDomains,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'Analysis')]
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,

        # [Parameter(ParameterSetName = 'Standard')]
        # [Parameter(ParameterSetName = 'Analysis', Mandatory)]
        #[string] $SourceServer,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'Analysis')]
        [switch] $GlobalCatalog,

        [Parameter(ParameterSetName = 'Analysis')]
        [string] $SnapshotPath,

        [Parameter(ParameterSetName = 'Standard')]
        [switch] $Sorted,

        [switch] $ClearSnapshot
    )

    if ($SnapshotPath -and $ClearSnapshot) {
        if (Test-Path -LiteralPath $SnapshotPath) {
            Remove-Item -LiteralPath $SnapshotPath -Force -ErrorAction Stop
        }
    }

    $DistinguishedName = $Identity
    $DomainFromIdentity = ConvertFrom-DistinguishedName -DistinguishedName $Identity -ToDomainCN

    $ForestInformation = Get-WinADForestDetails -Extended
    if ($GlobalCatalog) {
        [Array] $GCs = foreach ($DC in $ForestInformation.ForestDomainControllers) {
            if ($DC.IsGlobalCatalog) {
                $DC
            }
        }
    } else {
        [Array] $GCs = foreach ($DC in $ForestInformation.ForestDomainControllers) {
            if ($DC.Domain -eq $DomainFromIdentity) {
                $DC
            }
        }
    }
    $ResultsCached = [ordered] @{}
    $Results = foreach ($GC in $GCs) {
        # Query the specific object on each GC
        Try {
            if ($GlobalCatalog) {
                $ObjectInfo = Get-ADObject -Identity $Identity -Server "$($GC.HostName):3268" -Properties * -ErrorAction Stop
            } else {
                $ObjectInfo = Get-ADObject -Identity $Identity -Server $GC.HostName -Properties * -ErrorAction Stop
            }
        } catch {
            $ObjectInfo = $null
            Write-Warning "Test-WinADObjectReplicationStatus - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
            $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
        }
        if ($ObjectInfo) {
            $PreparedObject = [PSCustomObject] @{
                DomainController   = $GC.HostName
                Domain             = $GC.Domain
                UserAccountControl = $ObjectInfo.userAccountCOntrol
                Created            = $ObjectInfo.Created
                uSNChanged         = $ObjectInfo.uSNChanged
                uSNCreated         = $ObjectInfo.uSNCreated
                whenCreated        = $ObjectInfo.whenCreated
                WhenChanged        = $ObjectInfo.WhenChanged
                Error              = $ErrorValue
            }
            $ResultsCached[$GC.HostName] = $PreparedObject
            $PreparedObject
        }
    }

    if ($SnapshotPath) {
        $Date = Get-Date
        $DateText = $Date.ToString('yyyy-MM-dd HH:mm:ss')
        if (Test-Path -LiteralPath $SnapshotPath) {
            $Output = Import-Clixml -Path $SnapshotPath
        } else {
            $Output = [ordered] @{
                $DistinguishedName = [ordered] @{}
            }
        }
        $Output[$DistinguishedName][$DateText] = [ordered] @{}
        foreach ($GC in $GCs) {
            $Output[$DistinguishedName][$DateText][$GC.Hostname] = [ordered] @{
                Date        = $Date
                USNChanged  = $ResultsCached[$GC.Hostname].USNChanged
                WhenChanged = $ResultsCached[$GC.Hostname].WhenChanged
            }
        }
        foreach ($Key in [string[]] $Output.Keys | Where-Object { $_.Name -ne 'Summary' }) {
            if (-not $Output['Summary']) {
                $Output['Summary'] = [ordered] @{}
            }
            if ($Output[$DistinguishedName].Count -gt 1) {
                $Output['Summary'][$Key] = [ordered] @{}

                foreach ($TextDate in [string[]] $Output[$DistinguishedName].Keys | Select-Object -First 1) {
                    $Output['Summary'][$Key][$TextDate] = [ordered] @{}
                    foreach ($GC in $GCs) {
                        $Output['Summary'][$Key][$GC.Hostname] = [ordered] @{
                            'Name'        = $GC.HostName
                            'Query'       = if ($GlobalCatalog) { 'Global Catalog' } else { 'Domain Based' }
                            'WhenChanged' = $Output[$DistinguishedName][$TextDate][$GC.Hostname].WhenChanged
                            'USNChanged'  = $Output[$DistinguishedName][$TextDate][$GC.Hostname].USNChanged
                        }
                    }
                }
                foreach ($TextDate in [string[]] $Output[$DistinguishedName].Keys | Select-Object -Skip 1) {
                    foreach ($GC in $GCs) {
                        if ($Output[$DistinguishedName][$TextDate][$GC.Hostname].USNChanged -ne $Output['Summary'][$Key][$GC.Hostname].UsnChanged) {
                            $Status = 'Changed'
                        } else {
                            $Status = 'Not changed'
                        }
                        $Output['Summary'][$Key][$GC.Hostname][$TextDate] = $Status
                    }
                }
            }
        }
        $Output | Export-Clixml -Path $SnapshotPath
        $Output
    } else {
        if ($Sorted) {
            $Results | Sort-Object -Property WhenChanged
        } else {
            $Results
        }
    }
}