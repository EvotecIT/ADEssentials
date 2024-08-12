function Find-WinADObjectDifference {
    <#
    .SYNOPSIS
    Finds the differences in Active Directory objects between two sets of objects.

    .DESCRIPTION
    This function compares two sets of Active Directory objects and identifies the differences between them.

    .PARAMETER Standard
    Specifies the standard parameter set for comparing Active Directory objects.

    .PARAMETER Identity
    Specifies the identities of the Active Directory objects to compare.

    .PARAMETER Forest
    Specifies the forest to search for the Active Directory objects.

    .PARAMETER ExcludeDomains
    Specifies the domains to exclude from the comparison.

    .PARAMETER IncludeDomains
    Specifies the domains to include in the comparison.

    .PARAMETER GlobalCatalog
    Indicates whether to use the global catalog for the comparison.

    .PARAMETER Properties
    Specifies the properties to include in the comparison.

    .PARAMETER AddProperties
    Specifies additional properties to include in the comparison.

    .EXAMPLE
    Find-WinADObjectDifference -Identity 'CN=User1,OU=Users,DC=domain,DC=com', 'CN=User2,OU=Users,DC=domain,DC=com' -Forest 'domain.com' -IncludeDomains 'domain.com' -Properties 'Name', 'Description'

    Compares 'User1' and 'User2' objects in the 'domain.com' forest, including only the 'Name' and 'Description' properties.

    .NOTES
    General notes
    #>
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

        [string[]] $Properties,
        [string[]] $AddProperties

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

    $ExcludeProperties = @(
        'MemberOf'
        'servicePrincipalName'
        'WhenChanged'
        'DistinguishedName'
        'uSNChanged'
        'uSNCreated'
    )

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
            #'memberOf'
            'facsimileTelephoneNumber'
            'givenName'
            'homePhone'
            'postalCode'
            'pager'
            'lastLogonTimestamp'
            'UserAccountControl', 'DisplayName', 'mailNickname', 'mail', 'ipPhone'
            'whenChanged'
            'whenCreated'
        )
    }
    if ($AddProperties) {
        $Properties += $AddProperties
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

        if (-not $I.DistinguishedName) {
            $DN = $I
        } else {
            $DN = $I.DistinguishedName
        }

        #if ($Modes -contains 'DetailsSummary') {
        $ADObjectDetailedDifferences = [ordered] @{
            DistinguishedName = $DN
        }
        #}
        #if ($Modes -contains 'Details') {
        $ADObjectSummary = [ordered] @{
            DistinguishedName     = $DN
            DifferentServers      = [System.Collections.Generic.List[Object]]::new()
            DifferentServersCount = 0
            DifferentProperties   = [System.Collections.Generic.List[Object]]::new()
            SameServers           = [System.Collections.Generic.List[Object]]::new()
            SameServersCount      = 0
            SameProperties        = [System.Collections.Generic.List[Object]]::new()
        }
        #}
        $CachedReversedObjects[$DN] = [ordered] @{}

        $ADObjectDetailsPerPropertyReversed = [ordered] @{
            DistinguishedName = $DN
            Property          = 'Status'
        }
        $CachedReversedObjects[$DN]['Status'] = $ADObjectDetailsPerPropertyReversed

        foreach ($Property in $Properties) {
            $ADObjectDetailsPerPropertyReversed = [ordered] @{
                DistinguishedName = $DN
                Property          = $Property
            }
            $CachedReversedObjects[$DN][$Property] = $ADObjectDetailsPerPropertyReversed
        }

        $CountObject++

        $Count = 0
        foreach ($GC in $GCs) {
            $Count++
            Write-Verbose -Message "Find-WinADObjectDifference - Processing object [Object: $CountObject / $($Identity.Count)][DC: $Count / $($GCs.Count)] $($GC.HostName) for $I"
            # Query the specific object on each GC
            if ($I -is [Microsoft.ActiveDirectory.Management.ADUser]) {
                Try {
                    if ($GlobalCatalog) {
                        $ObjectInfo = Get-ADUser -Identity $DN -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                    } else {
                        $ObjectInfo = Get-ADUser -Identity $DN -Server $GC.HostName -Properties $Properties -ErrorAction Stop
                    }
                } catch {
                    $ObjectInfo = $null
                    Write-Warning "Find-WinADObjectDifference - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                }
            } elseif ($I -is [Microsoft.ActiveDirectory.Management.ADComputer]) {
                Try {
                    if ($GlobalCatalog) {
                        $ObjectInfo = Get-ADComputer -Identity $DN -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                    } else {
                        $ObjectInfo = Get-ADComputer -Identity $DN -Server $GC.HostName -Properties $Properties -ErrorAction Stop
                    }
                } catch {
                    $ObjectInfo = $null
                    Write-Warning "Find-WinADObjectDifference - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                }
            } else {
                if ($I -is [string] -or $I.DistinguishedName) {
                    Try {
                        if ($GlobalCatalog) {
                            $ObjectInfo = Get-ADObject -Identity $DN -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                        } else {
                            $ObjectInfo = Get-ADObject -Identity $DN -Server $GC.HostName -Properties $Properties -ErrorAction Stop
                        }
                    } catch {
                        $ObjectInfo = $null
                        Write-Warning "Test-ADObject - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                        $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                    }
                } else {
                    $ObjectInfo = $null
                    Write-Warning "Test-ADObject - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                    $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
                }
            }
            if ($ObjectInfo) {
                if (-not $PrimaryObject) {
                    $PrimaryObject = $ObjectInfo
                }
                $ADObjectDetailsPerProperty = [ordered] @{
                    DistinguishedName = $DN
                    Server            = $GC.HostName
                    Status            = 'Exists'
                }
                #$CachedReversedObjects[$DN]['Status']['StatusComparison'] = $true
                $CachedReversedObjects[$DN]['Status'][$GC.HostName] = 'Exists'
                foreach ($Property in $Properties) {
                    #$CachedReversedObjects[$DN]['Status']['StatusComparison'] = $true
                    # Comparing WhenChanged is not needed, because it is special and will always be different
                    if ($Property -notin $ExcludeProperties) {
                        $PropertyNameSame = "$Property-Same"
                        $PropertyNameDiff = "$Property-Diff"
                        if (-not $ADObjectDetailedDifferences[$PropertyNameSame]) {
                            $ADObjectDetailedDifferences[$PropertyNameSame] = [System.Collections.Generic.List[Object]]::new()
                        }
                        if (-not $ADObjectDetailedDifferences[$PropertyNameDiff]) {
                            $ADObjectDetailedDifferences[$PropertyNameDiff] = [System.Collections.Generic.List[Object]]::new()
                        }
                        if ($Property -in 'MemberOf', 'servicePrincipalName') {
                            # this requires complicated logic for comparison

                        } elseif ($null -eq $($PrimaryObject.$Property) -and $null -eq ($ObjectInfo.$Property)) {
                            # Both are null, so it's the same
                            $ADObjectDetailedDifferences[$PropertyNameSame].Add($GC.HostName)
                            if ($Property -notin $ADObjectSummary.SameProperties) {
                                $ADObjectSummary.SameProperties.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectSummary.SameServers) {
                                $ADObjectSummary.SameServers.Add($GC.HostName)
                            }
                        } elseif ($null -eq $PrimaryObject.$Property) {
                            # PrimaryObject is null, but ObjectInfo is not, so it's different
                            $ADObjectDetailedDifferences[$PropertyNameDiff].Add($GC.HostName)
                            if ($Property -notin $ADObjectSummary.DifferentProperties) {
                                $ADObjectSummary.DifferentProperties.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectSummary.DifferentServers) {
                                $ADObjectSummary.DifferentServers.Add($GC.HostName)
                            }
                            # $CachedReversedObjects[$DN]['Status']['StatusComparison'] = $false
                        } elseif ($null -eq $ObjectInfo.$Property) {
                            # ObjectInfo is null, but PrimaryObject is not, so it's different
                            $ADObjectDetailedDifferences[$PropertyNameDiff].Add($GC.HostName)
                            if ($Property -notin $ADObjectSummary.DifferentProperties) {
                                $ADObjectSummary.DifferentProperties.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectSummary.DifferentServers) {
                                $ADObjectSummary.DifferentServers.Add($GC.HostName)
                            }
                            # $CachedReversedObjects[$DN]['Status']['StatusComparison'] = $false
                        } else {
                            if ($ObjectInfo.$Property -ne $PrimaryObject.$Property) {
                                # Both are not null, and they are different
                                $ADObjectDetailedDifferences[$PropertyNameDiff].Add($GC.HostName)
                                if ($Property -notin $ADObjectSummary.DifferentProperties) {
                                    $ADObjectSummary.DifferentProperties.Add($Property)
                                }
                                if ($GC.HostName -notin $ADObjectSummary.DifferentServers) {
                                    $ADObjectSummary.DifferentServers.Add($GC.HostName)
                                }
                                # $CachedReversedObjects[$DN]['Status']['StatusComparison'] = $false
                            } else {
                                # Both are not null, and they are the same
                                $ADObjectDetailedDifferences[$PropertyNameSame].Add($GC.HostName)
                                if ($Property -notin $ADObjectSummary.SameProperties) {
                                    $ADObjectSummary.SameProperties.Add($Property)
                                }
                                if ($GC.HostName -notin $ADObjectSummary.SameServers) {
                                    $ADObjectSummary.SameServers.Add($GC.HostName)
                                }
                            }
                        }
                    }
                    $ADObjectDetailsPerProperty[$Property] = $ObjectInfo.$Property
                    $CachedReversedObjects[$DN][$Property][$GC.HostName] = $ObjectInfo.$Property
                }
                $Output.ListDetails.Add([PSCustomObject] $ADObjectDetailsPerProperty)
            } else {
                if (-not $PrimaryObject) {
                    $PrimaryObject = $ObjectInfo
                }
                $ADObjectDetailsPerProperty = [ordered] @{
                    DistinguishedName = $DN
                    Server            = $GC.HostName
                    Status            = $ErrorValue
                }

                $ADObjectSummary.DifferentServers.Add($GC.HostName)

                $CachedReversedObjects[$DN]['Status'][$GC.HostName] = $ErrorValue
                #$CachedReversedObjects[$DN]['Status']['StatusComparison'] = $false
                foreach ($Property in $Properties) {
                    if ($Property -notin $ExcludeProperties) {
                        $ADObjectDetailsPerProperty[$Property] = $null
                        $CachedReversedObjects[$DN][$Property][$GC.HostName] = $ObjectInfo.$Property
                        if ($Property -notin $ADObjectSummary.DifferentProperties) {
                            $ADObjectSummary.DifferentProperties.Add($Property)
                        }
                        #$CachedReversedObjects[$DN][$Property]['StatusComparison'] = $false
                    }
                }
                $Output.ListDetails.Add([PSCustomObject] $ADObjectDetailsPerProperty)
            }
        }
        $ADObjectSummary.DifferentServersCount = $ADObjectSummary.DifferentServers.Count
        $ADObjectSummary.SameServersCount = $ADObjectSummary.SameServers.Count
        $Output.List.Add([PSCustomObject] $ADObjectDetailedDifferences)
        $Output.ListSummary.Add([PSCustomObject] $ADObjectSummary)
        foreach ($Object in $CachedReversedObjects[$DN].Keys) {
            $Output.ListDetailsReversed.Add([PSCustomObject] $CachedReversedObjects[$DN][$Object])
        }
    }
    $Output
}