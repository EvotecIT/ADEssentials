function Get-WinADOrganization {
    [cmdletBinding()]
    param(

    )
    $ForestInformation = Get-WinADForestDetails
    $Organization = [ordered] @{
        Forest                = [System.Collections.Generic.List[PSCustomObject]]::new()
        Domains               = [System.Collections.Generic.List[PSCustomObject]]::new()
        OrganizationalUnits   = [ordered] @{}
        Objects               = [ordered] @{}
        ObjectsCount          = [ordered] @{}
        ObjectsUsersCount     = [ordered] @{}
        ObjectsComputersCount = [ordered] @{}
        ObjectsGroupsCount    = [ordered] @{}
        ObjectsContactsCount  = [ordered] @{}
        ObjectsOtherCount     = [ordered] @{}
    }

    foreach ($Domain in $ForestInformation.Domains) {
        $CurrentDomainDN = ConvertTo-DistinguishedName -CanonicalName $Domain -ToDomain

        $DomainInformation = [ordered] @{
            Domain                   = $Domain
            Type                     = 'Domain'
            DistinguishedName        = $CurrentDomainDN
            Name                     = $Domain
            OrganizationalUnits      = @()
            OrganizationalUnitsCount = 0
            ObjectsCount             = 0
            ObjectsUsersCount        = 0
            ObjectsComputersCount    = 0
            ObjectsGroupsCount       = 0
            ObjectsContactsCount     = 0
            ObjectsOtherCount        = 0
        }

        $ValidObjectClasses = @(
            'user', 'computer', 'group', 'contact',
            'msDS-GroupManagedServiceAccount', 'msDS-ManagedServiceAccount',
            'printer', 'volume', 'foreignSecurityPrincipal',
            'inetOrgPerson', 'sharedFolder'
        )

        $Filter = ($ValidObjectClasses | ForEach-Object { "(ObjectClass -eq '$_')" }) -join ' -or '

        $getADObjectSplat = @{
            Filter     = $Filter
            Server     = $ForestInformation['QueryServers'][$Domain].HostName[0]
            Properties = 'DistinguishedName', 'CanonicalName', 'ObjectClass', 'Name'
        }

        $Objects = Get-ADObject @getADObjectSplat

        foreach ($Object in $Objects) {
            $DN = ConvertFrom-DistinguishedName -DistinguishedName $Object.DistinguishedName -ToOrganizationalUnit
            if (-not $Organization['Objects'][$DN]) {
                $Organization['Objects'][$DN] = [System.Collections.Generic.List[PSCustomObject]]::new()
                $Organization['ObjectsCount'][$DN] = 0
                $Organization['ObjectsUsersCount'][$DN] = 0
                $Organization['ObjectsComputersCount'][$DN] = 0
                $Organization['ObjectsGroupsCount'][$DN] = 0
                $Organization['ObjectsContactsCount'][$DN] = 0
                $Organization['ObjectsOtherCount'][$DN] = 0
            }
            $Organization['Objects'][$DN].Add($Object)
            if ($Object.ObjectClass -eq 'user') {
                $Organization['ObjectsUsersCount'][$DN]++
                $DomainInformation['ObjectsUsersCount']++
            } elseif ($Object.ObjectClass -eq 'computer') {
                $Organization['ObjectsComputersCount'][$DN]++
                $DomainInformation['ObjectsComputersCount']++
            } elseif ($Object.ObjectClass -eq 'group') {
                $Organization['ObjectsGroupsCount'][$DN]++
                $DomainInformation['ObjectsGroupsCount']++
            } elseif ($Object.ObjectClass -eq 'contact') {
                $Organization['ObjectsContactsCount'][$DN]++
                $DomainInformation['ObjectsContactsCount']++
            } else {
                $Organization['ObjectsOtherCount'][$DN]++
            }
            $Organization['ObjectsCount'][$DN]++
            $DomainInformation['ObjectsCount']++
        }

        $Organization.Domains.Add([PSCustomObject]$DomainInformation)

        $Organization.OrganizationalUnits[$Domain] = @(
            $DomainOUs = Get-ADOrganizationalUnit -Filter "*" -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -Properties DistinguishedName, CanonicalName
            foreach ($OU in $DomainOUs) {
                $SubOus = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit
                [Array] $OutputSubOu = @(
                    if ($SubOus) {
                        $SubOus
                    }
                    $CurrentDomainDN
                )
                $OUData = [PSCustomObject]@{
                    Domain                   = $Domain
                    Type                     = 'OrganizationalUnit'
                    DistinguishedName        = $OU.DistinguishedName
                    Name                     = $OU.Name
                    OrganizationalUnits      = $OutputSubOu
                    OrganizationalUnitsCount = $OutputSubOu.Count
                    ObjectsCount             = $Organization['Objects'][$OU.DistinguishedName].Count
                    ObjectsUsersCount        = if ($null -eq $Organization['ObjectsUsersCount'][$OU.DistinguishedName]) { 0 } else { $Organization['ObjectsUsersCount'][$OU.DistinguishedName] }
                    ObjectsComputersCount    = if ($null -eq $Organization['ObjectsComputersCount'][$OU.DistinguishedName]) { 0 } else { $Organization['ObjectsComputersCount'][$OU.DistinguishedName] }
                    ObjectsGroupsCount       = if ($null -eq $Organization['ObjectsGroupsCount'][$OU.DistinguishedName]) { 0 } else { $Organization['ObjectsGroupsCount'][$OU.DistinguishedName] }
                    ObjectsContactsCount     = if ($null -eq $Organization['ObjectsContactsCount'][$OU.DistinguishedName]) { 0 } else { $Organization['ObjectsContactsCount'][$OU.DistinguishedName] }
                    ObjectsOtherCount        = if ($null -eq $Organization['ObjectsOtherCount'][$OU.DistinguishedName]) { 0 } else { $Organization['ObjectsOtherCount'][$OU.DistinguishedName] }
                }

                $OUData
            }
        )
    }
    $Organization
}