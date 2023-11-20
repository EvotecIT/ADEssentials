function Find-WinADObjectDifference {
    [CmdletBinding(DefaultParameterSetName = 'Standard')]
    param(
        [Parameter(ParameterSetName = 'Standard', Mandatory)]
        [Array] $Identity,

        [Parameter(ParameterSetName = 'Standard')]
        [alias('ForestName')][string] $Forest,

        [Parameter(ParameterSetName = 'Standard')]
        [string[]] $ExcludeDomains,

        [Parameter(ParameterSetName = 'Standard')]
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,

        [Parameter(ParameterSetName = 'Standard')]
        [switch] $GlobalCatalog,

        [string[]] $Properties

        # [ValidateSet(
        #     'Summary',
        #     'DetailsPerProperty',
        #     'DetailsPerServer',
        #     'DetailsSummary'
        # )][string[]] $Modes
    )

    $ForestInformation = Get-WinADForestDetails -Extended

    $Output = [ordered] @{
        List                = [System.Collections.Generic.List[Object]]::new()
        ListDetails         = [System.Collections.Generic.List[Object]]::new()
        ListDetailsReversed = [System.Collections.Generic.List[Object]]::new()
        ListSummary         = [System.Collections.Generic.List[Object]]::new()
    }

    if (-not $Properties) {
        # $PropertiesUser = @(
        #     'AccountExpirationDate'
        #     'accountExpires'
        #     'AccountLockoutTime'
        #     'AccountNotDelegated'
        #     'adminCount'
        #     'AllowReversiblePasswordEncryption'
        #     'CannotChangePassword'
        #     'City'
        #     'codePage'
        #     'Company'
        #     'Country'
        #     'countryCode'
        #     'Department'
        #     'Description'
        #     'DisplayName'
        #     'DistinguishedName'
        #     'Division'
        #     'EmailAddress'
        #     'EmployeeID'
        #     'EmployeeNumber'
        #     'Enabled'
        #     'GivenName'
        #     'HomeDirectory'
        #     'HomedirRequired'
        #     'Initials'
        #     'instanceType'
        #     'KerberosEncryptionType'
        #     'LastLogonDate'
        #     'mail'
        #     'mailNickname'
        #     'Manager'
        #     'MemberOf'
        #     'MobilePhone'
        #     'Name'
        #     'ObjectClass'
        #     'Office'
        #     'OfficePhone'
        #     'Organization'
        #     'OtherName'
        #     'PasswordExpired'
        #     'PasswordLastSet'
        #     'PasswordNeverExpires'
        #     'PasswordNotRequired'
        #     'POBox'
        #     'PostalCode'
        #     'PrimaryGroup'
        #     'primaryGroupID'
        #     'PrincipalsAllowedToDelegateToAccount'
        #     'ProfilePath'
        #     'protocolSettings'
        #     'proxyAddresses'
        #     'pwdLastSet'
        #     'SamAccountName'
        #     'sAMAccountType'
        #     'ScriptPath'
        #     'sDRightsEffective'
        #     'ServicePrincipalNames'
        #     'showInAddressBook'
        #     'SID'
        #     'SIDHistory'
        #     'SmartcardLogonRequired'
        #     'State'
        #     'StreetAddress'
        #     'Surname'
        #     'Title'
        #     'TrustedForDelegation'
        #     'TrustedToAuthForDelegation'
        #     'UseDESKeyOnly'
        #     'userAccountControl'
        #     'UserPrincipalName'
        #     'uSNChanged'
        #     'uSNCreated'
        #     'whenChanged'
        #     'whenCreated'
        # )

        $Properties = @(
            'company'
            'department'
            'Description'
            'info'
            'l'
            for ($i = 1; $i -le 15; $i++) {
                "extensionAttribute$i"
            }
            'manager'
            'memberOf'
            'facsimileTelephoneNumber'
            'givenName'
            'homePhone'
            'postalCode'
            'pager'
            'UserAccountControl', 'DisplayName', 'mailNickname', 'mail', 'ipPhone'
            'WhenChanged'
        )
    }
    $Properties = $Properties | Sort-Object -Unique

    if ($GlobalCatalog) {
        [Array] $GCs = foreach ($DC in $ForestInformation.ForestDomainControllers) {
            if ($DC.IsGlobalCatalog) {
                $DC
            }
        }
    } else {
        $DomainFromIdentity = ConvertFrom-DistinguishedName -DistinguishedName $Identity[0] -ToDomainCN
        [Array] $GCs = foreach ($DC in $ForestInformation.ForestDomainControllers) {
            if ($DC.Domain -eq $DomainFromIdentity) {
                $DC
            }
        }
    }

    $CountObject = 0
    $CachedReversedObjects = [ordered] @{}

    foreach ($I in $Identity) {
        $PrimaryObject = $null

        #if ($Modes -contains 'DetailsSummary') {
            $ADObject = [ordered] @{
                DistinguishedName = $I
            }
        #}
        #if ($Modes -contains 'Details') {
            $ADObjectMinimal = [ordered] @{
                DistinguishedName     = $I
                DifferentServers      = [System.Collections.Generic.List[Object]]::new()
                DifferentServersCount = 0
                DifferentProperties   = [System.Collections.Generic.List[Object]]::new()
                SameServers           = [System.Collections.Generic.List[Object]]::new()
                SameServersCount      = 0
                SameProperties        = [System.Collections.Generic.List[Object]]::new()
            }
        #}
        $CachedReversedObjects[$I] = [ordered] @{}

        $ADObjectDetailsReversed = [ordered] @{
            DistinguishedName = $I
            Property          = 'Status'
        }
        $CachedReversedObjects[$I]['Status'] = $ADObjectDetailsReversed

        foreach ($Property in $Properties) {
            $ADObjectDetailsReversed = [ordered] @{
                DistinguishedName = $I
                Property          = $Property
            }
            $CachedReversedObjects[$I][$Property] = $ADObjectDetailsReversed
        }

        $CountObject++

        $Count = 0
        foreach ($GC in $GCs) {
            $Count++
            Write-Verbose -Message "Find-WinADObjectDifference - Processing object [Object: $CountObject / $($Identity.Count)][DC: $Count / $($GCs.Count)] $($GC.HostName) for $I"
            # Query the specific object on each GC
            if ($I -is [Microsoft.ActiveDirectory.Management.ADUser]) {
                $DN = $I.DistinguishedName
                Try {
                    if ($GlobalCatalog) {
                        $ObjectInfo = Get-ADUser -Identity $I.DistinguishedName -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                    } else {
                        $ObjectInfo = Get-ADUser -Identity $I.DistinguishedName -Server $GC.HostName -Properties * -ErrorAction Stop
                    }
                } catch {
                    $ObjectInfo = $null
                    Write-Warning "Find-WinADObjectDifference - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                }
            } elseif ($I -is [Microsoft.ActiveDirectory.Management.ADComputer]) {
                $DN = $I.DistinguishedName
                Try {
                    if ($GlobalCatalog) {
                        $ObjectInfo = Get-ADComputer -Identity $I.DistinguishedName -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                    } else {
                        $ObjectInfo = Get-ADComputer -Identity $I.DistinguishedName -Server $GC.HostName -Properties * -ErrorAction Stop
                    }
                } catch {
                    $ObjectInfo = $null
                    Write-Warning "Find-WinADObjectDifference - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                }
            } else {
                if ($I -is [string] -or $I.DistinguishedName) {
                    if (-not $I.DistinguishedName) {
                        $DN = $I
                    } else {
                        $DN = $I.DistinguishedName
                    }
                    Try {
                        if ($GlobalCatalog) {
                            $ObjectInfo = Get-ADObject -Identity $DN -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                        } else {
                            $ObjectInfo = Get-ADObject -Identity $DN -Server $GC.HostName -Properties * -ErrorAction Stop
                        }
                    } catch {
                        $ObjectInfo = $null
                        Write-Warning "Test-ADObject - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                        $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                    }
                } else {
                    $ObjectInfo = $null
                    Write-Warning "Test-ADObject - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    #$ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                   # return
                }
            }
            if ($ObjectInfo) {
                if (-not $PrimaryObject) {
                    $PrimaryObject = $ObjectInfo
                }
                $ADObjectDetails = [ordered] @{
                    DistinguishedName = $DN
                    Server            = $GC.HostName
                    StatusMessage     = 'Exists'
                }
                $CachedReversedObjects[$I]['Status'][$GC.HostName] = 'Exists'
                foreach ($Property in $Properties) {
                    # Comparing WhenChanged is not needed, because it is special and will always be different
                    if ($Property -notin 'WhenChanged') {
                        $PropertyNameSame = "$Property-Same"
                        $PropertyNameDiff = "$Property-Diff"
                        if (-not $ADObject[$PropertyNameSame]) {
                            $ADObject[$PropertyNameSame] = [System.Collections.Generic.List[Object]]::new()
                        }
                        if (-not $ADObject[$PropertyNameDiff]) {
                            $ADObject[$PropertyNameDiff] = [System.Collections.Generic.List[Object]]::new()
                        }
                        if ($Property -eq 'MemberOf') {

                        } elseif ($null -eq $($PrimaryObject.$Property) -and $null -eq ($ObjectInfo.$Property)) {
                            $ADObject[$PropertyNameSame].Add($GC.HostName)
                            if ($Property -notin $ADObjectMinimal.SameProperties) {
                                $ADObjectMinimal.SameProperties.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectMinimal.SameServers) {
                                $ADObjectMinimal.SameServers.Add($GC.HostName)
                            }
                        } elseif ($null -eq $PrimaryObject.$Property) {
                            $ADObject[$PropertyNameDiff].Add($GC.HostName)
                            if ($Property -notin $ADObjectMinimal.DifferentProperties) {
                                $ADObjectMinimal.DifferentProperties.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectMinimal.DifferentServers) {
                                $ADObjectMinimal.DifferentServers.Add($GC.HostName)
                            }
                        } elseif ($null -eq $ObjectInfo.$Property) {
                            $ADObject[$PropertyNameDiff].Add($GC.HostName)
                            if ($Property -notin $ADObjectMinimal.DifferentProperties) {
                                $ADObjectMinimal.DifferentProperties.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectMinimal.DifferentServers) {
                                $ADObjectMinimal.DifferentServers.Add($GC.HostName)
                            }
                        } else {
                            if ($ObjectInfo.$Property -ne $PrimaryObject.$Property) {
                                $ADObject[$PropertyNameDiff].Add($GC.HostName)
                                if ($Property -notin $ADObjectMinimal.DifferentProperties) {
                                    $ADObjectMinimal.DifferentProperties.Add($Property)
                                }
                                if ($GC.HostName -notin $ADObjectMinimal.DifferentServers) {
                                    $ADObjectMinimal.DifferentServers.Add($GC.HostName)
                                }
                            } else {
                                $ADObject[$PropertyNameSame].Add($GC.HostName)
                                if ($Property -notin $ADObjectMinimal.SameProperties) {
                                    $ADObjectMinimal.SameProperties.Add($Property)
                                }
                                if ($GC.HostName -notin $ADObjectMinimal.SameServers) {
                                    $ADObjectMinimal.SameServers.Add($GC.HostName)
                                }
                            }
                        }
                    }
                    $ADObjectDetails[$Property] = $ObjectInfo.$Property
                    $CachedReversedObjects[$I][$Property][$GC.HostName] = $ObjectInfo.$Property
                }
                $Output.ListDetails.Add([PSCustomObject] $ADObjectDetails)
            } else {
                if (-not $PrimaryObject) {
                    $PrimaryObject = $ObjectInfo
                }
                $ADObjectDetails = [ordered] @{
                    DistinguishedName = $DN
                    Server            = $GC.HostName
                    Status            = $ErrorValue
                }

                $ADObjectMinimal.DifferentServers.Add($GC.HostName)

                $CachedReversedObjects[$I]['Status'][$GC.HostName] = $ErrorValue
                foreach ($Property in $Properties) {
                    $ADObjectDetails[$Property] = $null
                    $CachedReversedObjects[$I][$Property][$GC.HostName] = $ObjectInfo.$Property

                    $ADObjectMinimal.DifferentProperties.Add($Property)
                }
                $Output.ListDetails.Add([PSCustomObject] $ADObjectDetails)
            }
        }
        $ADObjectMinimal.DifferentServersCount = $ADObjectMinimal.DifferentServers.Count
        $ADObjectMinimal.SameServersCount = $ADObjectMinimal.SameServers.Count
        $Output.List.Add([PSCustomObject] $ADObject)
        $Output.ListSummary.Add([PSCustomObject] $ADObjectMinimal)
        foreach ($Object in $CachedReversedObjects[$I].Keys) {
            $Output.ListDetailsReversed.Add([PSCustomObject] $CachedReversedObjects[$I][$Object])
        }
    }
    $Output
}