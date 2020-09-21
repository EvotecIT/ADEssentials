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
    An example

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)][Array] $Identity,
        [string] $DomainName,
        [pscredential] $Credential,
        #[switch] $IncludeDeletedObjects,
        [switch] $IncludeGroupMembership,
        [switch] $IncludeAllTypes,
        [switch] $AddType,
        [switch] $Cache
        #[switch] $ResolveType
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
            <#
            # Now we need to asses what kind of object is it
            # this is important as we accept SID, DN, ForeignSID, ForeignSecurityPrincipals or even DOMAIN\Account
            if (Test-IsDistinguishedName -Identity $Ident) {
                if ([Regex]::IsMatch($Ident, "S-\d-\d+-(\d+-){1,14}\d+")) {
                    # lets save it's value because we may need it if it's NT AUTHORITY
                    $TemporaryName = $Ident
                    $SIDConversion = Convert-Identity -Identity $Ident
                    $TemporaryDomainName = $SIDConversion.DomainName
                    $Ident = $SIDConversion.SID
                } else {
                    # We check if identity is DN and if so we provide Domain Name
                    $TemporaryDomainName = ConvertFrom-DistinguishedName -DistinguishedName $Ident -ToDomainCN
                }
            } elseif ($Ident -like "*\*") {
                # lets save it's value because we may need it if it's NT AUTHORITY
                $TemporaryName = $Ident
                $NetbiosConversion = Convert-Identity -Identity $Ident
                if ($NetbiosConversion.SID) {
                    $TemporaryDomainName = $NetbiosConversion.DomainName
                    $Ident = $NetbiosConversion.SID
                } else {
                    # It happens that sometimes things like EVOTECPL\Print Operators are not resolved, we try different method
                    $NetbiosConversion = ConvertFrom-NetbiosName -Identity $Ident
                    if ($NetbiosConversion.DomainName) {
                        $TemporaryDomainName = $NetbiosConversion.DomainName
                        $Ident = $NetbiosConversion.Name
                    }
                }
                # if no conditions happen, we let it as is
                # We do nothing, because we were not able to process DomainName so maybe something else is going on
            } elseif ([Regex]::IsMatch($Ident, "^S-\d-\d+-(\d+-){1,14}\d+$")) {
                # This is for converting sids, including foreign ones
                $SIDConversion = Convert-Identity -Identity $Ident
                if ($SIDConversion.DomainName) {
                    $TemporaryDomainName = $SIDConversion.DomainName
                    #$Ident = $NetbiosConversion.Name
                }
            }
            #>
            # if Domain Name is provided we don't check for anything as it's most likely already good Ident value
            if (-not $TemporrayDomainName) {
                $MatchRegex = [Regex]::Matches($Ident, "S-\d-\d+-(\d+-|){1,14}\d+")
                if ($MatchRegex.Success) {
                    $ResolvedIdentity = ConvertFrom-SID -SID $MatchRegex.Value
                    $TemporaryDomainName = $ResolvedIdentity.DomainName
                    $Ident = $MatchRegex.Value
                } elseif ($Ident -like '*\*') {
                    $ResolvedIdentity = Convert-Identity -Identity $Ident
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
                } elseif ($Ident -like '*@*') {
                    $CNConversion = $Ident -split '@', 2
                    $TemporaryDomainName = $CNConversion[1]
                    $Ident = $CNConversion[0]
                } elseif ($Ident -like '*DC=*') {
                    $DNConversion = ConvertFrom-DistinguishedName -DistinguishedName $Ident -ToDomainCN
                    $TemporaryDomainName = $DNConversion
                } elseif ($Ident -like '*.*') {
                    $ResolvedIdentity = Convert-Identity -Identity $Ident
                    if ($ResolvedIdentity.SID) {
                        $TemporaryDomainName = $ResolvedIdentity.DomainName
                        $Ident = $ResolvedIdentity.SID
                    } else {
                        $CNConversion = $Ident -split '\.', 2
                        $Ident = $CNConversion[0]
                        $TemporaryDomainName = $CNConversion[1]
                    }
                }

                <#
                if ([Regex]::IsMatch($Ident, "S-\d-\d+-(\d+-|){1,14}\d+") -or $Ident -like '*\*' -or $Ident -like "*@*" -or $Ident -like '*.*' -or $Ident -like '*DC=*') {
                    $ResolvedIdentity = Convert-Identity -Identity $Ident #-Verbose
                    if ($ResolvedIdentity.SID) {
                        #if (-not $TemporaryDomainName) {
                        $TemporaryDomainName = $ResolvedIdentity.DomainName
                        #}
                        $Ident = $ResolvedIdentity.SID
                    } else {
                        # It happens that sometimes things like EVOTECPL\Print Operators are not resolved, we try different method
                        if ($Ident -like "*\*") {
                            $NetbiosConversion = ConvertFrom-NetbiosName -Identity $Ident
                            if ($NetbiosConversion.DomainName) {
                                #if (-not $TemporaryDomainName) {
                                $TemporaryDomainName = $NetbiosConversion.DomainName
                                # }
                                $Ident = $NetbiosConversion.Name
                            }
                        } elseif ($Ident -like '*@*') {
                            $CNConversion = $Ident -split '@', 2
                            $Ident = $CNConversion[0]
                            #if (-not $TemporaryDomainName) {
                            $TemporaryDomainName = $CNConversion[1]
                            #}
                        } elseif ($Ident -like '*.*') {
                            $CNConversion = $Ident -split '\.', 2
                            $Ident = $CNConversion[0]
                            #if (-not $TemporaryDomainName) {
                            $TemporaryDomainName = $CNConversion[1]
                            #}
                        } else {
                            # if nothing helpeed we leave it as is
                        }
                    }
                }
                #>
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
                if ($ObjectClass -notin 'group', 'computer', 'user', 'foreignSecurityPrincipal' -and (-not $IncludeAllTypes)) {
                    Write-Warning "Get-WinADObject - Unsupported object ($Ident) of type $ObjectClass. Only user,computer,group and foreignSecurityPrincipal is supported."
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
                        if ($GroupMembers.Count -ne $Members.Count) {
                            #Write-Warning "Get-WinADObject - Weird. Members count different."
                        }
                        [Array] $Members = foreach ($Member in $GroupMembers) {
                            if ($Member.DistinguishedName) {
                                $Member.DistinguishedName
                            } elseif ($Member.DisplayName) {
                                $Member.DisplayName
                            } else {
                                $Member.Sid
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
                    <#
                    if ($TemporaryName) {
                        $DisplayName = $TemporaryName
                        # We try to make the output similar to what is reported by Get-ADGroupMember
                    } else {
                        # But sometimes 'NT AUTHORITY\INTERACTIVE' can be searched via SID which would not hit any conditions above
                        # So we try our suprt
                        $TemporaryName = Convert-Identity -Identity $Ident
                        if ($TemporaryName -is [string]) {
                            $DisplayName = $TemporaryName
                        }
                    }
                    #>
                    #if ($TemporaryName) {
                    #    $DisplayName = $TemporaryName
                    #} else {
                    $DisplayName = $ResolvedIdentity.Name
                    #}
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
                    Enabled             = if ($ObjectClass -eq 'group') { $null } else { $UAC -notcontains 'ACCOUNTDISABLE' }
                    PasswordNeverExpire = if ($ObjectClass -eq 'group') { $null } else { $UAC -contains 'DONT_EXPIRE_PASSWORD' }
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
                if ($AddType) {
                    if (-not $ResolvedIdentity) {
                        # This is purely to get special types
                        $ResolvedIdentity = ConvertFrom-SID -SID $ReturnObject['ObjectSID']
                    }
                    $ReturnObject['Type'] = $ResolvedIdentity.Type
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


<# Group properties
Name                           Value
----                           -----
usnchanged                     {13683028}
distinguishedname              {CN=Test Local Group,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz}
grouptype                      {-2147483644}
whencreated                    {27.08.2019 11:17:23}
samaccountname                 {Test Local Group}
objectsid                      {1 5 0 0 0 0 0 5 21 0 0 0 113 37 225 50 27 133 23 171 67 175 144 188 26 14 0 0}
instancetype                   {4}
adspath                        {LDAP://CN=Test Local Group,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz}
usncreated                     {7802330}
whenchanged                    {06.07.2020 09:45:54}
memberof                       {CN=GDS-TestGroup10,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz, CN=GDS-TestGroup4,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz}
member                         {CN=S-1-5-21-1928204107-2710010574-1926425344-500,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz, CN=S-1-5-21-1928204107-2710010574-1926425344-512,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz, CN=Test Test 2,OU=Users,OU=Production,DC=ad,DC=evotec,DC=pl, CN=GDS-TestGroup4,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz...}
cn                             {Test Local Group}
samaccounttype                 {536870912}
objectguid                     {237 65 154 255 148 47 114 77 149 87 67 41 17 75 245 116}
objectcategory                 {CN=Group,CN=Schema,CN=Configuration,DC=ad,DC=evotec,DC=xyz}
objectclass                    {top, group}
dscorepropagationdata          {10.06.2020 22:01:29, 10.06.2020 21:46:58, 10.06.2020 21:36:49, 15.03.2020 18:28:02...}
name                           {Test Local Group}
#>


<# User Properties
Name                           Value
----                           -----
msexchhidefromaddresslists     {True}
givenname                      {Przemysław}
codepage                       {0}
objectcategory                 {CN=Person,CN=Schema,CN=Configuration,DC=ad,DC=evotec,DC=xyz}
msds-externaldirectoryobjectid {User_e6a8f1cf-0874-4323-a12f-2bf51bb6dfdd}
dscorepropagationdata          {25.08.2020 21:06:50, 25.08.2020 20:06:50, 25.08.2020 19:06:50, 25.08.2020 18:06:50...}
msexchblockedsendershash       {166 15 235 0 208 246 3 1 78 214 53 5 67 135 205 5 254 172 122 6 37 72 82 8 108 110 221 9 24 41 233 12 107 189 240 12 244 213 71 18 242 154 55 19 113 138 60 19 176 124 206 20 147 165 11 21 190 226 32 23 12 56 177 23 183 188 237 24 13 31 140 32 196 43 59 34 157 32 84 37 198 4 49 39 105 170 151 39 67 128 233 41 73 0 12 42 31 18 237 42 224 196 36 43 203 74 147 43 100 228 13 45 53 12 94 45 185 84 7 46 154 39 142 46 216 152 203 49 141 181 209 49 101 119 239 49 209 189 226 52 37 177 222 53 222 36 205 55 164 116 215 55 85 4 76 56 53 152 100 57 220 39 19 65 149 167 103 65 140 103 233 71 54 217 1 73 165 16 61 73 61 17 163 73 30 79 79...
usnchanged                     {14157215}
instancetype                   {4}
mail                           {przemyslaw.klys@evotec.pl}
logoncount                     {48877}
mailnickname                   {przemyslaw.klys}
name                           {Przemysław Kłys}
badpasswordtime                {132385178870307938}
pwdlastset                     {132237277331029960}
extensionattribute5            {test2}
objectclass                    {top, person, organizationalPerson, user}
badpwdcount                    {0}
samaccounttype                 {805306368}
lastlogontimestamp             {132425105651705853}
usncreated                     {41006}
sn                             {Kłys}
msexchsafesendershash          {24 10 157 2 244 157 176 2 137 48 180 3 78 135 227 5 199 95 74 6 230 177 86 6 100 152 110 9 13 36 201 9 184 49 92 11 129 194 226 11 233 178 39 12 170 53 72 13 136 82 4 15 109 114 48 15 229 243 179 17 253 180 1 18 192 234 161 19 231 25 107 21 249 139 147 23 177 96 152 25 126 105 159 27 215 220 5 29 25 156 207 29 212 11 157 30 237 179 184 30 227 117 107 31 54 159 230 31 144 78 121 32 81 108 84 33 245 30 99 35 30 251 137 35 206 202 180 36 108 252 250 36 159 160 251 36 245 213 203 37 131 146 224 42 188 213 41 43 218 230 97 43 27 10 255 43 62 1 138 44 66 116 44 45 131 125 70 50 252 144 192 50 109 3 150 51 25 164 88 53 225 4 137 5...
proxyaddresses                 {smtp:przemyslaw.klys@evotec.xyz, SMTP:przemyslaw.klys@evotec.pl, smtp:pklys@evotec.xyz, smtp:pklys@evotec.pl...}
objectguid                     {42 147 40 179 127 133 241 74 185 208 53 87 138 162 13 34}
memberof                       {CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=xyz, CN=Enterprise Admins,CN=Users,DC=ad,DC=evotec,DC=xyz, CN=Schema Admins,CN=Users,DC=ad,DC=evotec,DC=xyz}
whencreated                    {20.05.2018 14:09:12}
adspath                        {LDAP://CN=Przemysław Kłys,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz}
useraccountcontrol             {66048}
cn                             {Przemysław Kłys}
countrycode                    {616}
co                             {Poland}
primarygroupid                 {513}
whenchanged                    {24.08.2020 15:54:14}
c                              {PL}
lockouttime                    {0}
lastlogon                      {132428529893921479}
distinguishedname              {CN=Przemysław Kłys,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz}
ms-ds-consistencyguid          {42 147 40 179 127 133 241 74 185 208 53 87 138 162 13 34}
directreports                  {CN=Testing 1,OU=Special,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz, CN=Test AD,OU=US,OU=ITR01,DC=ad,DC=evotec,DC=xyz, CN=Temporary Admin 1,OU=Users,OU=User,OU=SE1,OU=SE,OU=ITR01,DC=ad,DC=evotec,DC=xyz, CN=Test Przemyslaw Klys,OU=SE2,OU=SE,OU=ITR01,DC=ad,DC=evotec,DC=xyz...}
admincount                     {1}
managedobjects                 {CN=GDS-Test-1,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=pl, CN=GDS-TestGroup9,OU=Security,OU=Groups,OU=Production,DC=ad,DC=evotec,DC=xyz}
samaccountname                 {przemyslaw.klys}
objectsid                      {1 5 0 0 0 0 0 5 21 0 0 0 113 37 225 50 27 133 23 171 67 175 144 188 81 4 0 0}
lastlogoff                     {0}
extensionattribute4            {test}
displayname                    {Przemysław Kłys}
msds-site-affinity             {139 135 16 187 58 3 140 71 131 93 48 118 91 131 108 169 150 49 255 94 5 120 214 1, 79 88 72 121 160 123 99 70 147 49 185 139 0 197 241 168 127 190 15 207 235 165 213 1}
msds-keycredentiallink         {B:854:0002000020000133A552F2508CAC5C3D3ECF4CDA1414C87DFD9544C699E34D7A6D7582D7EC36A220000262390DFF3F290C897505B3B6F36AC36A9B2F32CBF66679CFBFB3C21AEF0CACC01B0103525341310008000003000000000100000000000000000000010001B0FB634056ED41754D49B02DF98B1F1AB82029119A190F0C17403BBC39BDDEE67D7F0E2A1E6466B188346CF4E8E8454A4E8ABBC9F7DABDF87079B70A651805F7784CC8ADE62F8B56F51F69E2E07B964EE4CA888C1D856B2CD3BC94B782582AA4A46E737067BC91AF54C03BE8D21A8D5634A51FC3DCE9E690F537D0F092D85B847C5DC90FC3074657B978BF53BEE7EE0A25CADA9C85CCD228AA2961D2A0EA7ED66F2ED0DD4AB62FDF9137E575700316CA96D53600A3C40A467BA9E8B4BEE04C3E86D3417C8138DF0EEA0D268AD18580C18...
accountexpires                 {9223372036854775807}
userprincipalname              {przemyslaw.klys@evotec.pl}
#>