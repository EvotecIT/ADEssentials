function Compare-InternalMissingObject {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $ForestInformation,
        [string] $Server,
        [string] $SourceDomain,
        [string[]] $TargetDomain,
        [int] $LimitPerDomain
    )
    $Today = (Get-Date).AddHours(-6)
    $Port = "3268"
    $Summary = [ordered] @{
        'Summary' = [PSCustomObject] @{
            Domain          = $SourceDomain
            MissingObject   = 0
            WrongGuid       = 0
            MissingObjectDC = [System.Collections.Generic.List[string]]::new()
            WrongGuidDC     = [System.Collections.Generic.List[string]]::new()
            Ignored         = 0
            IgnoredDC       = [System.Collections.Generic.List[string]]::new()
        }
    }
    $Source = [ordered] @{}
    Write-Color -Text "Getting objects from the source domain [$SourceDomain] on server [$Server]." -Color Yellow, White
    try {
        [Array] $ListOU = @(
            Get-ADObject -Filter 'ObjectClass -eq "container"' -SearchScope OneLevel -Server $Server -ErrorAction Stop | Select-Object Name, DistinguishedName
            Get-ADOrganizationalUnit -Filter * -Server $Server -SearchScope OneLevel -ErrorAction Stop | Select-Object Name, DistinguishedName
        )
        [Array] $Objects = foreach ($OU in $ListOU.DistinguishedName) {
            Get-ADObject -Filter * -SearchBase $OU -Server $Server -Properties Name, DistinguishedName, ObjectGuid, WhenChanged -ErrorAction Stop
        }
    } catch {
        Write-Color -Text "Couldn't get the objects from the source domain [$SourceDomain] on server [$Server].", " Error: ", $_.Exception.Message -Color Red, White, Red, White
        return $Source
    }
    foreach ($U in $Objects) {
        $Source[$U.DistinguishedName] = $U
    }
    $DomainControllers = foreach ($Domain in $TargetDomain) {
        if ($LimitPerDomain -gt 0) {
            for ($i = 0; $i -le $ForestInformation['DomainDomainControllers'][$Domain].Count; $i++) {
                if ($i -ge $LimitPerDomain) {
                    break
                }
                $ForestInformation['DomainDomainControllers'][$Domain][$i]
            }
        } else {
            $ForestInformation['DomainDomainControllers'][$Domain]
        }
    }
    $Count = 0
    :nextDC foreach ($DC in $DomainControllers) {
        $Count++
        $Summary[$DC.HostName] = @{
            Missing   = [System.Collections.Generic.List[Object]]::new()
            WrongGuid = [System.Collections.Generic.List[Object]]::new()
            Ignored   = [System.Collections.Generic.List[Object]]::new()
            Errors    = [System.Collections.Generic.List[string]]::new()
        }
        if ($DC.HostName -eq $Server) {
            Write-Color -Text "Skipping [$Count/$($DomainControllers.Count)] ", $DC.HostName, " [Same as Source]" -Color Yellow, White, Green
            continue
        }
        if ($DC.IsGlobalCatalog) {
            Write-Color -Text "Processing [$Count/$($DomainControllers.Count)] ", $DC.HostName, " [Is Global Catalog]" -Color Yellow, White, Green
        } else {
            Write-Color -Text "Processing [$Count/$($DomainControllers.Count)] ", $DC.HostName, " [Is not Global Catalog]" -Color Yellow, White, Red
            continue
        }

        $CountOU = 0
        [Array] $UsersTarget = foreach ($OU in $ListOU.DistinguishedName) {
            $CountOU++
            Write-Color -Text "Processing [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU -Color Yellow, White, Yellow, White
            if ($Port) {
                $QueryServer = "$($DC.HostName):$Port"
            } else {
                $QueryServer = $DC.HostName
            }
            try {
                Get-ADObject -Filter * -SearchBase $OU -Server $QueryServer -Properties Name, DistinguishedName, ObjectGuid, WhenCreated, WhenChanged -ErrorAction Stop
            } catch {
                Write-Color -Text "Couldn't get the objects from the target domain [$SourceDomain] on server [$QueryServer].", " Error: ", $_.Exception.Message -Color Red, White, Red, White
                $Summary[$DC.Hostname]['Errors'].Add(
                    [PSCustomObject] @{
                        GlobalCatalog = $DC.Hostname
                        Domain        = $SourceDomain
                        Object        = $OU
                        Error         = $_.Exception.Message
                    }
                )
                continue nextDC
            }
        }
        foreach ($U in $UsersTarget) {
            if (-not $Source[$U.DistinguishedName]) {
                if ($U.WhenChanged -lt $Today) {
                    Write-Color -Text "Missing [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " changed: ", $U.WhenChanged -Color Yellow, White, Yellow, White, Yellow
                    # Add-Member -NotePropertyName 'GlobalCatalog' -NotePropertyValue $DC.Hostname -Force -InputObject $U
                    # Add-Member -NotePropertyName 'Type' -NotePropertyValue 'Missing' -Force -InputObject $U
                    # Add-Member -NotePropertyName 'Domain' -NotePropertyValue $SourceDomain -Force -InputObject $U

                    $Summary[$DC.Hostname]['Missing'].Add(
                        [PSCustomObject] @{
                            GlobalCatalog     = $DC.Hostname
                            Type              = 'Missing'
                            Domain            = $SourceDomain
                            DistinguishedName = $U.DistinguishedName
                            Name              = $U.Name
                            ObjectClass       = $U.ObjectClass
                            ObjectGuid        = $U.ObjectGuid.Guid
                            WhenCreated       = $U.WhenCreated
                            WhenChanged       = $U.WhenChanged
                        }
                    )
                    $Summary['Summary'].MissingObject++
                    if (-not $Summary['Summary'].MissingObjectDC.Contains($DC.Hostname)) {
                        $Summary['Summary'].MissingObjectDC.Add($DC.Hostname)
                    }
                } else {
                    # the object is too new to try and compare, as it could be it was just created/moved
                    #Write-Color -Text "Ignoring [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " changed: ", $U.WhenChanged -Color Yellow, White, Yellow, White, Yellow
                    # Add-Member -NotePropertyName 'GlobalCatalog' -NotePropertyValue $DC.Hostname -Force -InputObject $U
                    # Add-Member -NotePropertyName 'Type' -NotePropertyValue 'Ignored' -Force -InputObject $U
                    # Add-Member -NotePropertyName 'Domain' -NotePropertyValue $SourceDomain -Force -InputObject $U
                    $Summary[$DC.Hostname]['Ignored'].Add(
                        [PSCustomObject] @{
                            GlobalCatalog     = $DC.Hostname
                            Type              = 'Ignored'
                            Domain            = $SourceDomain
                            DistinguishedName = $U.DistinguishedName
                            Name              = $U.Name
                            ObjectClass       = $U.ObjectClass
                            ObjectGuid        = $U.ObjectGuid.Guid
                            WhenCreated       = $U.WhenCreated
                            WhenChanged       = $U.WhenChanged
                        }
                    )
                    $Summary['Summary'].Ignored++
                    if (-not $Summary['Summary'].IgnoredDC.Contains($DC.Hostname)) {
                        $Summary['Summary'].IgnoredDC.Add($DC.Hostname)
                    }
                }
            } else {
                if ($Source[$U.DistinguishedName].ObjectGUID.Guid -ne $U.ObjectGuid.Guid) {
                    Write-Color -Text "WrongGUID [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " expected: ", $Source[$U.DistinguishedName].ObjectGUID.Guid, " got: ", $U.ObjectGuid.Guid -Color Red, White, Yellow, White, Red
                    #Add-Member -NotePropertyName 'GlobalCatalog' -NotePropertyValue $DC.Hostname -Force -InputObject $U
                    #Add-Member -NotePropertyName 'Type' -NotePropertyValue 'WrongGuid' -Force -InputObject $U
                    #Add-Member -NotePropertyName 'Domain' -NotePropertyValue $SourceDomain -Force -InputObject $U

                    try {
                        $TryToFind = Get-ADObject -Filter "ObjectGuid -eq '$($Source[$U.DistinguishedName].ObjectGUID.Guid)'" -Server $Server -Properties Name, DistinguishedName, ObjectGuid, WhenCreated, WhenChanged -ErrorAction Stop
                    } catch {
                        $TryToFind = $null
                    }
                    if ($TryToFind) {
                        Write-Color -Text "WrongGUID [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " expected: ", $Source[$U.DistinguishedName].ObjectGUID.Guid, " got: ", $U.ObjectGuid.Guid, " found: ", $TryToFind.DistinguishedName -Color Red, White, Yellow, White, Red
                    }

                    $Summary[$DC.Hostname]['WrongGuid'].Add(
                        [PSCustomObject] @{
                            GlobalCatalog           = $DC.Hostname
                            Type                    = 'WrongGuid'
                            Domain                  = $SourceDomain
                            DistinguishedName       = $U.DistinguishedName
                            Name                    = $U.Name
                            ObjectClass             = $U.ObjectClass
                            ObjectGuid              = $U.ObjectGuid.Guid
                            WhenCreated             = $U.WhenCreated
                            WhenChanged             = $U.WhenChanged
                            SourceObjectName        = $Source[$U.DistinguishedName].Name
                            SourceObjectDN          = $Source[$U.DistinguishedName].DistinguishedName
                            SourceObjectGuid        = $Source[$U.DistinguishedName].ObjectGUID.Guid
                            SourceObjectWhenCreated = $Source[$U.DistinguishedName].WhenCreated
                            SourceObjectWhenChanged = $Source[$U.DistinguishedName].WhenChanged
                            NewDistinguishedName    = $TryToFind.DistinguishedName
                        }
                    )
                    $Summary['Summary'].WrongGuid++
                    if (-not $Summary['Summary'].WrongGuidDC.Contains($DC.Hostname)) {
                        $Summary['Summary'].WrongGuidDC.Add($DC.Hostname)
                    }
                }
            }
        }
    }
    $Summary
}

