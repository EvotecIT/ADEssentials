function ConvertTo-TimeSpanFromRepadmin {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$timeString
    )

    switch -Regex ($timeString) {
        '^\s*(\d+)d\.(\d+)h:(\d+)m:(\d+)s\s*$' {
            $days = $Matches[1]
            $hours = $Matches[2]
            $minutes = $Matches[3]
            $seconds = $Matches[4]
            New-TimeSpan -Days $days -Hours $hours -Minutes $minutes -Seconds $seconds
        }
        '^\s*(\d+)h:(\d+)m:(\d+)s\s*$' {
            $hours = $Matches[1]
            $minutes = $Matches[2]
            $seconds = $Matches[3]
            New-TimeSpan -Hours $hours -Minutes $minutes -Seconds $seconds
        }
        '^\s*(\d+)m:(\d+)s\s*$' {
            $minutes = $Matches[1]
            $seconds = $Matches[2]
            New-TimeSpan -Minutes $minutes -Seconds $seconds
        }
        '^\s*:(\d+)s\s*$' {
            $seconds = $Matches[1]
            New-TimeSpan -Seconds $seconds
        }
        '^\s*(\d+)s\s*$' {
            $seconds = $Matches[1]
            New-TimeSpan -Seconds $seconds
        }
        '^>60 days\s*$' {
            New-TimeSpan -Days 60
        }
        '^\s*\(unknown\)\s*$' {
            $null
        }
        default {
            $null
        }
    }
}