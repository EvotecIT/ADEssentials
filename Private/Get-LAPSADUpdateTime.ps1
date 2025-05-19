function Get-LAPSADUpdateTime {
    <#
    .SYNOPSIS
    Gets the Windows LAPS Update Time.

    .DESCRIPTION
    Gets the Windows LAPS Update Time for the specified computer account. The output value is a DateTime object representing the update time as a UTC date time.

    .PARAMETER Identity
    The computer account identity to get the LAPS update time for.

    .EXAMPLE
    Get-LapsADUpdateTime -Identity foo

    .NOTES
    To convert the DateTime to the local time you can use the ToLocalTime() method on the output object.
        $updateTime = Get-LapsADUpdateTime -Identity foo
        $updateTime.ToLocalTime()

    Copyright: (c) 2025, Jordan Borean (@jborean93) <jborean93@gmail.com>
    MIT License (see LICENSE or https://opensource.org/licenses/MIT)
    #>
    [OutputType([DateTime])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Identity')][string[]] $Identity,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Computer')][Microsoft.ActiveDirectory.Management.ADComputer] $ADComputer
    )

    process {
        foreach ($id in $Identity) {
            Write-Verbose "Get-LapsADUpdateTime - Attempting to get ADComputer for '$id'"
            if ($ADComputer) {
                Write-Verbose "Get-LapsADUpdateTime - Using provided ADComputer object."
                Get-LAPSADUpdateTimeComputer -ADComputer $ADComputer
            } else {
                try {
                    $compInfo = Get-ADComputer $id -Properties msLAPS-EncryptedPassword, msLAPS-Password, 'msLAPS-EncryptedDSRMPassword'
                    Get-LAPSADUpdateTimeComputer -ADComputer $compInfo
                } catch {
                    $PSCmdlet.WriteError($_)
                }
            }
        }
    }
}