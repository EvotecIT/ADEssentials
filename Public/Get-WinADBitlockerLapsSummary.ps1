function Get-WinADBitlockerLapsSummary {
    [CmdletBinding()]
    param(
        [string[]] $Domain
    )
    if (-not $Domain) {
        $Domain = (Get-ADForest).Domains
    }
    $ComputerProperties = @(
        $Schema = [directoryservices.activedirectory.activedirectoryschema]::GetCurrentSchema()
        @(
            $Schema.FindClass("computer").mandatoryproperties | Select-Object name, commonname, description, syntax
            $Schema.FindClass("computer").optionalproperties | Select-Object name, commonname, description, syntax
        )
    )
    if ($ComputerProperties.Name -contains 'ms-Mcs-AdmPwd') {
        $LapsAvailable = $true
        $Properties = @(
            'Name'
            'OperatingSystem'
            'OperatingSystemVersion'
            'DistinguishedName'
            'LastLogonDate'
            'ms-Mcs-AdmPwd'
            'ms-Mcs-AdmPwdExpirationTime'
        )
    } else {
        $LapsAvailable = $false
        $Properties = @(
            'Name'
            'OperatingSystem'
            'OperatingSystemVersion'
            'DistinguishedName'
            'LastLogonDate'
        )
    }
    $CurrentDate = Get-Date
    $FormattedComputers = foreach ($D in $Domain) {
        $Computers = Get-ADComputer -Filter * -Properties $Properties -Server $D
        foreach ($_ in $Computers) {
            if ($LapsAvailable) {
                if ($_.'ms-Mcs-AdmPwd') {
                    $Laps = $true
                    $LapsExpirationDays = Convert-TimeToDays -StartTime ($CurrentDate) -EndTime (Convert-ToDateTime -Timestring ($_.'ms-Mcs-AdmPwdExpirationTime'))
                    $LapsExpirationTime = Convert-ToDateTime -Timestring ($_.'ms-Mcs-AdmPwdExpirationTime')
                } else {
                    $Laps = $false
                    $LapsExpirationDays = $null
                    $LapsExpirationTime = $null
                }
            } else {
                $Laps = 'N/A'
            }
            [Array] $Bitlockers = Get-ADObject -Server $D -Filter 'objectClass -eq "msFVE-RecoveryInformation"' -SearchBase $_.DistinguishedName -Properties 'WhenCreated', 'msFVE-RecoveryPassword' | Sort-Object -Descending
            if ($Bitlockers) {
                $Encrypted = $true
                $EncryptedTime = $Bitlockers[0].WhenCreated
            } else {
                $Encrypted = $false
                $EncryptedTime = $null
            }
            [PSCustomObject] @{
                Name               = $_.Name
                Enabled            = $_.Enabled
                Domain             = $D
                DNSHostName        = $_.DNSHostName
                DistinguishedName  = $_.DistinguishedName
                System             = ConvertTo-OperatingSystem -OperatingSystem $_.OperatingSystem -OperatingSystemVersion $_.OperatingSystemVersion
                LastLogonDate      = $_.LastLogonDate
                Encrypted          = $Encrypted
                EncryptedTime      = $EncryptedTime
                Laps               = $Laps
                LapsExpirationDays = $LapsExpirationDays
                LapsExpirationTime = $LapsExpirationTime
            }
        }
    }
    return $FormattedComputers
}