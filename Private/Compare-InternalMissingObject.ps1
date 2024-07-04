function Compare-InternalMissingObject {
    <#
    .SYNOPSIS
    Compares internal missing objects between domains.

    .DESCRIPTION
    This function compares internal missing objects between domains based on the provided ForestInformation, server, source domain, target domains, and limit per domain.

    .PARAMETER ForestInformation
    Specifies the forest information containing domain controllers.

    .PARAMETER Server
    Specifies the server to retrieve objects from.

    .PARAMETER SourceDomain
    Specifies the source domain to compare objects from.

    .PARAMETER TargetDomain
    Specifies the target domains to compare against.

    .PARAMETER LimitPerDomain
    Specifies the limit of objects to compare per domain.

    .EXAMPLE
    Compare-InternalMissingObject -ForestInformation $ForestInfo -Server "Server01" -SourceDomain "DomainA" -TargetDomain @("DomainB", "DomainC") -LimitPerDomain 100
    Compares internal missing objects between DomainA and DomainB, DomainC on Server01 with a limit of 100 objects per domain.

    .NOTES
    Ensure that the necessary permissions are in place to retrieve objects from the server.
    #>
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $ForestInformation,
        [string] $Server,
        [string] $SourceDomain,
        [string[]] $TargetDomain,
        [int] $LimitPerDomain
    )
    $Today = (Get-Date).AddHours(-24)
    $Port = "3268"
    $Summary = [ordered] @{
        'Summary' = [PSCustomObject] @{
            SourceServer    = $Server
            Domain          = $SourceDomain
            MissingObject   = 0
            WrongGuid       = 0
            MissingObjectDC = [System.Collections.Generic.List[string]]::new()
            WrongGuidDC     = [System.Collections.Generic.List[string]]::new()
            UniqueMissing   = [System.Collections.Generic.List[string]]::new()
            UniqueWrongGuid = [System.Collections.Generic.List[string]]::new()
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
    # Clearing the objects to free up memory
    $Objects = $null
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
            Missing         = [System.Collections.Generic.List[Object]]::new()
            MissingAtSource = [System.Collections.Generic.List[Object]]::new()
            WrongGuid       = [System.Collections.Generic.List[Object]]::new()
            # Ignored         = [System.Collections.Generic.List[Object]]::new()
            Errors          = [System.Collections.Generic.List[Object]]::new()
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
        # lets free up memory before we start again
        $UsersTarget = $null
        # $CacheTarget = [ordered] @{}
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
            # if ($U.DistinguishedName) {
            # $CacheTarget[$U.DistinguishedName] = $U
            # }
            if (-not $Source[$U.DistinguishedName]) {
                if ($U.WhenChanged -lt $Today) {
                    Write-Color -Text "Missing [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " changed: ", $U.WhenChanged -Color Yellow, White, Yellow, White, Yellow
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
                    if (-not $Summary['Summary'].UniqueMissing.Contains($U.DistinguishedName)) {
                        $Summary['Summary'].UniqueMissing.Add($U.DistinguishedName)
                    }
                }
            } else {
                if ($Source[$U.DistinguishedName].ObjectGUID.Guid -ne $U.ObjectGuid.Guid) {
                    Write-Color -Text "Wrong GUID [$Count/$($DomainControllers.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " expected: ", $Source[$U.DistinguishedName].ObjectGUID.Guid, " got: ", $U.ObjectGuid.Guid -Color Red, White, Yellow, White, Red
                    Write-Color -Text "[*] SourceDN: ", $Source[$U.DistinguishedName].DistinguishedName, " SourceName: ", $Source[$U.DistinguishedName].Name -Color Yellow, White, Yellow, White
                    Write-Color -Text "[*] SourceGuid: ", $Source[$U.DistinguishedName].ObjectGUID.Guid, " SourceWhenCreated: ", $Source[$U.DistinguishedName].WhenCreated, " SourceWhenChanged: ", $Source[$U.DistinguishedName].WhenChanged -Color Yellow, White, Yellow, White, Yellow, White
                    Write-Color -Text "[*] TargetDN: ", $U.DistinguishedName, " TargetName: ", $U.Name -Color Yellow, White, Yellow, White
                    Write-Color -Text "[*] TargetGuid: ", $U.ObjectGuid.Guid, " TargetWhenCreated: ", $U.WhenCreated, " TargetWhenChanged: ", $U.WhenChanged -Color Yellow, White, Yellow, White, Yellow, White

                    try {
                        $TryToFind = Get-ADObject -Filter "ObjectGuid -eq '$($Source[$U.DistinguishedName].ObjectGUID.Guid)'" -Server $QueryServer -Properties Name, DistinguishedName, ObjectGuid, WhenCreated, WhenChanged -ErrorAction Stop
                    } catch {
                        $TryToFind = $null
                    }
                    if ($TryToFind) {
                        Write-Color -Text "[*] Found: ", $TryToFind.DistinguishedName, " Name: ", $TryToFind.Name -Color Yellow, White, Yellow, White
                        Write-Color -Text "[*] FoundGuid: ", $TryToFind.ObjectGuid.Guid, " FoundWhenCreated: ", $TryToFind.WhenCreated, " FoundWhenChanged: ", $TryToFind.WhenChanged -Color Yellow, White, Yellow, White, Yellow, White
                    }

                    if ($U.WhenCreated -gt $Today) {
                        # the object is too new to try and compare, as it could be it was just created/moved
                    } else {
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
                        if (-not $Summary['Summary'].UniqueWrongGuid.Contains($U.DistinguishedName)) {
                            $Summary['Summary'].UniqueWrongGuid.Add($U.DistinguishedName)
                        }
                    }
                }
            }
        }
        $UsersTarget = $null
    }
    # Clearing the objects to free up memory
    $Source = $null
    $Summary
}