function ConvertTo-Date {
    <#
    .SYNOPSIS
    Converts a numerical account expiration value to a readable date.

    .DESCRIPTION
    This function takes a numerical account expiration value and converts it to a readable date format. If the value is 0 or exceeds the maximum DateTime value, it returns $null.

    .PARAMETER AccountExpires
    The numerical account expiration value to convert.

    .EXAMPLE
    ConvertTo-Date -AccountExpires 1324567890
    Converts the numerical account expiration value to a readable date.

    .NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
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