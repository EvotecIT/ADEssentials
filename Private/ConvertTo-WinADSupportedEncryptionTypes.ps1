function ConvertTo-WinADSupportedEncryptionTypes {
    [cmdletBinding()]
    param(
        [AllowNull()][object] $Value
    )

    if ($null -ne $Value -and $Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $Value = @($Value) | Select-Object -First 1
    }

    if ($null -eq $Value -or ($Value -is [string] -and $Value -eq '')) {
        return [PSCustomObject] @{
            RawValue               = $null
            ValueState             = 'Not configured'
            Types                  = [string[]] @()
            TypesText              = 'Not configured (uses KDC/domain defaults)'
            FallsBackToDomainDefaults = $true
            SupportsAESKeys        = $false
            SupportsRC4Encryption  = $false
            SupportsDESEncryption  = $false
            EnforcesAESSessionKeys = $false
        }
    }

    try {
        [int32] $RawValue = $Value
    } catch {
        return [PSCustomObject] @{
            RawValue               = $Value
            ValueState             = 'Invalid'
            Types                  = [string[]] @()
            TypesText              = "Invalid value: $Value"
            FallsBackToDomainDefaults = $false
            SupportsAESKeys        = $false
            SupportsRC4Encryption  = $false
            SupportsDESEncryption  = $false
            EnforcesAESSessionKeys = $false
        }
    }

    if ($RawValue -eq 0) {
        return [PSCustomObject] @{
            RawValue               = 0
            ValueState             = 'Configured as 0'
            Types                  = [string[]] @()
            TypesText              = 'Configured as 0 (uses KDC/domain defaults)'
            FallsBackToDomainDefaults = $true
            SupportsAESKeys        = $false
            SupportsRC4Encryption  = $false
            SupportsDESEncryption  = $false
            EnforcesAESSessionKeys = $false
        }
    }

    $EncryptionTypeMap = [ordered] @{
        '1'   = 'DES-CBC-CRC'
        '2'   = 'DES-CBC-MD5'
        '4'   = 'RC4-HMAC'
        '8'   = 'AES128-CTS-HMAC-SHA1-96'
        '16'  = 'AES256-CTS-HMAC-SHA1-96'
        '32'  = 'FAST-supported'
        '64'  = 'Compound-identity-supported'
        '128' = 'Claims-supported'
        '256' = 'AES256-CTS-HMAC-SHA1-96-SK'
        '512' = 'Resource-SID-compression-disabled'
    }

    [string[]] $Types = foreach ($Bit in $EncryptionTypeMap.Keys) {
        if ($RawValue -band [int32] $Bit) {
            $EncryptionTypeMap[$Bit]
        }
    }

    [PSCustomObject] @{
        RawValue               = $RawValue
        ValueState             = 'Configured'
        Types                  = $Types
        TypesText              = if ($Types.Count -gt 0) { $Types -join ', ' } else { 'None' }
        FallsBackToDomainDefaults = $false
        SupportsAESKeys        = $Types -contains 'AES128-CTS-HMAC-SHA1-96' -or $Types -contains 'AES256-CTS-HMAC-SHA1-96'
        SupportsRC4Encryption  = $Types -contains 'RC4-HMAC'
        SupportsDESEncryption  = $Types -contains 'DES-CBC-CRC' -or $Types -contains 'DES-CBC-MD5'
        EnforcesAESSessionKeys = $Types -contains 'AES256-CTS-HMAC-SHA1-96-SK'
    }
}
