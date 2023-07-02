function Get-WinADObject {
    <#
    .SYNOPSIS
    Gets Active Directory Object

    .DESCRIPTION
    Returns Active Directory Object (Computers, Groups, Users or ForeignSecurityPrincipal) using ADSI

    .PARAMETER Identity
    Identity of an object. It can be SamAccountName, SID, DistinguishedName or multiple other options

    .PARAMETER DomainName
    Choose domain name the objects resides in. This is optional for most objects

    .PARAMETER Credential
    Parameter description

    .PARAMETER IncludeGroupMembership
    Queries for group members when object is a group

    .PARAMETER IncludeAllTypes
    Allows functions to return all objects types and not only Computers, Groups, Users or ForeignSecurityPrincipal

    .EXAMPLE
    Get-WinADObject -Identity 'TEST\Domain Admins' -Verbose
    Get-WinADObject -Identity 'EVOTEC\Domain Admins' -Verbose
    Get-WinADObject -Identity 'Domain Admins' -DomainName 'DC=AD,DC=EVOTEC,DC=PL' -Verbose
    Get-WinADObject -Identity 'Domain Admins' -DomainName 'ad.evotec.pl' -Verbose
    Get-WinADObject -Identity 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=pl'
    Get-WinADObject -Identity 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=xyz'

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)][Array] $Identity,
        [string] $DomainName,
        [pscredential] $Credential,
        [switch] $IncludeGroupMembership,
        [switch] $IncludeAllTypes,
        [switch] $AddType,
        [switch] $Cache,
        [string[]] $Properties
    )
    Begin {
        if ($Cache -and -not $Script:CacheObjectsWinADObject) {
            $Script:CacheObjectsWinADObject = @{}
        }
        # This is purely for calling group workaround
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement

        $GroupTypes = @{
            '2'           = @{
                Name  = 'Distribution Group - Global' # distribution
                Type  = 'Distribution'
                Scope = 'Global'
            }
            '4'           = @{
                Name  = 'Distribution Group - Domain Local' # distribution
                Type  = 'Distribution'
                Scope = 'Domain local'
            }
            '8'           = @{
                Name  = 'Distribution Group - Universal'
                Type  = 'Distribution'
                Scope = 'Universal'
            }
            '-2147483640' = @{
                Name  = 'Security Group - Universal'
                Type  = 'Security'
                Scope = 'Universal'
            }
            '-2147483643' = @{
                Name  = 'Security Group - Builtin Local' # Builtin local Security Group
                Type  = 'Security'
                Scope = 'Builtin local'
            }
            '-2147483644' = @{
                Name  = 'Security Group - Domain Local'
                Type  = 'Security'
                Scope = 'Domain local'
            }
            '-2147483646' = @{
                Name  = 'Security Group - Global' # security
                Type  = 'Security'
                Scope = 'Global'
            }
        }
    }
    process {
        foreach ($Ident in $Identity) {
            if (-not $Ident) {
                Write-Warning -Message "Get-WinADObject - Identity is empty. Skipping"
                continue
            }
            $ResolvedIdentity = $null
            # If it's an object we need to make sure we pass only DN
            if ($Ident.DistinguishedName) {
                $Ident = $Ident.DistinguishedName
            }
            # we reset domain name to it's given value if at all
            $TemporaryName = $Ident
            $TemporaryDomainName = $DomainName

            # Since we change $Ident below to different names we need to be sure we use original query for cache
            if ($Cache -and $Script:CacheObjectsWinADObject[$TemporaryName]) {
                Write-Verbose "Get-WinADObject - Requesting $TemporaryName from Cache"
                $Script:CacheObjectsWinADObject[$TemporaryName]
                continue
            }
            # if Domain Name is provided we don't check for anything as it's most likely already good Ident value
            if (-not $TemporaryDomainName) {
                $MatchRegex = [Regex]::Matches($Ident, "S-\d-\d+-(\d+-|){1,14}\d+")
                if ($MatchRegex.Success) {
                    $ResolvedIdentity = ConvertFrom-SID -SID $MatchRegex.Value
                    $TemporaryDomainName = $ResolvedIdentity.DomainName
                    $Ident = $MatchRegex.Value
                } elseif ($Ident -like '*\*') {
                    $ResolvedIdentity = Convert-Identity -Identity $Ident -Verbose:$false
                    if ($ResolvedIdentity.SID) {
                        $TemporaryDomainName = $ResolvedIdentity.DomainName
                        $Ident = $ResolvedIdentity.SID
                    } else {
                        $NetbiosConversion = ConvertFrom-NetbiosName -Identity $Ident
                        if ($NetbiosConversion.DomainName) {
                            $TemporaryDomainName = $NetbiosConversion.DomainName
                            $Ident = $NetbiosConversion.Name
                        }
                    }
                } elseif ($Ident -like '*DC=*') {
                    $DNConversion = ConvertFrom-DistinguishedName -DistinguishedName $Ident -ToDomainCN
                    $TemporaryDomainName = $DNConversion
                } elseif ($Ident -like '*@*') {
                    $CNConversion = $Ident -split '@', 2
                    $TemporaryDomainName = $CNConversion[1]
                    $Ident = $CNConversion[0]
                } elseif ($Ident -like '*.*') {
                    $ResolvedIdentity = Convert-Identity -Identity $Ident -Verbose:$false
                    if ($ResolvedIdentity.SID) {
                        $TemporaryDomainName = $ResolvedIdentity.DomainName
                        $Ident = $ResolvedIdentity.SID
                    } else {
                        $CNConversion = $Ident -split '\.', 2
                        $Ident = $CNConversion[0]
                        $TemporaryDomainName = $CNConversion[1]
                    }
                } else {
                    $ResolvedIdentity = Convert-Identity -Identity $Ident -Verbose:$false
                    if ($ResolvedIdentity.SID) {
                        $TemporaryDomainName = $ResolvedIdentity.DomainName
                        $Ident = $ResolvedIdentity.SID
                    } else {
                        $NetbiosConversion = ConvertFrom-NetbiosName -Identity $Ident
                        if ($NetbiosConversion.DomainName) {
                            $TemporaryDomainName = $NetbiosConversion.DomainName
                            $Ident = $NetbiosConversion.Name
                        }
                    }
                }
            }


            # Building up ADSI call
            $Search = [System.DirectoryServices.DirectorySearcher]::new()
            #$Search.SizeLimit = $SizeLimit
            if ($TemporaryDomainName) {
                try {
                    $Context = [System.DirectoryServices.AccountManagement.PrincipalContext]::new('Domain', $TemporaryDomainName)
                } catch {
                    Write-Warning "Get-WinADObject - Building context failed ($TemporaryDomainName), error: $($_.Exception.Message)"
                }
            } else {
                try {
                    $Context = [System.DirectoryServices.AccountManagement.PrincipalContext]::new('Domain')
                } catch {
                    Write-Warning "Get-WinADObject - Building context failed, error: $($_.Exception.Message)"
                }
            }
            #Convert Identity Input String to HEX, if possible
            Try {
                $IdentityGUID = ""
                ([System.Guid]$Ident).ToByteArray() | ForEach-Object { $IdentityGUID += $("\{0:x2}" -f $_) }
            } Catch {
                $IdentityGUID = "null"
            }
            # Building search filter
            $Search.filter = "(|(DistinguishedName=$Ident)(Name=$Ident)(SamAccountName=$Ident)(UserPrincipalName=$Ident)(objectGUID=$IdentityGUID)(objectSid=$Ident))"

            if ($TemporaryDomainName) {
                $Search.SearchRoot = "LDAP://$TemporaryDomainName"
            }
            if ($PSBoundParameters['Credential']) {
                $Cred = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$TemporaryDomainName", $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                $Search.SearchRoot = $Cred
            }
            Write-Verbose "Get-WinADObject - Requesting $Ident ($TemporaryDomainName)"
            try {
                $SearchResults = $($Search.FindAll())
            } catch {
                if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                    throw "Get-WinADObject - Requesting $Ident ($TemporaryDomainName) failed. Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                } else {
                    Write-Warning "Get-WinADObject - Requesting $Ident ($TemporaryDomainName) failed. Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    continue
                }
            }

            if ($SearchResults.Count -lt 1) {
                if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                    throw "Requesting $Ident ($TemporaryDomainName) failed with no results."
                }
            }

            foreach ($Object in $SearchResults) {
                $UAC = Convert-UserAccountControl -UserAccountControl ($Object.properties.useraccountcontrol -as [string])
                $ObjectClass = ($Object.properties.objectclass -as [array])[-1]
                if ($ObjectClass -notin 'group', 'contact', 'inetOrgPerson', 'computer', 'user', 'foreignSecurityPrincipal', 'msDS-ManagedServiceAccount', 'msDS-GroupManagedServiceAccount' -and (-not $IncludeAllTypes)) {
                    Write-Warning "Get-WinADObject - Unsupported object ($Ident) of type $ObjectClass. Only user,computer,group, foreignSecurityPrincipal, msDS-ManagedServiceAccount, msDS-GroupManagedServiceAccount are displayed by default. Use IncludeAllTypes switch to display all if nessecary."
                    continue
                }
                $Members = $Object.properties.member -as [array]
                if ($ObjectClass -eq 'group') {
                    # we only do this additional step when requested. It's not nessecary for day to day use but can hurt performance real bad for normal use cases
                    # This was especially visible for group with 50k members and Get-WinADObjectMember which doesn't even require this data
                    if ($IncludeGroupMembership) {
                        # This is weird case but for some reason $Object.properties.member doesn't always return all values
                        # the workaround is to do additional query for group and assing it

                        $GroupMembers = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($Context, $Ident).Members
                        try {
                            [Array] $Members = foreach ($Member in $GroupMembers) {
                                if ($Member.DistinguishedName) {
                                    $Member.DistinguishedName
                                } elseif ($Member.DisplayName) {
                                    $Member.DisplayName
                                } else {
                                    $Member.Sid
                                }
                            }
                        } catch {
                            if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                                throw
                                return
                            } else {
                                Write-Warning -Message "Error while parsing group members for $($Ident): $($_.Exception.Message)"
                            }
                        }
                    }
                }
                $ObjectDomainName = ConvertFrom-DistinguishedName -DistinguishedName ($Object.properties.distinguishedname -as [string]) -ToDomainCN
                $DisplayName = $Object.properties.displayname -as [string]
                $SamAccountName = $Object.properties.samaccountname -as [string]
                $Name = $Object.properties.name -as [string]

                if ($ObjectClass -eq 'foreignSecurityPrincipal' -and $DisplayName -eq '') {
                    # If object is foreignSecurityPrincipal (which shouldn't happen at this point) we need to set it to temporary name we
                    # used before. Usually this is to fix 'NT AUTHORITY\INTERACTIVE'
                    # I have no clue if there's better way to do it
                    $DisplayName = $ResolvedIdentity.Name
                    if ($DisplayName -like '*\*') {
                        $NetbiosWithName = $DisplayName -split '\\'
                        if ($NetbiosWithName.Count -eq 2) {
                            #$NetbiosName = $NetbiosWithName[0]
                            $NetbiosUser = $NetbiosWithName[1]
                            $Name = $NetbiosUser
                            $SamAccountName = $NetbiosUser
                        } else {
                            $Name = $DisplayName
                        }
                    } else {
                        $Name = $DisplayName
                    }
                }

                $GroupType = $Object.properties.grouptype -as [string]
                if ($Object.Properties.objectsid) {
                    try {
                        $ObjectSID = [System.Security.Principal.SecurityIdentifier]::new($Object.Properties.objectsid[0], 0).Value
                    } catch {
                        Write-Warning "Get-WinADObject - Getting objectsid failed, error: $($_.Exception.Message)"
                        $ObjectSID = $null
                    }
                } else {
                    $ObjectSID = $null
                }

                $ReturnObject = [ordered] @{
                    DisplayName         = $DisplayName
                    Name                = $Name
                    SamAccountName      = $SamAccountName
                    ObjectClass         = $ObjectClass
                    Enabled             = if ($ObjectClass -in 'group', 'contact') { $null } else { $UAC -notcontains 'ACCOUNTDISABLE' }
                    PasswordNeverExpire = if ($ObjectClass -in 'group', 'contact') { $null } else { $UAC -contains 'DONT_EXPIRE_PASSWORD' }
                    DomainName          = $ObjectDomainName
                    Distinguishedname   = $Object.properties.distinguishedname -as [string]
                    #Adspath             = $Object.properties.adspath -as [string]
                    WhenCreated         = $Object.properties.whencreated -as [string]
                    WhenChanged         = $Object.properties.whenchanged -as [string]
                    #Deleted             = $Object.properties.isDeleted -as [string]
                    #Recycled            = $Object.properties.isRecycled -as [string]
                    UserPrincipalName   = $Object.properties.userprincipalname -as [string]
                    ObjectSID           = $ObjectSID
                    MemberOf            = $Object.properties.memberof -as [array]
                    Members             = $Members
                    DirectReports       = $Object.Properties.directreports
                    GroupScopedType     = $GroupTypes[$GroupType].Name
                    GroupScope          = $GroupTypes[$GroupType].Scope
                    GroupType           = $GroupTypes[$GroupType].Type
                    #Administrative      = if ($Object.properties.admincount -eq '1') { $true } else { $false }
                    #Type                = $ResolvedIdentity.Type
                    Description         = $Object.properties.description -as [string]
                }

                if ($Properties -contains 'LastLogonDate') {
                    $LastLogon = [int64] $Object.properties.lastlogontimestamp[0]
                    if ($LastLogon -ne 9223372036854775807) {
                        $ReturnObject['LastLogonDate'] = [datetime]::FromFileTimeUtc($LastLogon)
                    } else {
                        $ReturnObject['LastLogonDate'] = $null
                    }
                }
                if ($Properties -contains 'PasswordLastSet') {
                    $PasswordLastSet = [int64] $Object.properties.pwdlastset[0]
                    if ($PasswordLastSet -ne 9223372036854775807) {
                        $ReturnObject['PasswordLastSet'] = [datetime]::FromFileTimeUtc($PasswordLastSet)
                    } else {
                        $ReturnObject['PasswordLastSet'] = $null
                    }
                }
                if ($Properties -contains 'AccountExpirationDate') {
                    $ExpirationDate = [int64] $Object.properties.accountexpires[0]
                    if ($ExpirationDate -ne 9223372036854775807) {
                        $ReturnObject['AccountExpirationDate'] = [datetime]::FromFileTimeUtc($ExpirationDate)
                    } else {
                        $ReturnObject['AccountExpirationDate'] = $null
                    }
                }

                if ($AddType) {
                    if (-not $ResolvedIdentity) {
                        # This is purely to get special types
                        $ResolvedIdentity = ConvertFrom-SID -SID $ReturnObject['ObjectSID']
                    }
                    $ReturnObject['Type'] = $ResolvedIdentity.Type
                }
                if ($ReturnObject['Type'] -eq 'WellKnownAdministrative') {
                    if (-not $TemporaryDomainName) {
                        # This is so BUILTIN\Administrators would not report domain name that's always related to current one, while it could be someone expects it to be from different forest
                        # this is to mainly address issues with Get-ADACL IdentityReference returning data that's hard to manage otherwise
                        $ReturnObject['DomainName'] = ''
                    }
                }

                <#
                $LastLogon = $Object.properties.lastlogon -as [string]
                if ($LastLogon) {
                    $LastLogonDate = [datetime]::FromFileTime($LastLogon)
                } else {
                    $LastLogonDate = $null
                }

                $AccountExpires = $Object.Properties.accountexpires -as [string]
                $AccountExpiresDate = ConvertTo-Date -accountExpires $AccountExpires

                $PasswordLastSet = $Object.Properties.pwdlastset -as [string]
                if ($PasswordLastSet) {
                    $PasswordLastSetDate = [datetime]::FromFileTime($PasswordLastSet)
                } else {
                    $PasswordLastSetDate = $null
                }
                $BadPasswordTime = $Object.Properties.badpasswordtime -as [string]
                if ($BadPasswordTime) {
                    $BadPasswordDate = [datetime]::FromFileTime($BadPasswordTime)
                } else {
                    $BadPasswordDate = $null
                }

                $ReturnObject['LastLogonDate'] = $LastLogonDate
                $ReturnObject['PasswordLastSet'] = $PasswordLastSetDate
                $ReturnObject['BadPasswordTime'] = $BadPasswordDate
                $ReturnObject['AccountExpiresDate'] = $AccountExpiresDate
                #>
                if ($Cache) {
                    $Script:CacheObjectsWinADObject[$TemporaryName] = [PSCustomObject] $ReturnObject
                    $Script:CacheObjectsWinADObject[$TemporaryName]
                } else {
                    [PSCustomObject] $ReturnObject
                }
            }
        }
    }
}