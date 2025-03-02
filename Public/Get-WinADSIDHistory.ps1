function Get-WinADSIDHistory {
    <#
    .SYNOPSIS
    Retrieves SID History information for objects in Active Directory forest.

    .DESCRIPTION
    This function collects and analyzes SID History information for all objects in the Active Directory forest.
    It provides detailed information about internal and external SID history values, including statistics about
    users, groups, and computers that have SID history attributes.

    .PARAMETER Forest
    The name of the Active Directory forest to analyze. If not specified, uses the current forest.

    .PARAMETER ExcludeDomains
    An array of domain names to exclude from the analysis.

    .PARAMETER IncludeDomains
    An array of domain names to include in the analysis. Also aliased as 'Domain' or 'Domains'.

    .PARAMETER ExtendedForestInformation
    A hashtable containing extended forest information. Usually provided by Get-WinADForestDetails.

    .PARAMETER All
    Switch to return all information including domain SIDs and statistics. If not specified, returns only object information.

    .EXAMPLE
    Get-WinADSIDHistory -Forest "contoso.com"

    Returns a list of all objects with SID history in the specified forest.

    .EXAMPLE
    Get-WinADSIDHistory -IncludeDomains "domain1.local","domain2.local" -All

    Returns detailed SID history information including statistics for specified domains.

    .EXAMPLE
    Get-WinADSIDHistory -ExcludeDomains "legacy.local" -All

    Returns detailed SID history information for all domains except the specified excluded domain.

    .NOTES
    The function returns:
    - Object details (Name, Domain, Enabled status, etc.)
    - SID History count and values
    - Internal vs External vs Unknown SID information
    - Domain translation for SID values
    - Statistics about object types and status
    #>
    [CmdletBinding()]
    param (
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $All
    )

    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    # Lets get all information about the forest
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation -Extended

    # Lets create an output object
    $Output = [ordered] @{
        'All'           = [System.Collections.Generic.List[PSCustomObject]]::new()
        'DomainSIDs'    = $null
        'Statistics'    = [ordered] @{
            'TotalObjects'    = 0
            'TotalUsers'      = 0
            'TotalGroups'     = 0
            'TotalComputers'  = 0
            'EnabledObjects'  = 0
            'DisabledObjects' = 0
            'InternalSIDs'    = 0
            'ExternalSIDs'    = 0
            'UnknownSIDs'     = 0
        }
        'Trusts'        = [System.Collections.Generic.List[PSCustomObject]]::new()
        'DuplicateSIDs' = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    # Lets find out all trusts in the forest
    $Output['Trusts'] = Get-WinADTrust -Forest $Forest -Recursive -SkipValidation

    # Lets find out all SIDs that are in the forest and in trusts
    $DomainSIDs = [ordered]@{}
    $ForestDomainSIDs = [ordered]@{}
    $TrustDomainSIDs = [ordered]@{}

    # Add forest domains
    foreach ($Domain in $ForestInformation.DomainsExtended.Keys) {
        $SID = $ForestInformation.DomainsExtended[$Domain].DomainSID
        $DomainSIDs[$SID] = [PSCustomObject] @{
            Domain = $Domain
            Type   = 'Domain'
            SID    = $SID
        }
        $ForestDomainSIDs[$SID] = $Domain
    }

    # Add trusted domains
    foreach ($Trust in $Output['Trusts']) {
        if ($Trust.TrustTarget -in $ForestInformation.DomainsExtended.Keys) {
            continue
        }
        $SID = $Trust.DomainSID
        $DomainSIDs[$SID] = [PSCustomObject] @{
            Domain = $Trust.TrustTarget
            Type   = 'Trust'
            SID    = $SID
        }
        $TrustDomainSIDs[$SID] = $Trust.TrustTarget
    }

    # Lets get all objects with SIDHistory
    $AllUsers = foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers'][$Domain].HostName[0]
        $getADObjectSplat = @{
            LDAPFilter = "(sidHistory=*)"
            Properties = 'sidHistory', 'userPrincipalName', 'WhenCreated', 'WhenChanged', 'userAccountControl', 'mail', 'sAMAccountName', 'lastLogonTimestamp', 'objectClass', 'distinguishedName', 'name', 'pwdLastSet'
            Server     = $QueryServer
        }

        $Objects = Get-ADObject @getADObjectSplat
        foreach ($Object in $Objects) {
            $SidDomains = [System.Collections.Generic.List[string]]::new()
            $SidHistoryValues = [System.Collections.Generic.List[string]]::new()
            $SidHistoryDomainsTranslated = [System.Collections.Generic.List[string]]::new()
            $SidHistoryInternal = [System.Collections.Generic.List[string]]::new()
            $SIDHistoryExternal = [System.Collections.Generic.List[string]]::new()
            $SIDHistoryUnknown = [System.Collections.Generic.List[string]]::new()

            foreach ($Sid in $Object.sidHistory) {
                $SidHistoryValues.Add($Sid.Value)
                $DomainSID = $Sid.AccountDomainSid.Value

                # Check if this is from an internal forest domain
                if ($ForestDomainSIDs.Contains($DomainSID)) {
                    $SIDHistoryInternal.Add($Sid.Value)
                    $Output['Statistics']['InternalSIDs']++
                }
                # Check if this is from a known trust
                elseif ($TrustDomainSIDs.Contains($DomainSID)) {
                    $SIDHistoryExternal.Add($Sid.Value)
                    $Output['Statistics']['ExternalSIDs']++
                }
                # Otherwise it's unknown
                else {
                    $SIDHistoryUnknown.Add($Sid.Value)
                    $Output['Statistics']['UnknownSIDs']++
                }

                if (-not $SidDomains.Contains($DomainSID)) {
                    $SidDomains.Add($DomainSID)
                }

                $DomainInternal = $DomainSIDs[$DomainSID].Domain
                if ($DomainInternal) {
                    if (-not $SidHistoryDomainsTranslated.Contains($DomainInternal)) {
                        $SidHistoryDomainsTranslated.Add($DomainInternal)
                    }
                } else {
                    if (-not $SidHistoryDomainsTranslated.Contains($DomainSID)) {
                        $SidHistoryDomainsTranslated.Add($DomainSID)
                    }
                }
            }

            $UAC = Convert-UserAccountControl -UserAccountControl $Object.UserAccountControl

            $LastLogonTime = if ($Object.lastLogonTimestamp) {
                [datetime]::FromFileTime($Object.lastLogonTimestamp)
            } else {
                $null
            }
            $LastLogonTimeDays = if ($LastLogonTime) {
                [math]::Round((New-TimeSpan -Start $LastLogonTime -End (Get-Date)).TotalDays, 0)
            } else {
                $null
            }

            $PasswordLastSet = if ($Object.pwdLastSet) {
                [datetime]::FromFileTime($Object.pwdLastSet)
            } else {
                $null
            }

            $PasswordLastSetDays = if ($PasswordLastSet) {
                [math]::Round((New-TimeSpan -Start $PasswordLastSet -End (Get-Date)).TotalDays, 0)
            } else {
                $null
            }

            $O = [PSCustomObject] @{
                Name               = $Object.Name
                UserPrincipalName  = $Object.UserPrincipalName
                Domain             = $Domain
                SamAccountName     = $Object.sAMAccountName
                ObjectClass        = $Object.ObjectClass
                Enabled            = if ($UAC -contains 'ACCOUNTDISABLE') { $false } else { $true }
                PasswordDays       = $PasswordLastSetDays
                LogonDays          = $LastLogonTimeDays
                Count              = $SidHistoryValues.Count
                SIDHistory         = $SidHistoryValues
                Domains            = $SidDomains
                DomainsExpanded    = $SidHistoryDomainsTranslated
                Internal           = $SIDHistoryInternal
                InternalCount      = $SIDHistoryInternal.Count
                External           = $SIDHistoryExternal
                ExternalCount      = $SIDHistoryExternal.Count
                Unknown            = $SIDHistoryUnknown
                UnknownCount       = $SIDHistoryUnknown.Count
                WhenCreated        = $Object.WhenCreated
                WhenChanged        = $Object.WhenChanged
                LastLogon          = $LastLogonTime
                PasswordLastSet    = $PasswordLastSet
                OrganizationalUnit = ConvertFrom-DistinguishedName -DistinguishedName $Object.DistinguishedName -ToOrganizationalUnit
                DistinguishedName  = $Object.DistinguishedName
            }
            if ($O.Enabled) {
                $Output['Statistics']['EnabledObjects']++
            } else {
                $Output['Statistics']['DisabledObjects']++
            }
            $Output['Statistics']['TotalObjects']++
            switch ($O.ObjectClass) {
                'user' {
                    $Output['Statistics']['TotalUsers']++
                }
                'group' {
                    $Output['Statistics']['TotalGroups']++
                }
                'computer' {
                    $Output['Statistics']['TotalComputers']++
                }
            }
            $O
            if ($All) {
                foreach ($Sid in $SidDomains) {
                    if (-not $Output[$Sid]) {
                        $Output[$Sid] = [System.Collections.Generic.List[PSCustomObject]]::new()
                    }
                    $Output[$Sid].Add($O)
                }
            }
        }
    }
    if ($All) {
        $Output['DomainSIDs'] = $DomainSIDs
        $Output['Statistics'] = $Output['Statistics']
        $Output['All'] = $AllUsers
        $Output
    } else {
        $AllUsers
    }
}