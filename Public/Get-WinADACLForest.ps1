function Get-WinADACLForest {
    <#
    .SYNOPSIS
    Gets permissions or owners from forest

    .DESCRIPTION
    Gets permissions or owners from forest

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .PARAMETER Owner
    Queries for Owners, instead of permissions

    .PARAMETER Separate
    Returns OrderedDictionary with each top level container being in separate key

    .EXAMPLE
    # With split per sheet
    $FilePath = "$Env:USERPROFILE\Desktop\PermissionsOutputPerSheet.xlsx"
    $Permissions = Get-WinADACLForest -Verbose -SplitWorkSheets
    foreach ($Perm in $Permissions.Keys) {
        $Permissions[$Perm] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Perm -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
    $Permissions | Format-Table *

    .EXAMPLE
    # With owners in one sheet
    $FilePath = "$Env:USERPROFILE\Desktop\PermissionsOutput.xlsx"
    $Permissions = Get-WinADACLForest -Verbose
    $Permissions | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'Permissions' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    $Permissions | Format-Table *

    .EXAMPLE
    # With split per sheet
    $FilePath = "$Env:USERPROFILE\Desktop\OwnersOutput.xlsx"
    $Owners = Get-WinADACLForest -Verbose -SplitWorkSheets -Owner
    foreach ($Owner in $Owners.Keys) {
        $Owners[$Owner] | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName $Owner -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    }
    $Owners | Format-Table *

    .EXAMPLE
    # With owners in one sheet
    $FilePath = "$Env:USERPROFILE\Desktop\OwnersOutput.xlsx"
    $Owners = Get-WinADACLForest -Verbose -Owner
    $Owners | ConvertTo-Excel -FilePath $FilePath -ExcelWorkSheetName 'AllOwners' -AutoFilter -AutoFit -FreezeTopRowFirstColumn
    $Owners | Format-Table *

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [string[]] $SearchBase,
        [switch] $Owner,
        [switch] $Separate,
        [switch] $IncludeInherited
    )
    $ForestTime = Start-TimeLog
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -Extended
    $Output = [ordered]@{}
    foreach ($Domain in $ForestInformation.Domains) {
        if ($SearchBase) {
            # Lets do quick removal when domain doesn't match so we don't use search base by accident
            $Found = $false
            foreach ($S in $SearchBase) {
                $DN = $ForestInformation['DomainsExtended'][$Domain].DistinguishedName
                $CurrentObjectDC = ConvertFrom-DistinguishedName -DistinguishedName $S -ToDC
                if ($CurrentObjectDC -eq $DN) {
                    $Found = $true
                    break
                }
            }
            if ($Found -eq $false) {
                continue
            }
        }
        Write-Verbose "Get-WinADACLForest - [Start][Domain $Domain]"
        $DomainTime = Start-TimeLog
        $Output[$Domain] = [ordered] @{}
        $Server = $ForestInformation.QueryServers[$Domain].HostName[0]
        $DomainStructure = @(
            if ($SearchBase) {
                foreach ($S in $SearchBase) {
                    Get-ADObject -Filter * -Properties canonicalName, ntSecurityDescriptor -SearchScope Base -SearchBase $S -Server $Server
                }
            } else {
                Get-ADObject -Filter * -Properties canonicalName, ntSecurityDescriptor -SearchScope Base -Server $Server
                Get-ADObject -Filter * -Properties canonicalName, ntSecurityDescriptor -SearchScope OneLevel -Server $Server
            }
        )
        $LdapFilter = "(|(ObjectClass=user)(ObjectClass=contact)(ObjectClass=computer)(ObjectClass=group)(objectClass=inetOrgPerson)(objectClass=foreignSecurityPrincipal)(objectClass=container)(objectClass=organizationalUnit)(objectclass=msDS-ManagedServiceAccount)(objectclass=msDS-GroupManagedServiceAccount))"
        $DomainStructure = $DomainStructure | Sort-Object -Property canonicalName
        foreach ($Structure in $DomainStructure) {
            $Time = Start-TimeLog
            $ObjectName = "[$Domain][$($Structure.CanonicalName)][$($Structure.ObjectClass)][$($Structure.DistinguishedName)]"
            #$ObjectOutputName = "$($Structure.Name)_$($Structure.ObjectClass)".Replace(' ', '').ToLower()
            $ObjectOutputName = "$($Structure.Name)".Replace(' ', '').ToLower()
            Write-Verbose "Get-WinADACLForest - [Start]$ObjectName"
            if ($Structure.ObjectClass -eq 'organizationalUnit') {
                #$Containers = Get-ADOrganizationalUnit -Filter '*' -Server $Server -SearchBase $Structure.DistinguishedName -Properties canonicalName
                $Ignore = @()
                $Containers = @(
                    Get-ADObject -LDAPFilter $LdapFilter -SearchBase $Structure.DistinguishedName -Properties canonicalName, ntSecurityDescriptor -Server $Server -SearchScope Subtree | ForEach-Object {
                        $Found = $false
                        foreach ($I in $Ignore) {
                            if ($_.DistinguishedName -like $I) {
                                $Found = $true
                            }
                        }
                        if (-not $Found) {
                            $_
                        }
                    }
                ) | Sort-Object canonicalName
            } elseif ($Structure.ObjectClass -eq 'domainDNS') {
                $Containers = $Structure
            } elseif ($Structure.ObjectClass -eq 'container') {
                $Ignore = @(
                    # lets ignore GPO, we deal with it in GPOZaurr
                    -join ('*CN=Policies,CN=System,', $ForestInformation['DomainsExtended'][$DOmain].DistinguishedName)

                    -join ('*,CN=System,', $ForestInformation['DomainsExtended'][$DOmain].DistinguishedName)
                )
                #$Containers = Get-ADObject -SearchBase $Structure.DistinguishedName -Filter { ObjectClass -eq 'container' } -Properties canonicalName -Server $Server -SearchScope Subtree
                $Containers = Get-ADObject -LDAPFilter $LdapFilter -SearchBase $Structure.DistinguishedName -Properties canonicalName, ntSecurityDescriptor -Server $Server -SearchScope Subtree | ForEach-Object {
                    $Found = $false
                    foreach ($I in $Ignore) {
                        if ($_.DistinguishedName -like $I) {
                            $Found = $true
                        }
                    }
                    if (-not $Found) {
                        $_
                    }
                } | Sort-Object canonicalName
            } else {
                $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
                Write-Verbose "Get-WinADACLForest - [Skip  ]$ObjectName[ObjectClass not requested]"
                continue
            }
            if (-not $Containers) {
                $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
                Write-Verbose "Get-WinADACLForest - [End  ]$ObjectName[$EndTime]"
                continue
            }
            Write-Verbose "Get-WinADACLForest - [Read ]$ObjectName[Objects to process: $($Containers.Count)]"
            if ($Owner) {
                $MYACL = Get-ADACLOwner -ADObject $Containers -Resolve
            } else {
                if ($IncludeInherited) {
                    $MYACL = Get-ADACL -ADObject $Containers -ResolveTypes
                } else {
                    $MYACL = Get-ADACL -ADObject $Containers -ResolveTypes -NotInherited
                }
            }
            if ($Separate) {
                $Output[$Domain][$ObjectOutputName] = $MYACL
            } else {
                $MYACL
            }
            $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
            Write-Verbose "Get-WinADACLForest - [End  ]$ObjectName[$EndTime]"
        }
        $DomainEndTime = Stop-TimeLog -Time $DomainTime -Option OneLiner
        Write-Verbose "Get-WinADACLForest - [End  ][Domain $Domain][$DomainEndTime]"
    }
    $ForestEndTime = Stop-TimeLog -Time $ForestTime -Option OneLiner
    Write-Verbose "Get-WinADACLForest - [End  ][Forest][$ForestEndTime]"
    if ($Separate) {
        $Output
    }
}