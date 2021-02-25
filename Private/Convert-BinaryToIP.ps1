function Convert-BinaryToIP {
    [cmdletBinding()]
    param(
        [string] $Binary
    )
    $Binary = $Binary -replace '\s+'
    if ($Binary.Length % 8) {
        Write-Warning -Message "Convert-BinaryToIP - Binary string '$Binary' is not evenly divisible by 8."
        return $Null
    }
    [int] $NumberOfBytes = $Binary.Length / 8
    $Bytes = @(foreach ($i in 0..($NumberOfBytes - 1)) {
            try {
                #$Bytes += # skipping this and collecting "outside" seems to make it like 10 % faster
                [System.Convert]::ToByte($Binary.Substring(($i * 8), 8), 2)
            } catch {
                Write-Warning -Message "Convert-BinaryToIP - Error converting '$Binary' to bytes. `$i was $i."
                return $Null
            }
        })
    return $Bytes -join '.'
}