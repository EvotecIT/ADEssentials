function Get-WinADKerberosAccount {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Today = Get-Date
    $Accounts = [ordered] @{}
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $Accounts["$Domain"] = [ordered] @{}
    }
    foreach ($Domain in $ForestInformation.Domains) {
        Write-Verbose -Message "Get-WinADKerberosAccount - Processing domain $Domain"
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'Name', 'SamAccountName', 'msDS-KrbTgtLinkBl',
            'Enabled',
            'PasswordLastSet', 'WhenCreated', 'WhenChanged'
            'AllowReversiblePasswordEncryption', 'BadLogonCount', 'AccountNotDelegated'
            'SID', 'SIDHistory'
        )

        $KerberosPasswords = Get-ADUser -Filter "Name -like 'krbtgt*'" -Server $QueryServer -Properties $Properties #| Select-Object -Property $Properties

        foreach ($Account in $KerberosPasswords) {
            Write-Verbose -Message "Get-WinADKerberosAccount - Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ DC"

            if ($Account.SamAccountName -like "*_*" -and -not $Account.'msDS-KrbTgtLinkBl') {
                Write-Warning -Message "Get-WinADKerberosAccount - Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ DC - Skipping"
                continue
            }

            $CachedServers = [ordered] @{}
            foreach ($DC in $ForestInformation.DomainDomainControllers[$Domain]) {
                $Server = $DC.HostName
                Write-Verbose -Message "Get-WinADKerberosAccount - Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ DC Server $Server"
                $ServerData = Get-ADUser -Identity $Account.DistinguishedName -Server $Server -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet', 'WhenCreated', 'WhenChanged'

                $WhenChangedDaysAgo = ($Today) - $ServerData.WhenChanged
                $PasswordLastSetAgo = ($Today) - $ServerData.PasswordLastSet

                $CachedServers[$Server] = [PSCustomObject] @{
                    'Server'              = $Server
                    'Name'                = $ServerData.Name
                    'GlobalCatalog'       = $ServerData.'msDS-KrbTgtLinkBl'
                    'PasswordLastSet'     = $ServerData.'PasswordLastSet'
                    'PasswordLastSetDays' = $PasswordLastSetAgo.Days
                    'WhenChangedDays'     = $WhenChangedDaysAgo.Days
                    'WhenChanged'         = $ServerData.'WhenChanged'
                    'WhenCreated'         = $ServerData.'WhenCreated'
                }
            }

            Write-Verbose -Message "Get-WinADKerberosAccount - Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ GC"
            $GlobalCatalogs = [ordered] @{}
            foreach ($DC in $ForestInformation.ForestDomainControllers) {
                if ($DC.IsGlobalCatalog ) {
                    $Server = $DC.HostName
                    #$DomainPerServer = $DC.Domain
                    Write-Verbose -Message "Get-WinADKerberosAccount - Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ GC Server $Server"
                    $ServerData = Get-ADUser -Identity $Account.DistinguishedName -Server "$($Server):3268" -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet', 'WhenCreated', 'WhenChanged'

                    $WhenChangedDaysAgo = ($Today) - $ServerData.WhenChanged
                    $PasswordLastSetAgo = ($Today) - $ServerData.PasswordLastSet

                    $GlobalCatalogs[$Server] = [PSCustomObject] @{
                        'Server'              = $Server
                        'Name'                = $ServerData.Name
                        'GlobalCatalog'       = $ServerData.'msDS-KrbTgtLinkBl'
                        'PasswordLastSet'     = $ServerData.'PasswordLastSet'
                        'PasswordLastSetDays' = $PasswordLastSetAgo.Days
                        'WhenChangedDays'     = $WhenChangedDaysAgo.Days
                        'WhenChanged'         = $ServerData.'WhenChanged'
                        'WhenCreated'         = $ServerData.'WhenCreated'
                    }
                }
            }

            $Accounts["$Domain"][$Account.SamAccountName] = @{
                FullInformation   = $Account
                DomainControllers = $CachedServers
                GlobalCatalogs    = $GlobalCatalogs
            }
        }
    }
    $Accounts
}