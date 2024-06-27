function Get-WinADKerberosAccount {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $IncludeCriticalAccounts
    )
    $Today = Get-Date
    $Accounts = [ordered] @{
        'CriticalAccounts' = [ordered] @{}
        'Data'             = [ordered] @{}
    }
    Write-Verbose -Message "Get-WinADKerberosAccount - Gathering information about forest"
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -PreferWritable
    foreach ($Domain in $ForestInformation.Domains) {
        $Accounts['Data']["$Domain"] = [ordered] @{}
    }
    $DomainCount = 0
    $DomainCountTotal = $ForestInformation.Domains.Count
    foreach ($Domain in $ForestInformation.Domains) {
        $DomainCount++
        $ProcessingText = "[Domain: $DomainCount/$DomainCountTotal]"
        Write-Verbose -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain"
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'Name', 'SamAccountName', 'msDS-KrbTgtLinkBl',
            'Enabled',
            'PasswordLastSet', 'WhenCreated', 'WhenChanged'
            'AllowReversiblePasswordEncryption', 'BadLogonCount', 'AccountNotDelegated'
            'SID', 'SIDHistory'
        )
        $PropertiesMembers = @(
            'Name', 'SamAccountName'
            'Enabled',
            'PasswordLastSet', 'WhenCreated', 'WhenChanged'
            'AllowReversiblePasswordEncryption', 'BadLogonCount', 'AccountNotDelegated'
            'SID', 'SIDHistory'
        )

        $CountK = 0
        try {
            [Array] $KerberosPasswords = Get-ADUser -Filter "Name -like 'krbtgt*'" -Server $QueryServer -Properties $Properties -ErrorAction Stop
        } catch {
            Write-Warning -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain - unable to get Kerberos accounts. Error: $($_.Exception.Message)"
            continue
        }

        if ($IncludeCriticalAccounts) {
            $Members = @(
                try {
                    Get-ADGroupMember -Identity 'Domain Admins' -Server $QueryServer -Recursive -ErrorAction Stop
                } catch {
                    Write-Warning -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain - unable to get Domain Admins. Error: $($_.Exception.Message)"
                }
                try {
                    Get-ADGroupMember -Identity 'Enterprise Admins' -Server $QueryServer -Recursive -ErrorAction Stop
                } catch {
                    Write-Warning -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain - unable to get Enterprise Admins. Error: $($_.Exception.Message)"
                }
            ) | Sort-Object -Unique -Property DistinguishedName
        } else {
            $Members = @()
        }
        $CriticalAccounts = foreach ($Member in $Members) {
            Try {
                $User = Get-ADUser -Identity $Member.DistinguishedName -Server $QueryServer -Properties $PropertiesMembers -ErrorAction Stop
            } Catch {
                Write-Warning -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain - unable to get critical account $($Member.DistinguishedName). Error: $($_.Exception.Message)"
            }
            if ($User) {
                if ($null -eq $User.WhenChanged) {
                    $WhenChangedDaysAgo = $null
                } else {
                    $WhenChangedDaysAgo = ($Today) - $User.WhenChanged
                }
                if ($null -eq $User.PasswordLastSet) {
                    $PasswordLastSetAgo = $null
                } else {
                    $PasswordLastSetAgo = ($Today) - $User.PasswordLastSet
                }

                [PSCustomObject] @{
                    'Name'                              = $User.Name
                    'SamAccountName'                    = $User.SamAccountName
                    'Enabled'                           = $User.Enabled
                    'PasswordLastSet'                   = $User.PasswordLastSet
                    'PasswordLastSetDays'               = $PasswordLastSetAgo.Days
                    'WhenChangedDays'                   = $WhenChangedDaysAgo.Days
                    'WhenChanged'                       = $User.WhenChanged
                    'WhenCreated'                       = $User.WhenCreated
                    'AllowReversiblePasswordEncryption' = $User.AllowReversiblePasswordEncryption
                    'BadLogonCount'                     = $User.BadLogonCount
                    'AccountNotDelegated'               = $User.AccountNotDelegated
                    'SID'                               = $User.SID
                    'SIDHistory'                        = $User.SIDHistory
                }
            }
        }

        foreach ($Account in $KerberosPasswords) {
            $CountK++
            $ProcessingText = "[Domain: $DomainCount/$DomainCountTotal / Account: $CountK/$($KerberosPasswords.Count)]"
            Write-Verbose -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain \ Kerberos account ($CountK/$($KerberosPasswords.Count)) $($Account.SamAccountName) \ DC"

            #if ($Account.SamAccountName -like "*_*" -and -not $Account.'msDS-KrbTgtLinkBl') {
            #    Write-Warning -Message "Get-WinADKerberosAccount - Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ DC - Skipping"
            #    continue
            #}

            $CachedServers = [ordered] @{}
            $CountDC = 0
            $CountDCTotal = $ForestInformation.DomainDomainControllers[$Domain].Count
            foreach ($DC in $ForestInformation.DomainDomainControllers[$Domain]) {
                $CountDC++
                $Server = $DC.HostName
                $ProcessingText = "[Domain: $DomainCount/$DomainCountTotal / Account: $CountK/$($KerberosPasswords.Count), DC: $CountDC/$CountDCTotal]"
                Write-Verbose -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ DC Server $Server"
                try {
                    $ServerData = Get-ADUser -Identity $Account.DistinguishedName -Server $Server -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet', 'WhenCreated', 'WhenChanged' -ErrorAction Stop
                } catch {
                    Write-Warning -Message "Get-WinADKerberosAccount - Processing domain $Domain $ProcessingText \ Kerberos account $($Account.SamAccountName) \ DC Server $Server - Error: $($_.Exception.Message)"
                    $CachedServers[$Server] = [PSCustomObject] @{
                        'Server'              = $Server
                        'Name'                = $Server
                        'PasswordLastSet'     = $null
                        'PasswordLastSetDays' = $null
                        'WhenChangedDays'     = $null
                        'WhenChanged'         = $null
                        'WhenCreated'         = $null
                        'msDS-KrbTgtLinkBl'   = $ServerData.'msDS-KrbTgtLinkBl'
                        'Status'              = $_.Exception.Message
                    }
                }
                if ($ServerData.Name) {
                    if ($null -eq $ServerData.WhenChanged) {
                        $WhenChangedDaysAgo = $null
                    } else {
                        $WhenChangedDaysAgo = ($Today) - $ServerData.WhenChanged
                    }
                    if ($null -eq $ServerData.PasswordLastSet) {
                        $PasswordLastSetAgo = $null
                    } else {
                        $PasswordLastSetAgo = ($Today) - $ServerData.PasswordLastSet
                    }
                    if ($Account.SamAccountName -like "*_*" -and $ServerData.'msDS-KrbTgtLinkBl') {
                        $Status = 'OK'
                    } elseif ($Account.SamAccountName -like "*_*" -and -not $ServerData.'msDS-KrbTgtLinkBl') {
                        $Status = 'Missing link, orphaned?'
                    } else {
                        $Status = 'OK'
                    }

                    $CachedServers[$Server] = [PSCustomObject] @{
                        'Server'              = $Server
                        'Name'                = $ServerData.Name
                        'PasswordLastSet'     = $ServerData.'PasswordLastSet'
                        'PasswordLastSetDays' = $PasswordLastSetAgo.Days
                        'WhenChangedDays'     = $WhenChangedDaysAgo.Days
                        'WhenChanged'         = $ServerData.'WhenChanged'
                        'WhenCreated'         = $ServerData.'WhenCreated'
                        'msDS-KrbTgtLinkBl'   = $ServerData.'msDS-KrbTgtLinkBl'
                        'Status'              = $Status
                    }
                }
            }

            Write-Verbose -Message "Get-WinADKerberosAccount - Gathering information about forest for Global Catalogs"
            $ForestInformationGC = Get-WinADForestDetails -Forest $Forest
            $ProcessingText = "[Domain: $DomainCount/$DomainCountTotal / Account: $CountK/$($KerberosPasswords.Count)]"
            Write-Verbose -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ GC"
            $GlobalCatalogs = [ordered] @{}
            $GlobalCatalogCount = 0
            $GlobalCatalogCountTotal = $ForestInformationGC.ForestDomainControllers.Count
            foreach ($DC in $ForestInformationGC.ForestDomainControllers) {
                $GlobalCatalogCount++

                $Server = $DC.HostName
                $ProcessingText = "[Domain: $DomainCount/$DomainCountTotal / Account: $CountK/$($KerberosPasswords.Count), GC: $GlobalCatalogCount/$GlobalCatalogCountTotal]"
                Write-Verbose -Message "Get-WinADKerberosAccount - $ProcessingText Processing domain $Domain \ Kerberos account $($Account.SamAccountName) \ GC Server $Server"

                if ($DC.IsGlobalCatalog ) {
                    try {
                        $ServerData = Get-ADUser -Identity $Account.DistinguishedName -Server "$($Server):3268" -Properties 'msDS-KrbTgtLinkBl', 'PasswordLastSet', 'WhenCreated', 'WhenChanged' -ErrorAction Stop
                    } catch {
                        Write-Warning -Message "Get-WinADKerberosAccount - Processing domain $Domain $ProcessingText \ Kerberos account $($Account.SamAccountName) \ GC Server $Server - Error: $($_.Exception.Message)"
                        $GlobalCatalogs[$Server] = [PSCustomObject] @{
                            'Server'              = $Server
                            'Name'                = $Server
                            'PasswordLastSet'     = $null
                            'PasswordLastSetDays' = $null
                            'WhenChangedDays'     = $null
                            'WhenChanged'         = $null
                            'WhenCreated'         = $null
                            'msDS-KrbTgtLinkBl'   = $null
                            'Status'              = $_.Exception.Message
                        }
                    }

                    if ($ServerData.Name) {
                        if ($null -eq $ServerData.WhenChanged) {
                            $WhenChangedDaysAgo = $null
                        } else {
                            $WhenChangedDaysAgo = ($Today) - $ServerData.WhenChanged
                        }
                        if ($null -eq $ServerData.PasswordLastSet) {
                            $PasswordLastSetAgo = $null
                        } else {
                            $PasswordLastSetAgo = ($Today) - $ServerData.PasswordLastSet
                        }
                        $GlobalCatalogs[$Server] = [PSCustomObject] @{
                            'Server'              = $Server
                            'Name'                = $ServerData.Name
                            'PasswordLastSet'     = $ServerData.'PasswordLastSet'
                            'PasswordLastSetDays' = $PasswordLastSetAgo.Days
                            'WhenChangedDays'     = $WhenChangedDaysAgo.Days
                            'WhenChanged'         = $ServerData.'WhenChanged'
                            'WhenCreated'         = $ServerData.'WhenCreated'
                            'msDS-KrbTgtLinkBl'   = $ServerData.'msDS-KrbTgtLinkBl'
                            'Status'              = 'OK'
                        }
                    }
                }
            }

            if ($null -eq $Account.PasswordLastSet) {
                $PasswordLastSetAgo = $null
            } else {
                $PasswordLastSetAgo = ($Today) - $Account.PasswordLastSet
            }
            if ($null -eq $Account.WhenChanged) {
                $WhenChangedDaysAgo = $null
            } else {
                $WhenChangedDaysAgo = ($Today) - $Account.WhenChanged
            }
            $Accounts['Data']["$Domain"][$Account.SamAccountName] = @{
                FullInformation   = [PSCustomObject] @{
                    'Name'                              = $Account.Name
                    'SamAccountName'                    = $Account.SamAccountName
                    'Enabled'                           = $Account.Enabled
                    'PasswordLastSet'                   = $Account.PasswordLastSet
                    'PasswordLastSetDays'               = $PasswordLastSetAgo.Days
                    'WhenChangedDays'                   = $WhenChangedDaysAgo.Days
                    'WhenChanged'                       = $Account.WhenChanged
                    'WhenCreated'                       = $Account.WhenCreated
                    'AllowReversiblePasswordEncryption' = $Account.AllowReversiblePasswordEncryption
                    'BadLogonCount'                     = $Account.BadLogonCount
                    'AccountNotDelegated'               = $Account.AccountNotDelegated
                    'SID'                               = $Account.SID
                    'SIDHistory'                        = $Account.SIDHistory
                }
                DomainControllers = $CachedServers
                GlobalCatalogs    = $GlobalCatalogs

            }
        }
        $Accounts['CriticalAccounts']["$Domain"] = $CriticalAccounts
    }
    $Accounts
}