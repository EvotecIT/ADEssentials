Function Get-WinADPriviligedObjects {
    [cmdletbinding()]
    param(
        [switch] $LegitimateOnly,
        [switch] $OrphanedOnly,
        [switch] $Unique,
        [switch] $SummaryOnly
    )
    $Forest = Get-ADForest
    $Domains = $Forest.Domains

    $UsersWithAdminCount = foreach ($domain in $Domains) {
        $Objects = Get-ADObject -filter 'admincount -eq 1 -and iscriticalsystemobject -notlike "*"' -server $domain -properties whenchanged, whencreated, admincount, isCriticalSystemObject, "msDS-ReplAttributeMetaData", samaccountname
        foreach ($_ in $Objects) {
            [PSCustomObject] @{
                Domain                 = $Domain
                distinguishedname      = $_.distinguishedname
                whenchanged            = $_.whenchanged
                whencreated            = $_.whencreated
                admincount             = $_.admincount
                SamAccountName         = $_.SamAccountName
                objectclass            = $_.objectclass
                isCriticalSystemObject = $_.isCriticalSystemObject
                adminCountDate         = ($_.'msDS-ReplAttributeMetaData' | ForEach-Object { ([XML]$_.Replace("`0", "")).DS_REPL_ATTR_META_DATA | Where-Object { $_.pszAttributeName -eq "admincount" } }).ftimeLastOriginatingChange | Get-Date -Format MM/dd/yyyy
            }
        }
    }

    $CriticalGroups = foreach ($domain in $Domains) {
        Get-ADGroup -filter 'admincount -eq 1 -and iscriticalsystemobject -eq $true' -server $domain | Select-Object @{name = 'Domain'; expression = { $domain } }, distinguishedname
    }

    $AdminCountLegitimate = [System.Collections.Generic.List[PSCustomObject]]::new()
    $AdminCountOrphaned = [System.Collections.Generic.List[PSCustomObject]]::new()

    $AdminCountAll = foreach ($object in $UsersWithAdminCount) {
        $DistinguishedName = ($object).distinguishedname
        # https://blogs.msdn.microsoft.com/adpowershell/2009/04/14/active-directory-powershell-advanced-filter-part-ii/
        $Results = foreach ($Group in $CriticalGroups) {
            $IsMember = if (Get-ADGroup -Filter { Member -RecursiveMatch $DistinguishedName } -searchbase $Group.DistinguishedName -server $Group.Domain) { $True } else { $False }
            $User = [PSCustomObject] @{
                DistinguishedName      = $Object.DistinguishedName
                Domain                 = $Object.domain
                IsMember               = $IsMember
                Admincount             = $Object.admincount
                AdminCountDate         = $Object.adminCountDate
                Whencreated            = $Object.whencreated
                ObjectClass            = $Object.objectclass
                GroupDomain            = if ($IsMember) { $Group.Domain } else { $null }
                GroupDistinguishedname = if ($IsMember) { $Group.DistinguishedName } else { $null }
            }
            if ($User.IsMember) {
                $AdminCountLegitimate.Add($User)
                $User
            }
            if ($User.IsMember -eq $false -and $AdminCountLegitimate.DistinguishedName -notcontains $User.DistinguishedName -and $AdminCountOrphaned.DistinguishedName -notcontains $User.DistinguishedName) {

                $Properties = @(
                    'distinguishedname'
                    'domain'
                    'IsMember'
                    'admincount'
                    'adminCountDate'
                    'whencreated'
                    'objectclass'
                )

                $AdminCountOrphaned.Add(($User | Select-Object -Property $Properties))
                $User
            }
        }
        $Results
    }

    $Output = @(
        if ($OrphanedOnly) {
            $AdminCountOrphaned
        } elseif ($LegitimateOnly) {
            if ($Unique) {
                $AdminCountLegitimate | Select-Object -Property DistinguishedName, Domain, IsMember, Admincount, AdminCountDate, Whencreated, ObjectClass -Unique
            } else {
                $AdminCountLegitimate
            }
        } else {
            if ($Unique) {
                $AdminCountAll | Select-Object -Property DistinguishedName, Domain, IsMember, Admincount, AdminCountDate, Whencreated, ObjectClass -Unique
            } else {
                $AdminCountAll
            }
        }
    )
    if ($SummaryOnly) {
        $Output | Group-Object ObjectClass | Select-Object -Property Name, Count
    } else {
        $Output
    }
}
