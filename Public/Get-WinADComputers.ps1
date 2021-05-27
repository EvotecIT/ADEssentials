function Get-WinADComputers {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $PerDomain
    )
    $Today = Get-Date
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation

    $Output = [ordered] @{}
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'DistinguishedName', 'LastLogonDate', 'PasswordLastSet', 'Enabled', 'DnsHostName', 'PasswordNeverExpires', 'PasswordNotRequired',
            'PasswordExpired', 'Manager', 'OperatingSystemVersion', 'OperatingSystem' , 'TrustedForDelegation', 'WhenCreated', 'WhenChanged', 'PrimaryGroupID'
        )
        $Computers = Get-ADComputer -Filter * -Server $QueryServer -Properties $Properties
        $Output[$Domain] = foreach ($Computer in $Computers) {
            $ComputerLocation = ($Computer.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
            $Region = $ComputerLocation[-4]
            $Country = $ComputerLocation[-5]
            if ($null -ne $Computer.LastLogonDate) {
                $LastLogonDays = "$(-$($Computer.LastLogonDate - $Today).Days)"
            } else {
                $LastLogonDays = $null
            }
            if ($null -ne $Computer.PasswordLastSet) {
                $PasswordLastChangedDays = "$(-$($Computer.PasswordLastSet - $Today).Days)"
            } else {
                $PasswordLastChangedDays = $null
            }
            [PSCustomObject] @{
                Name                 = $Computer.Name
                SamAccountName       = $Computer.SamAccountName
                IsDC                 = if ($Computer.PrimaryGroupID -in 516, 521) { $true } else { $false }
                WhenChanged          = $Computer.WhenChanged
                Enabled              = $Computer.Enabled
                LastLogonDays        = $LastLogonDays
                PasswordLastDays     = $PasswordLastChangedDays
                Level0               = $Region
                Level1               = $Country
                OperatingSystem      = $Computer.OperatingSystem
                #OperatingSystemVersion = $Computer.OperatingSystemVersion
                OperatingSystemName  = ConvertTo-OperatingSystem -OperatingSystem $Computer.OperatingSystem -OperatingSystemVersion $Computer.OperatingSystemVersion
                DistinguishedName    = $Computer.DistinguishedName
                LastLogonDate        = $Computer.LastLogonDate
                PasswordLastSet      = $Computer.PasswordLastSet
                PasswordNeverExpires = $Computer.PasswordNeverExpires
                PasswordNotRequired  = $Computer.PasswordNotRequired
                PasswordExpired      = $Computer.PasswordExpired
                ManagerDN            = $Computer.Manager
                #ManagerLastLogon     = $ManagerLastLogon
                #Group                = $Group
                Description          = $Computer.Description
                TrustedForDelegation = $Computer.TrustedForDelegation
                #Location          = $Location
                #Region            = $Region
                #Country           = $Country
            }

        }
    }
    if ($PerDomain) {
        $Output
    } else {
        $Output.Values
    }

}