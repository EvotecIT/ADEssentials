Function Get-WinADPrivilegedObjects {
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

    $CacheCritical = @{}
    foreach ($Group in $CriticalGroups) {
        $Members = Get-WinADGroupMember -Identity $Group.distinguishedname -Verbose:$false
        foreach ($Member in $Members) {
            if (-not $CacheCritical[$Member.DistinguishedName]) {
                $CacheCritical[$Member.DistinguishedName] = [System.Collections.Generic.List[string]]::new()
            }
            $CacheCritical[$Member.DistinguishedName].Add($Group.DistinguishedName)
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