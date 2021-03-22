function Convert-IPToBinary {
    [cmdletBinding()]
    param(
        [string] $IP
    )
    $IPv4Regex = '(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)'
    $IP = $IP.Trim()
    if ($IP -match "\A${IPv4Regex}\z") {
        try {
            return ($IP.Split('.') | ForEach-Object { [System.Convert]::ToString([byte] $_, 2).PadLeft(8, '0') }) -join ''
        } catch {
            Write-Warning -Message "Convert-IPToBinary - Error converting '$IP' to a binary string: $_"
            return $Null
        }
    } else {
        Write-Warning -Message "Convert-IPToBinary - Invalid IP detected: '$IP'. Conversion failed."
        return $Null
    }
}