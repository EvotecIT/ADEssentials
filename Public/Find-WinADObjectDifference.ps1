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
        [switch] $GlobalCatalog
    )

    $ForestInformation = Get-WinADForestDetails -Extended

    $Output = [ordered] @{
        List                = [System.Collections.Generic.List[Object]]::new()
        ListDetails         = [System.Collections.Generic.List[Object]]::new()
        ListDetailsReversed = [System.Collections.Generic.List[Object]]::new()
        ListSummary         = [System.Collections.Generic.List[Object]]::new()
    }

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

    )
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
        $ADObject = [ordered] @{
            DistinguishedName = $I
        }
        $ADObjectMinimal = [ordered] @{
            DistinguishedName     = $I
            ServersDifferent      = [System.Collections.Generic.List[Object]]::new()
            ServersDifferentCount = 0
            ServersSame           = [System.Collections.Generic.List[Object]]::new()
            ServersSameCount      = 0
            PropertiesSame        = [System.Collections.Generic.List[Object]]::new()
            PropertiesDifferent   = [System.Collections.Generic.List[Object]]::new()
        }
        $CachedReversedObjects[$I] = [ordered] @{}

        foreach ($Property in $Properties) {
            $ADObjectDetailsReversed = [ordered] @{
                DistinguishedName = $I
                Property = $Property
            }
            $CachedReversedObjects[$I][$Property] = $ADObjectDetailsReversed
        }

        $CountObject++

        $Count = 0
        foreach ($GC in $GCs) {
            $Count++
            Write-Verbose -Message "Find-WinADObjectDifference - Processing object [Object: $CountObject / $($Identity.Count)][DC: $Count / $($GCs.Count)] $($GC.HostName) for $I"
            # Query the specific object on each GC
            Try {
                if ($GlobalCatalog) {
                    $ObjectInfo = Get-ADObject -Identity $I -Server "$($GC.HostName):3268" -ErrorAction Stop -Properties $Properties
                } else {
                    $ObjectInfo = Get-ADObject -Identity $I -Server $GC.HostName -Properties * -ErrorAction Stop
                }
            } catch {
                $ObjectInfo = $null
                Write-Warning "Test-ADObject - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
            }
            if ($ObjectInfo) {
                if (-not $PrimaryObject) {
                    $PrimaryObject = $ObjectInfo
                }
                $ADObjectDetails = [ordered] @{
                    DistinguishedName = $I
                    Server            = $GC.HostName
                }
                foreach ($Property in $Properties) {
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
                        if ($Property -notin $ADObjectMinimal.PropertiesSame) {
                            $ADObjectMinimal.PropertiesSame.Add($Property)
                        }
                        if ($GC.HostName -notin $ADObjectMinimal.ServersSame) {
                            $ADObjectMinimal.ServersSame.Add($GC.HostName)
                        }
                    } elseif ($null -eq $PrimaryObject.$Property) {
                        $ADObject[$PropertyNameDiff].Add($GC.HostName)
                        if ($Property -notin $ADObjectMinimal.PropertiesDifferent) {
                            $ADObjectMinimal.PropertiesDifferent.Add($Property)
                        }
                        if ($GC.HostName -notin $ADObjectMinimal.ServersDifferent) {
                            $ADObjectMinimal.ServersDifferent.Add($GC.HostName)
                        }
                    } elseif ($null -eq $ObjectInfo.$Property) {
                        $ADObject[$PropertyNameDiff].Add($GC.HostName)
                        if ($Property -notin $ADObjectMinimal.PropertiesDifferent) {
                            $ADObjectMinimal.PropertiesDifferent.Add($Property)
                        }
                        if ($GC.HostName -notin $ADObjectMinimal.ServersDifferent) {
                            $ADObjectMinimal.ServersDifferent.Add($GC.HostName)
                        }
                    } else {
                        if ($ObjectInfo.$Property -ne $PrimaryObject.$Property) {
                            $ADObject[$PropertyNameDiff].Add($GC.HostName)
                            if ($Property -notin $ADObjectMinimal.PropertiesDifferent) {
                                $ADObjectMinimal.PropertiesDifferent.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectMinimal.ServersDifferent) {
                                $ADObjectMinimal.ServersDifferent.Add($GC.HostName)
                            }
                        } else {
                            $ADObject[$PropertyNameSame].Add($GC.HostName)
                            if ($Property -notin $ADObjectMinimal.PropertiesSame) {
                                $ADObjectMinimal.PropertiesSame.Add($Property)
                            }
                            if ($GC.HostName -notin $ADObjectMinimal.ServersSame) {
                                $ADObjectMinimal.ServersSame.Add($GC.HostName)
                            }
                        }
                    }
                    $ADObjectDetails[$Property] = $ObjectInfo.$Property

                    $CachedReversedObjects[$I][$Property][$GC.HostName] = $ObjectInfo.$Property
                }
                $Output.ListDetails.Add([PSCustomObject] $ADObjectDetails)
            }
        }
        $ADObjectMinimal.ServersDifferentCount = $ADObjectMinimal.ServersDifferent.Count
        $ADObjectMinimal.ServersSameCount = $ADObjectMinimal.ServersSame.Count
        $Output.List.Add([PSCustomObject] $ADObject)
        $Output.ListSummary.Add([PSCustomObject] $ADObjectMinimal)
        foreach ($Object in $CachedReversedObjects[$I].Keys) {
            $Output.ListDetailsReversed.Add([PSCustomObject] $CachedReversedObjects[$I][$Object])
        }
    }
    $Output
}