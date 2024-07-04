Function Get-WinADPrivilegedObjects {
    <#
    .SYNOPSIS
    Retrieves privileged objects within an Active Directory forest.

    .DESCRIPTION
    This cmdlet retrieves and displays privileged objects within an Active Directory forest. It can be used to identify objects with administrative privileges, including their properties such as when they were changed, created, their admin count, and whether they are critical system objects. The cmdlet also provides information about the associated domain and the date of the last originating change for the admin count.

    .PARAMETER Forest
    Specifies the target forest to retrieve privileged objects from. This parameter is required.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search.

    .PARAMETER LegitimateOnly
    If specified, only objects with legitimate admin counts are returned.

    .PARAMETER OrphanedOnly
    If specified, only orphaned objects (not critical system objects and not members of critical groups) are returned.

    .PARAMETER SummaryOnly
    A switch parameter that controls the level of detail in the output. If set, the output includes a summary of the privileged objects. If not set, the output includes detailed information.

    .PARAMETER DoNotShowCriticalSystemObjects
    If specified, critical system objects are excluded from the results.

    .PARAMETER Formatted
    A switch parameter that controls the formatting of the output. If set, the output is formatted for better readability.

    .PARAMETER Splitter
    Specifies the character to use as a delimiter when joining multiple data elements together in the output.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .EXAMPLE
    Get-WinADPrivilegedObjects -Forest "example.com" -IncludeDomains "example.com" -LegitimateOnly -Formatted
    This example retrieves only the privileged objects with legitimate admin counts within the "example.com" forest and formats the output for better readability.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [alias('Get-WinADPriviligedObjects')]
    [cmdletbinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $LegitimateOnly,
        [switch] $OrphanedOnly,
        #[switch] $Unique,
        [switch] $SummaryOnly,
        [switch] $DoNotShowCriticalSystemObjects,
        [alias('Display')][switch] $Formatted,
        [string] $Splitter = [System.Environment]::NewLine,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    $Domains = $ForestInformation.Domains
    $UsersWithAdminCount = foreach ($Domain in $Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        if ($DoNotShowCriticalSystemObjects) {
            $Objects = Get-ADObject -Filter 'admincount -eq 1 -and iscriticalsystemobject -notlike "*"' -Server $QueryServer -Properties whenchanged, whencreated, admincount, isCriticalSystemObject, samaccountname, "msDS-ReplAttributeMetaData"
        } else {
            $Objects = Get-ADObject -Filter 'admincount -eq 1' -Server $QueryServer -Properties whenchanged, whencreated, admincount, isCriticalSystemObject, samaccountname, "msDS-ReplAttributeMetaData"
        }
        foreach ($_ in $Objects) {
            [PSCustomObject] @{
                Domain                 = $Domain
                distinguishedname      = $_.distinguishedname
                whenchanged            = $_.whenchanged
                whencreated            = $_.whencreated
                admincount             = $_.admincount
                SamAccountName         = $_.SamAccountName
                objectclass            = $_.objectclass
                isCriticalSystemObject = if ($_.isCriticalSystemObject) { $true } else { $false }
                adminCountDate         = ($_.'msDS-ReplAttributeMetaData' | ForEach-Object { ([XML]$_.Replace("`0", "")).DS_REPL_ATTR_META_DATA | Where-Object { $_.pszAttributeName -eq "admincount" } }).ftimeLastOriginatingChange | Get-Date -Format MM/dd/yyyy
            }
        }
    }

    $CriticalGroups = foreach ($Domain in $Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        Get-ADGroup -Filter 'admincount -eq 1 -and iscriticalsystemobject -eq $true' -Server $QueryServer #| Select-Object @{name = 'Domain'; expression = { $domain } }, distinguishedname
    }

    $CacheCritical = [ordered] @{}
    foreach ($Group in $CriticalGroups) {
        [Array] $Members = Get-WinADGroupMember -Identity $Group.distinguishedname -Verbose:$false -All
        Write-Verbose -Message "Processing $($Group.DistinguishedName) with $($Members.Count) members"
        foreach ($Member in $Members) {
            if ($null -ne $Member -and $Member.DistinguishedName) {
                if (-not $CacheCritical[$Member.DistinguishedName]) {
                    $CacheCritical[$Member.DistinguishedName] = [System.Collections.Generic.List[string]]::new()
                }
                if ($Group.DistinguishedName -notin $CacheCritical[$Member.DistinguishedName]) {
                    $CacheCritical[$Member.DistinguishedName].Add($Group.DistinguishedName)
                }
            }
        }
    }

    $AdminCountAll = foreach ($object in $UsersWithAdminCount) {
        $DistinguishedName = $object.distinguishedname
        [Array] $IsMemberGroups = foreach ($Group in $CriticalGroups) {
            $CacheCritical[$DistinguishedName] -contains $Group.DistinguishedName
        }
        $IsMember = $IsMemberGroups -contains $true
        $GroupDomains = $CacheCritical[$DistinguishedName]
        $IsOrphaned = -not $Object.isCriticalSystemObject -and -not $IsMember

        if ($Formatted) {
            $GroupDomains = $GroupDomains -join $Splitter
            $User = [PSCustomObject] @{
                DistinguishedName      = $Object.DistinguishedName
                Domain                 = $Object.domain
                IsOrphaned             = $IsOrphaned
                IsMember               = $IsMember
                IsCriticalSystemObject = $Object.isCriticalSystemObject
                Admincount             = $Object.admincount
                AdminCountDate         = $Object.adminCountDate
                WhenCreated            = $Object.whencreated
                ObjectClass            = $Object.objectclass
                GroupDomain            = $GroupDomains
            }
        } else {
            $User = [PSCustomObject] @{
                'DistinguishedName'      = $Object.DistinguishedName
                'Domain'                 = $Object.domain
                'IsOrphaned'             = $IsOrphaned
                'IsMember'               = $IsMember
                'IsCriticalSystemObject' = $Object.isCriticalSystemObject
                'AdminCount'             = $Object.admincount
                'AdminCountDate'         = $Object.adminCountDate
                'WhenCreated'            = $Object.whencreated
                'ObjectClass'            = $Object.objectclass
                'GroupDomain'            = $GroupDomains
            }
        }
        $User
    }

    $Output = @(
        if ($OrphanedOnly) {
            $AdminCountAll | Where-Object { $_.IsOrphaned }
        } elseif ($LegitimateOnly) {
            $AdminCountAll | Where-Object { $_.IsOrphaned -eq $false }
        } else {
            $AdminCountAll
        }
    )
    if ($SummaryOnly) {
        $Output | Group-Object ObjectClass | Select-Object -Property Name, Count
    } else {
        $Output
    }
}