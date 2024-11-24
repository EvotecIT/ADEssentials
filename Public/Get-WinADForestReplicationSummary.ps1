function Get-WinADForestReplicationSummary {
    <#
    .SYNOPSIS
    Function that retrieves the replication summary of the Active Directory forest.

    .DESCRIPTION
    This function retrieves the replication summary of the Active Directory forest.
    It uses the repadmin command to retrieve the replication summary and then parses
    the output to create a custom object with the following properties:
    - Server: The server name.
    - LargestDelta: The largest delta between replication cycles.
    - Fails: The number of failed replication cycles.
    - Total: The total number of replication cycles.
    - PercentageError: The percentage of failed replication cycles.
    - Type: The type of server (Source or Destination).
    - ReplicationError: The replication error message.

    .PARAMETER InputContent
    Allow the user to pass the repadmin output as a string.

    .PARAMETER FilePath
    Allow the user to pass the path of a file containing the repadmin output.

    .PARAMETER IncludeStatisticsVariable
    Allow the user to pass the name of a variable to store the statistics.

    .EXAMPLE
    Get-WinADForestReplicationSummary | Format-Table

    .EXAMPLE
    Get-WinADForestReplicationSummary -FilePath C:\repadmin.txt | Format-Table

    .EXAMPLE
    Get-WinADForestReplicationSummary -InputContent $repadminOutput | Format-Table

    .EXAMPLE
    Get-WinADForestReplicationSummary -IncludeStatisticsVariable Statistics | Format-Table

    $Statistics | Format-Table

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'InputContent')][string] $InputContent,
        [Parameter(ParameterSetName = 'FilePath')][string] $FilePath,
        [string] $IncludeStatisticsVariable
    )

    if ($InputContent) {
        $OutputRepadmin = $InputContent

    } elseif ($FilePath) {
        $OutputRepadmin = Get-Content -Path $FilePath -Raw
    } else {
        # Run repadmin and capture the output
        $OutputRepadmin = repadmin /replsummary /bysrc /bydest | Out-String
    }
    # Split the output into sections
    $sections = $OutputRepadmin -split "Source DSA|Destination DSA"

    $lines = $sections[1] -split "`r`n"
    [Array] $sourceData = foreach ($line in $lines) {
        if ($line -match '^Experienced the following operational errors trying to retrieve replication information') {
            break
        }
        if ($line -match '\S' -and $line -notmatch '^\s*largest') {
            if ($line -match "^\s*(?<DSA>\S+)\s+(?<Rest>.*)$") {
                #Write-Verbose -Message "Processing line: $line"
                $DSA = $Matches.DSA
                # $rest = $Matches.Rest -split "\s+", 4 # split into 4 parts: LargestDelta, Fails, Total, Percentage and the rest
                $Rest = $Matches.Rest
                if ($rest -match ">60 days") {
                    $RestSplitted = $Rest -split "\s+", 7
                    $LargestDelta = New-TimeSpan -Days 60
                    $Fails = $RestSplitted[2]
                    $Total = $RestSplitted[4]
                    $Percentage = $RestSplitted[5]
                    $ReplicationError = $RestSplitted[6]
                    $Type = "Source"
                } else {
                    $RestSplitted = $Rest -split "\s+", 4 # split into 4 parts: LargestDelta, Fails, Total, Percentage and the rest
                    $LargestDelta = ConvertTo-TimeSpanFromRepadmin -timeString $RestSplitted[0]
                    $Fails = $RestSplitted[1]
                    $Continue = $RestSplitted[3]
                    $Continue = $Continue -split "\s{2,}"
                    $Total = $Continue[0]
                    $Percentage = $Continue[1]

                    $ReplicationError = $Continue[2]
                    if ($null -eq $ReplicationError) {
                        $ReplicationError = "None"
                    }
                    $Type = "Source"
                }


                [PSCustomObject]@{
                    Server           = $DSA
                    LargestDelta     = $LargestDelta
                    Fails            = if ($null -ne $Fails) { [int] $Fails.Replace("/", "").Trim() } else { $null }
                    Total            = [int] $Total
                    PercentageError  = $Percentage
                    Type             = $Type
                    ReplicationError = $ReplicationError
                }
            }
        }
    }

    $lines = $sections[2] -split "`r`n"
    [Array] $destinationData = foreach ($line in $lines) {
        if ($line -match '^Experienced the following operational errors trying to retrieve replication information') {
            break
        }
        if ($line -match '\S' -and $line -notmatch '^\s*largest') {
            if ($line -match "^\s*(?<DSA>\S+)\s+(?<Rest>.*)$") {
                # Write-Verbose -Message "Processing line: $line"
                $DSA = $Matches.DSA
                $Rest = $Matches.Rest
                if ($rest -match ">60 days") {
                    $RestSplitted = $Rest -split "\s+", 7
                    $LargestDelta = New-TimeSpan -Days 60
                    $Fails = $RestSplitted[2]
                    $Total = $RestSplitted[4]
                    $Percentage = $RestSplitted[5]
                    $ReplicationError = $RestSplitted[6]
                    $Type = "Destination"
                } else {
                    $RestSplitted = $Rest -split "\s+", 4 # split into 4 parts: LargestDelta, Fails, Total, Percentage and the rest
                    $LargestDelta = ConvertTo-TimeSpanFromRepadmin -timeString $RestSplitted[0]
                    $Fails = $RestSplitted[1]
                    $Continue = $RestSplitted[3]
                    $Continue = $Continue -split "\s{2,}"
                    $Total = $Continue[0]
                    $Percentage = $Continue[1]

                    $ReplicationError = $Continue[2]
                    if ($null -eq $ReplicationError) {
                        $ReplicationError = "None"
                    }
                    $Type = "Destination"
                }

                [PSCustomObject]@{
                    Server           = $DSA
                    LargestDelta     = $LargestDelta
                    Fails            = if ($null -ne $Fails) { [int] $Fails.Replace("/", "").Trim() } else { $null }
                    Total            = [int] $Total
                    PercentageError  = $Percentage
                    Type             = $Type
                    ReplicationError = $ReplicationError
                }
            }
        }
    }

    [Array] $operationalErrors = foreach ($line in $lines) {
        if ($line -match '^Experienced the following operational errors trying to retrieve replication information') {
            $processingErrors = $true
            continue
        }
        if ($processingErrors) {
            if ($line -match "^\s*(?<ErrorCode>\d+)\s+-\s+(?<ServerName>.*)$") {
                # Write-Verbose -Message "Processing error line: $line"
                $ErrorCode = $Matches.ErrorCode
                $ServerName = $Matches.ServerName
                if ($ServerName -match "\.") {
                    $HostName = $ServerName.Split(".")[0]
                } else {
                    $HostName = $ServerName
                }
                [PSCustomObject]@{
                    Server           = $HostName
                    LargestDelta     = $null
                    Fails            = 1
                    Total            = 1
                    PercentageError  = 100
                    Type             = "Unknown"
                    ReplicationError = "($ErrorCode) Error trying to retrieve replication information"
                }
            }
        }
    }


    # Combine the data from both sections
    $ReplicationSummary = $sourceData + $destinationData + $operationalErrors
    $ReplicationSummary

    if ($IncludeStatisticsVariable) {
        $Statistics = [ordered] @{
            "Good"             = 0
            "Failures"         = 0
            "Total"            = 0
            "DeltaOver1Hours"  = 0
            "DeltaOver3Hours"  = 0
            "DeltaOver6Hours"  = 0
            "DeltaOver12Hours" = 0
            "DeltaOver24Hours" = 0
            "UniqueErrors"     = [System.Collections.Generic.List[string]]::new()
            "UniqueWarnings"   = [System.Collections.Generic.List[string]]::new()
        }
        foreach ($Replication in $ReplicationSummary) {
            $Statistics.Total++

            if ($Replication.LargestDelta -gt (New-TimeSpan -Hours 24)) {
                $Statistics.DeltaOver24Hours++
            } elseif ($Replication.LargestDelta -gt (New-TimeSpan -Hours 12)) {
                $Statistics.DeltaOver12Hours++
            } elseif ($Replication.LargestDelta -gt (New-TimeSpan -Hours 6)) {
                $Statistics.DeltaOver6Hours++
            } elseif ($Replication.LargestDelta -gt (New-TimeSpan -Hours 3)) {
                $Statistics.DeltaOver3Hours++
            } elseif ($Replication.LargestDelta -gt (New-TimeSpan -Hours 1)) {
                $Statistics.DeltaOver1Hours++
            }
            if ($Replication.Fails -eq 0) {
                $Statistics.Good++
            } else {
                $Statistics.Failures++
            }
            if ($Replication.ReplicationError -notin "None", "") {
                if ($Replication.ReplicationError -like "*Operational errors trying to retrieve replication information*") {
                    if ($Replication.ReplicationError -notin $Statistics.UniqueWarnings) {
                        $Statistics.UniqueWarnings.Add($Replication.ReplicationError)
                    }
                } elseif ($Replication.ReplicationError -like "*The remote procedure call was cancelled.*") {
                    if ($Replication.ReplicationError -notin $Statistics.UniqueWarnings) {
                        $Statistics.UniqueWarnings.Add($Replication.ReplicationError)
                    }
                } elseif ($Replication.ReplicationError -like "*The RPC server is unavailable*") {
                    if ($Replication.ReplicationError -notin $Statistics.UniqueWarnings) {
                        $Statistics.UniqueWarnings.Add($Replication.ReplicationError)
                    }
                } elseif ($Replication.ReplicationError -notin $Statistics.UniqueErrors) {
                    if ($Statistics.UniqueErrors -notcontains $Replication.ReplicationError) {
                        $Statistics.UniqueErrors.Add($Replication.ReplicationError)
                    }
                }
            }
        }

        Set-Variable -Scope Global -Name $IncludeStatisticsVariable -Value $Statistics
    }
}