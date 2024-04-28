function Compare-InternalMissingObject {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $ForestInformation,
        [string] $Server,
        [string] $SourceDomain,
        [string[]] $TargetDomain
    )
    $Today = Get-Date -Hour 00 -Minute 00 -Second 00
    $Port = "3268"
    $Summary = [ordered] @{
        'Summary' = [PSCustomObject] @{
            Domain          = $SourceDomain
            MissingObject   = 0
            WrongGuid       = 0
            MissingObjectDC = [System.Collections.Generic.List[string]]::new()
            WrongGuidDC     = [System.Collections.Generic.List[string]]::new()
        }
    }
    $Source = [ordered] @{}
    [Array] $ListOU = @(
        Get-ADObject -Filter 'ObjectClass -eq "container"' -SearchScope OneLevel -Server $Server | Select-Object Name, DistinguishedName
        Get-ADOrganizationalUnit -Filter * -Server $Server -SearchScope OneLevel | Select-Object Name, DistinguishedName
    )
    [Array] $Objects = foreach ($OU in $ListOU.DistinguishedName) {
        Get-ADObject -Filter * -SearchBase $OU -Server $Server -Properties Name, DistinguishedName, ObjectGuid, WhenChanged, WhenCreated
    }
    foreach ($U in $Objects) {
        $Source[$U.DistinguishedName] = $U
    }
    $DomainControllers = foreach ($Domain in $TargetDomain) {
        $ForestInformation['DomainDomainControllers'][$Domain]
    }
    $Count = 0
    foreach ($DC in $DomainControllers) {
        $Count++
        if ($DC.IsGlobalCatalog) {
            Write-Color -Text "Processing [$Count/$($DomainControllers.Count)] ", $DC.HostName, " [IS GC]" -Color Yellow, White, Green
        } else {
            Write-Color -Text "Processing [$Count/$($DomainControllers.Count)] ", $DC.HostName, " [NOT GC]" -Color Yellow, White, Red
            continue
        }

        $Summary[$DC.HostName] = @{
            Missing   = [System.Collections.Generic.List[Object]]::new()
            WrongGuid = [System.Collections.Generic.List[Object]]::new()
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
            Get-ADObject -Filter * -SearchBase $OU -Server $QueryServer -Properties Name, DistinguishedName, ObjectGuid, WhenCreated, WhenChanged
        }
        foreach ($U in $UsersTarget) {
            if (-not $Source[$U.DistinguishedName]) {
                if ($U.WhenCreated -lt $Today) {
                    Add-Member -NotePropertyName 'GlobalCatalog' -NotePropertyValue $DC.Hostname -Force -InputObject $U
                    Add-Member -NotePropertyName 'Type' -NotePropertyValue 'Missing' -Force -InputObject $U
                    Add-Member -NotePropertyName 'Domain' -NotePropertyValue $SourceDomain -Force -InputObject $U
                    $Summary[$DC.Hostname]['Missing'].Add($U)
                    $Summary['Summary'].MissingObject++
                    if (-not $Summary['Summary'].MissingObjectDC.Contains($DC.Hostname)) {
                        $Summary['Summary'].MissingObjectDC.Add($DC.Hostname)
                    }
                } else {
                    Write-Color -Text "Processing [$Count/$($DCs.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " changed: ", $U.WhenChanged -Color Yellow, White, Yellow, White, Yellow
                }
            } else {
                if ($Source[$U.DistinguishedName].ObjectGUID.Guid -ne $U.ObjectGuid.Guid) {
                    Write-Color -Text "Processing [$Count/$($DCs.Count)][$CountOU/$($ListOU.Count)] ", $DC.HostName, " OU: ", $OU, " object: ", $U.DistinguishedName, " expected: ", $Source[$U.DistinguishedName].ObjectGUID.Guid, " got: ", $U.ObjectGuid.Guid -Color Yellow, White, Yellow, White, Red
                    Add-Member -NotePropertyName 'GlobalCatalog' -NotePropertyValue $DC.Hostname -Force -InputObject $U
                    Add-Member -NotePropertyName 'Type' -NotePropertyValue 'WrongGuid' -Force -InputObject $U
                    Add-Member -NotePropertyName 'Domain' -NotePropertyValue $SourceDomain -Force -InputObject $U
                    $Summary[$DC.Hostname]['WrongGuid'].Add($U)
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

