function Get-LAPSADUpdateTimeComputer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Microsoft.ActiveDirectory.Management.ADComputer] $ADComputer
    )
    $encBlob = $blob = $null
    if ($ADComputer.'msLAPS-EncryptedPassword') {
        $encBlob = $ADComputer.'msLAPS-EncryptedPassword'
    } elseif ($ADComputer.'msLAPS-EncryptedDSRMPassword') {
        $encBlob = $ADComputer.'msLAPS-EncryptedDSRMPassword'
    } elseif ($ADComputer.'msLAPS-Password') {
        $blob = $ADComputer.'msLAPS-Password'
    }

    if ($encBlob) {
        Write-Verbose -Message "Get-LAPSADUpdateTimeComputer - Getting timestamp from encrypted blob $([Convert]::ToBase64String($encBlob, 0, 8))"
        $timeStampUpper = [int64][BitConverter]::ToUInt32($encBlob, 0)
        $timeStampLower = [int64][BitConverter]::ToUInt32($encBlob, 4)
        $updateFileTime = ($timeStampUpper -shl 32) -bor $timeStampLower
    } elseif ($blob) {
        Write-Verbose -Message "Get-LAPSADUpdateTimeComputer - Getting timestamp from JSON blob '$blob'"
        $t = (ConvertFrom-Json -InputObject $blob).t
        $updateFileTime = [Convert]::ToInt64($t, 16)
    } else {
        $err = [System.Management.Automation.ErrorRecord]::new([Exception]::new("Failed to find LAPS attribute for $id"), 'NoLAPSAttribute', 'ObjectNotFound', $id)
        if ($ErrorActionPreference -eq 'Stop') {
            $PSCmdlet.WriteError($err)
        } else {
            Write-Warning -Message "Get-LAPSADUpdateTimeComputer- Failed to find LAPS attribute for $id. Exception: $($err.Exception.Message)"
        }
    }
    [DateTime]::FromFileTimeUtc($updateFileTime)
}
