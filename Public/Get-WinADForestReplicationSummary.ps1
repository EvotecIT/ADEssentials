function Get-WinADForestReplicationSummary {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'InputContent')][string] $InputContent,
        [Parameter(ParameterSetName = 'FilePath')][string] $FilePath
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
    $sourceData = foreach ($line in $lines) {
        if ($line -match '^Experienced the following operational errors trying to retrieve replication information') {
            break
        }
        if ($line -match '\S' -and $line -notmatch '^\s*largest') {
            if ($line -match "^\s*(?<DSA>\S+)\s+(?<Rest>.*)$") {
                Write-Verbose -Message "Processing line: $line"
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
                    Fails            = if ($null -ne $Fails) { $Fails.Replace("/", "").Trim() } else { $null }
                    Total            = $Total
                    PercentageError  = $Percentage
                    Type             = $Type
                    ReplicationError = $ReplicationError
                }
            }
        }
    }

    $lines = $sections[2] -split "`r`n"
    $destinationData = foreach ($line in $lines) {
        if ($line -match '^Experienced the following operational errors trying to retrieve replication information') {
            break
        }
        if ($line -match '\S' -and $line -notmatch '^\s*largest') {
            if ($line -match "^\s*(?<DSA>\S+)\s+(?<Rest>.*)$") {
                Write-Verbose -Message "Processing line: $line"
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
                    Fails            = if ($null -ne $Fails) { $Fails.Replace("/", "").Trim() } else { $null }
                    Total            = $Total
                    PercentageError  = $Percentage
                    Type             = $Type
                    ReplicationError = $ReplicationError
                }
            }
        }
    }
    # Combine the data from both sections
    $sourceData + $destinationData
}