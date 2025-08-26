function Add-DHCPTimingStatistic {
    <#
    .SYNOPSIS
    Adds timing statistics for DHCP data collection operations.

    .DESCRIPTION
    Internal function to track and record timing statistics for various DHCP data collection operations.

    .PARAMETER TimingList
    The list to add timing statistics to.

    .PARAMETER ServerName
    The name of the DHCP server being processed.

    .PARAMETER Operation
    The operation being timed (e.g., 'Server Discovery', 'Scope Collection', etc.).

    .PARAMETER StartTime
    The start time of the operation.

    .PARAMETER EndTime
    The end time of the operation. If not provided, current time is used.

    .PARAMETER ItemCount
    Optional count of items processed during this operation.

    .PARAMETER Success
    Whether the operation completed successfully.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.Collections.Generic.List[Object]] $TimingList,

        [Parameter(Mandatory = $true)]
        [string] $ServerName,

        [Parameter(Mandatory = $true)]
        [string] $Operation,

        [Parameter(Mandatory = $true)]
        [datetime] $StartTime,

        [Parameter(Mandatory = $false)]
        [datetime] $EndTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [int] $ItemCount = 0,

        [Parameter(Mandatory = $false)]
        [bool] $Success = $true
    )

    try {
        # Ensure we have a valid TimingList to add to
        if ($null -eq $TimingList) {
            Write-Warning "Add-DHCPTimingStatistic - TimingList is null for $ServerName / $Operation"
            return
        }

        $Duration = $EndTime - $StartTime

        $TimingObject = [PSCustomObject]@{
            ServerName      = $ServerName
            Operation       = $Operation
            StartTime       = $StartTime
            EndTime         = $EndTime
            DurationMs      = [Math]::Round($Duration.TotalMilliseconds, 2)
            DurationSeconds = [Math]::Round($Duration.TotalSeconds, 2)
            ItemCount       = $ItemCount
            ItemsPerSecond  = if ($Duration.TotalSeconds -gt 0 -and $ItemCount -gt 0) {
                [Math]::Round($ItemCount / $Duration.TotalSeconds, 2)
            } else {
                0
            }
            Success         = $Success
            Timestamp       = Get-Date
        }

        $TimingList.Add($TimingObject)
        Write-Verbose "Add-DHCPTimingStatistic - Added timing for $ServerName / $Operation : $($Duration.TotalSeconds)s"
    } catch {
        Write-Warning "Add-DHCPTimingStatistic - Failed to add timing statistic for $ServerName / $Operation : $($_.Exception.Message)"
    }
}