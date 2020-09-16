function ConvertTo-Date {
    [cmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline, Mandatory)]$AccountExpires
    )
    process {
        $lngValue = $AccountExpires
        if (($lngValue -eq 0) -or ($lngValue -gt [DateTime]::MaxValue.Ticks)) {
            $AccountExpirationDate = $null
        } else {
            $Date = [DateTime]$lngValue
            $AccountExpirationDate = $Date.AddYears(1600).ToLocalTime()
        }
        $AccountExpirationDate
    }
}