Function Get-WinADPriviligedObjects {
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
    if (-not $ExtendedForestInformation) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    } else {
        $ForestInformation = $ExtendedForestInformation
    }
    $Domains = $ForestInformation.Domains

    $UsersWithAdminCount = foreach ($Domain in $Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        if ($DoNotShowCriticalSystemObjects) {
            $Objects = Get-ADObject -filter 'admincount -eq 1 -and iscriticalsystemobject -notlike "*"' -server $QueryServer -properties whenchanged, whencreated, admincount, isCriticalSystemObject, samaccountname, "msDS-ReplAttributeMetaData"
        } else {
            $Objects = Get-ADObject -filter 'admincount -eq 1' -server $QueryServer -properties whenchanged, whencreated, admincount, isCriticalSystemObject, samaccountname, "msDS-ReplAttributeMetaData"
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
        Get-ADGroup -filter 'admincount -eq 1 -and iscriticalsystemobject -eq $true' -server $QueryServer | Select-Object @{name = 'Domain'; expression = { $domain } }, distinguishedname
    }

    $AdminCountAll = foreach ($object in $UsersWithAdminCount) {
        $DistinguishedName = $object.distinguishedname
        # https://blogs.msdn.microsoft.com/adpowershell/2009/04/14/active-directory-powershell-advanced-filter-part-ii/

        $IsMember = foreach ($Group in $CriticalGroups) {
            $QueryServer = $ForestInformation['QueryServers']["$($Group.Domain)"].HostName[0]
            $Group = Get-ADGroup -Filter "Member -RecursiveMatch '$DistinguishedName'" -searchbase $Group.DistinguishedName -server $QueryServer
            if ($Group) {
                $Group.DistinguishedName
            }
        }

        if ($IsMember.Count -gt 0) {
            $GroupDomains = $IsMember
        } else {
            $GroupDomains = $null
        }

        if ($Formatted) {
            $GroupDomains = $GroupDomains -join $Splitter
            $User = [PSCustomObject] @{
                DistinguishedName      = $Object.DistinguishedName
                Domain                 = $Object.domain
                IsOrphaned             = (-not $Object.isCriticalSystemObject) -and (-not $IsMember -and -not $Object.isCriticalSystemObject )
                IsMember               = $IsMember.Count -gt 0
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
                'IsOrphaned'             = (-not $Object.isCriticalSystemObject) -and (-not $IsMember -and -not $Object.isCriticalSystemObject )
                'IsMember'               = $IsMember.Count -gt 0
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