function Get-WinADOrganization {
    <#
    .SYNOPSIS
    Retrieves detailed information about the Active Directory organizational structure.

    .DESCRIPTION
    Gathers data about domains, organizational units (OUs), and the objects within them across the AD forest.
    It calculates both direct object counts for each container (Domain/OU) and total object counts,
    which include objects in all descendant OUs.

    .EXAMPLE
    Get-WinADOrganization

    Returns an object containing detailed information about the forest structure, domains, OUs, and object counts.

    .NOTES
    Requires the Active Directory PowerShell module.
    Utilizes helper functions like Get-WinADForestDetails, ConvertTo-DistinguishedName, and ConvertFrom-DistinguishedName.
    #>
    [cmdletBinding()]
    param(

    )
    $ForestInformation = Get-WinADForestDetails
    $Organization = [ordered] @{
        Forest                      = [System.Collections.Generic.List[PSCustomObject]]::new()
        Domains                     = [System.Collections.Generic.List[PSCustomObject]]::new()
        OrganizationalUnits         = [ordered] @{}
        Objects                     = [ordered] @{}
        DirectObjectsCount          = [ordered] @{}
        DirectObjectsUsersCount     = [ordered] @{}
        DirectObjectsComputersCount = [ordered] @{}
        DirectObjectsGroupsCount    = [ordered] @{}
        DirectObjectsContactsCount  = [ordered] @{}
        DirectObjectsOtherCount     = [ordered] @{}
    }

    foreach ($Domain in $ForestInformation.Domains) {
        $CurrentDomainDN = ConvertTo-DistinguishedName -CanonicalName $Domain -ToDomain

        $DomainObject = Get-ADObject -Identity $CurrentDomainDN -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -Properties gPLink, ProtectedFromAccidentalDeletion, WhenCreated, WhenChanged, Description, CanonicalName

        # Renamed Objects*Count to Total*Count as they represent the overall domain total.
        # Added Objects*Count for objects directly in the domain root.
        $DomainInformation = [ordered] @{
            Domain                          = $Domain
            Type                            = 'Domain'
            DistinguishedName               = $CurrentDomainDN
            CanonicalName                   = $DomainObject.CanonicalName
            Name                            = $Domain
            OrganizationalUnits             = @() # This property seems unused/unpopulated later, consider removing or using.
            OrganizationalUnitsCount        = 0 # This property seems unused/unpopulated later, consider removing or using.
            Description                     = $DomainObject.Description
            WhenCreated                     = $DomainObject.WhenCreated
            WhenChanged                     = $DomainObject.WhenChanged
            ProtectedFromAccidentalDeletion = $DomainObject.ProtectedFromAccidentalDeletion
            # Total counts for the entire domain
            TotalObjectsCount               = 0
            TotalObjectsUsersCount          = 0
            TotalObjectsComputersCount      = 0
            TotalObjectsGroupsCount         = 0
            TotalObjectsContactsCount       = 0
            TotalObjectsOtherCount          = 0
            # Direct counts for objects in domain root
            DirectGroupPolicyLinks          = $DomainObject.gPLink.Count
            DirectObjectsCount              = 0
            DirectObjectsUsersCount         = 0
            DirectObjectsComputersCount     = 0
            DirectObjectsGroupsCount        = 0
            DirectObjectsContactsCount      = 0
            DirectObjectsOtherCount         = 0
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
        $DomainInformation['Objects'] = $Objects

        foreach ($Object in $Objects) {
            # Determine the parent container DN (OU or Domain)
            $ParentDN = ConvertFrom-DistinguishedName -DistinguishedName $Object.DistinguishedName -ToOrganizationalUnit
            if (-not $ParentDN) {
                # Object is likely directly under the domain root
                $ParentDN = $CurrentDomainDN
            }

            # Initialize count structures if this is the first object seen for this ParentDN
            if (-not $Organization['Objects'].Contains($ParentDN)) {
                $Organization['Objects'][$ParentDN] = [System.Collections.Generic.List[PSCustomObject]]::new()
                $Organization['DirectObjectsCount'][$ParentDN] = 0
                $Organization['DirectObjectsUsersCount'][$ParentDN] = 0
                $Organization['DirectObjectsComputersCount'][$ParentDN] = 0
                $Organization['DirectObjectsGroupsCount'][$ParentDN] = 0
                $Organization['DirectObjectsContactsCount'][$ParentDN] = 0
                $Organization['DirectObjectsOtherCount'][$ParentDN] = 0
            }

            # Add object to the list for its parent
            $Organization['Objects'][$ParentDN].Add($Object)

            # Increment counts for the specific parent container (OU or Domain Root)
            $Organization['DirectObjectsCount'][$ParentDN]++
            # Increment total counts for the domain
            $DomainInformation['TotalObjectsCount']++

            # Increment specific type counts for parent and domain total
            if ($Object.ObjectClass -eq 'user') {
                $Organization['DirectObjectsUsersCount'][$ParentDN]++
                $DomainInformation['TotalObjectsUsersCount']++
            } elseif ($Object.ObjectClass -eq 'computer') {
                $Organization['DirectObjectsComputersCount'][$ParentDN]++
                $DomainInformation['TotalObjectsComputersCount']++
            } elseif ($Object.ObjectClass -eq 'group') {
                $Organization['DirectObjectsGroupsCount'][$ParentDN]++
                $DomainInformation['TotalObjectsGroupsCount']++
            } elseif ($Object.ObjectClass -eq 'contact') {
                $Organization['DirectObjectsContactsCount'][$ParentDN]++
                $DomainInformation['TotalObjectsContactsCount']++
            } else {
                $Organization['DirectObjectsOtherCount'][$ParentDN]++
                $DomainInformation['TotalObjectsOtherCount']++ # Increment total other count for domain
            }

            # If the object is directly under the domain, increment domain direct counts
            if ($ParentDN -eq $CurrentDomainDN) {
                $DomainInformation['ObjectsCount']++
                if ($Object.ObjectClass -eq 'user') {
                    $DomainInformation['DirectObjectsUsersCount']++
                } elseif ($Object.ObjectClass -eq 'computer') {
                    $DomainInformation['DirectObjectsComputersCount']++
                } elseif ($Object.ObjectClass -eq 'group') {
                    $DomainInformation['DirectObjectsGroupsCount']++
                } elseif ($Object.ObjectClass -eq 'contact') {
                    $DomainInformation['DirectObjectsContactsCount']++
                } else {
                    $DomainInformation['DirectObjectsOtherCount']++
                }
            }
        }

        $Organization.Domains.Add([PSCustomObject]$DomainInformation)

        # Store OU data temporarily to allow for total calculation later
        $DomainOUDataList = [System.Collections.Generic.List[PSCustomObject]]::new()
        $DomainOUs = Get-ADOrganizationalUnit -Filter "*" -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -Properties DistinguishedName, CanonicalName, WhenCreated, WhenChanged, Description, ProtectedFromAccidentalDeletion, LinkedGroupPolicyObjects
        foreach ($OU in $DomainOUs) {
            $SubOus = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit
            [Array] $OutputSubOu = @(
                if ($SubOus) {
                    $SubOus
                }
                $CurrentDomainDN
            )

            # Get direct counts, handling potential nulls/missing keys
            $DirectObjectsCount = if ($Organization['DirectObjectsCount'].Contains($OU.DistinguishedName)) { $Organization['DirectObjectsCount'][$OU.DistinguishedName] } else { 0 }
            $DirectUsersCount = if ($Organization['DirectObjectsUsersCount'].Contains($OU.DistinguishedName)) { $Organization['DirectObjectsUsersCount'][$OU.DistinguishedName] } else { 0 }
            $DirectComputersCount = if ($Organization['DirectObjectsComputersCount'].Contains($OU.DistinguishedName)) { $Organization['DirectObjectsComputersCount'][$OU.DistinguishedName] } else { 0 }
            $DirectGroupsCount = if ($Organization['DirectObjectsGroupsCount'].Contains($OU.DistinguishedName)) { $Organization['DirectObjectsGroupsCount'][$OU.DistinguishedName] } else { 0 }
            $DirectContactsCount = if ($Organization['DirectObjectsContactsCount'].Contains($OU.DistinguishedName)) { $Organization['DirectObjectsContactsCount'][$OU.DistinguishedName] } else { 0 }
            $DirectOtherCount = if ($Organization['DirectObjectsOtherCount'].Contains($OU.DistinguishedName)) { $Organization['DirectObjectsOtherCount'][$OU.DistinguishedName] } else { 0 }

            $OUData = [PSCustomObject]@{
                Domain                          = $Domain
                Type                            = 'OrganizationalUnit'
                DistinguishedName               = $OU.DistinguishedName
                CanonicalName                   = $OU.CanonicalName
                Name                            = $OU.Name
                OrganizationalUnits             = $OutputSubOu # This represents the parent hierarchy, not children
                OrganizationalUnitsCount        = $OutputSubOu.Count # Count of parent OUs + Domain
                Description                     = $OU.Description
                WhenCreated                     = $OU.WhenCreated
                WhenChanged                     = $OU.WhenChanged
                ProtectedFromAccidentalDeletion = $OU.ProtectedFromAccidentalDeletion
                # Total Counts (initialized to direct counts, will be updated later)
                TotalObjectsCount               = $DirectObjectsCount
                TotalObjectsUsersCount          = $DirectUsersCount
                TotalObjectsComputersCount      = $DirectComputersCount
                TotalObjectsGroupsCount         = $DirectGroupsCount
                TotalObjectsContactsCount       = $DirectContactsCount
                TotalObjectsOtherCount          = $DirectOtherCount
                # Direct Counts
                DirectGroupPolicyLinks          = $OU.LinkedGroupPolicyObjects.Count
                DirectObjectsCount              = $DirectObjectsCount
                DirectObjectsUsersCount         = $DirectUsersCount
                DirectObjectsComputersCount     = $DirectComputersCount
                DirectObjectsGroupsCount        = $DirectGroupsCount
                DirectObjectsContactsCount      = $DirectContactsCount
                DirectObjectsOtherCount         = $DirectOtherCount
            }
            $DomainOUDataList.Add($OUData)
        }
        # Assign the collected OU data for the current domain
        $Organization.OrganizationalUnits[$Domain] = $DomainOUDataList
    }

    # --- Calculate Total Counts for OUs ---
    # Create a lookup for all OUs across all domains by DN
    $AllOUsLookup = @{}
    foreach ($DomainKey in $Organization.OrganizationalUnits.Keys) {
        foreach ($OUItem in $Organization.OrganizationalUnits[$DomainKey]) {
            $AllOUsLookup[$OUItem.DistinguishedName] = $OUItem
        }
    }

    # Iterate through each OU and calculate its total counts by summing descendants' direct counts
    # It's often more robust to calculate from the bottom up, but summing all descendants works too.
    foreach ($CurrentOU_DN in $AllOUsLookup.Keys) {
        $CurrentOU = $AllOUsLookup[$CurrentOU_DN]

        # Find descendants (OUs whose DN ends with the current OU's DN, excluding self)
        $DescendantOUs = $AllOUsLookup.Values | Where-Object { $_.DistinguishedName -ne $CurrentOU.DistinguishedName -and $_.DistinguishedName.EndsWith(",$($CurrentOU.DistinguishedName)") }

        if ($DescendantOUs) {
            # Sum direct counts from all descendants
            # Use try-catch or default value for Measure-Object in case a property doesn't exist or is empty
            $ObjectsSum = ($DescendantOUs | Measure-Object -Property DirectObjectsCount -Sum -ErrorAction SilentlyContinue).Sum
            $UsersSum = ($DescendantOUs | Measure-Object -Property DirectObjectsUsersCount -Sum -ErrorAction SilentlyContinue).Sum
            $ComputersSum = ($DescendantOUs | Measure-Object -Property DirectObjectsComputersCount -Sum -ErrorAction SilentlyContinue).Sum
            $GroupsSum = ($DescendantOUs | Measure-Object -Property DirectObjectsGroupsCount -Sum -ErrorAction SilentlyContinue).Sum
            $ContactsSum = ($DescendantOUs | Measure-Object -Property DirectObjectsContactsCount -Sum -ErrorAction SilentlyContinue).Sum
            $OtherSum = ($DescendantOUs | Measure-Object -Property DirectObjectsOtherCount -Sum -ErrorAction SilentlyContinue).Sum

            # Add descendant sums to the current OU's total counts (which were initialized with direct counts)
            # Cast to [int] to handle potential $null from Measure-Object if sum is 0 or property missing
            $CurrentOU.TotalObjectsCount += [int]$ObjectsSum
            $CurrentOU.TotalObjectsUsersCount += [int]$UsersSum
            $CurrentOU.TotalObjectsComputersCount += [int]$ComputersSum
            $CurrentOU.TotalObjectsGroupsCount += [int]$GroupsSum
            $CurrentOU.TotalObjectsContactsCount += [int]$ContactsSum
            $CurrentOU.TotalObjectsOtherCount += [int]$OtherSum
        }
    }

    # --- End Calculate Total Counts ---

    $Organization
}