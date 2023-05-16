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

    .PARAMETER IncludeOwnerType
    Include only specific Owner Type, by default all Owner Types are included

    .PARAMETER ExcludeOwnerType
    Exclude specific Owner Type, by default all Owner Types are included

    .PARAMETER Separate
    Returns OrderedDictionary with each top level container being in separate key

    .PARAMETER OutputFile
    Saves output to Excel file. Requires PSWriteExcel module.
    This was added to speed up processing and reduce memory usage.
    When using this option, you can use PassThru option, to get objects as well.

    .PARAMETER PassThru
    Returns objects as well as saves to Excel file. Requires PSWriteExcel module.

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
        [switch] $IncludeInherited,
        [validateSet('WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown')][string[]] $IncludeOwnerType,
        [validateSet('WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown')][string[]] $ExcludeOwnerType,
        [string] $OutputFile,
        [switch] $PassThru
    )
    if ($OutputFile) {
        $CommandExists = Get-Command -Name 'ConvertTo-Excel' -ErrorAction SilentlyContinue
        if (-not $CommandExists) {
            Write-Warning -Message "ConvertTo-Excel command is missing. Please install PSWriteExcel module when using OutputFile option."
            Write-Warning -Message "Install-Module -Name PSWriteExcel -Force -Verbose"
            return
        }
    }

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
        Write-Verbose -Message "Get-WinADACLForest - [Start][Domain $Domain]"
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
            Write-Verbose -Message "Get-WinADACLForest - [Start]$ObjectName"
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
                Write-Verbose -Message "Get-WinADACLForest - [Skip  ]$ObjectName[ObjectClass not requested]"
                continue
            }
            if (-not $Containers) {
                $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
                Write-Verbose -Message "Get-WinADACLForest - [End  ]$ObjectName[$EndTime]"
                continue
            }
            Write-Verbose -Message "Get-WinADACLForest - [Read ]$ObjectName[Objects to process: $($Containers.Count)]"
            if ($Owner) {
                $getADACLOwnerSplat = @{
                    ADObject         = $Containers
                    Resolve          = $true
                    ExcludeOwnerType = $ExcludeOwnerType
                    IncludeOwnerType = $IncludeOwnerType
                }
                Remove-EmptyValue -IDictionary $getADACLOwnerSplat

                $MYACL = Get-ADACLOwner @getADACLOwnerSplat
            } else {
                if ($IncludeInherited) {
                    $MYACL = Get-ADACL -ADObject $Containers -ResolveTypes
                } else {
                    $MYACL = Get-ADACL -ADObject $Containers -ResolveTypes -NotInherited
                }
            }

            if ($OutputFile) {
                $TimeExport = Start-TimeLog
                $Extension = [io.path]::GetExtension($OutputFile)
                $DirectoryPath = [io.path]::GetDirectoryName($OutputFile)
                $FileName = [io.path]::GetFileNameWithoutExtension($OutputFile)
                if ($ForestInformation.Domains.Count -gt 1) {
                    $FinalPath = [io.path]::Combine($DirectoryPath, "$FileName-$Domain$Extension")
                } else {
                    $FinalPath = [io.path]::Combine($DirectoryPath, "$FileName$Extension")
                }
                Write-Verbose -Message "Get-WinADACLForest - [Save  ]$ObjectName[OutputFile: $FinalPath]"
                if ($Structure.ObjectClass -eq 'domainDns') {
                    $WorkSheetName = "$($Structure.CanonicalName)".Replace("/", "")
                } else {
                    $WorkSheetName = "$($Structure.Name)"
                }
                $MYACL | ConvertTo-Excel -FilePath $FinalPath -ExcelWorkSheetName $WorkSheetName -AutoFilter -AutoFit -FreezeTopRowFirstColumn
                $EndTimeExport = Stop-TimeLog -Time $TimeExport -Option OneLiner
                Write-Verbose -Message "Get-WinADACLForest - [End  ]$ObjectName[OutputFile: $FinalPath][$EndTimeExport]"
                Write-Verbose -Message "Get-WinADACLForest - [Start]$ObjectName[Garbage Collection]"
                [System.GC]::Collect()
                Start-Sleep -Seconds 5
                [System.GC]::Collect()
                Write-Verbose -Message "Get-WinADACLForest - [End  ]$ObjectName[Garbage Collection][Done]"
                if ($PassThru) {
                    $MYACL
                }
            } elseif ($Separate) {
                $Output[$Domain][$ObjectOutputName] = $MYACL
            } else {
                $MYACL
            }
            $EndTime = Stop-TimeLog -Time $Time -Option OneLiner
            Write-Verbose -Message "Get-WinADACLForest - [End  ]$ObjectName[$EndTime]"
        }
        $DomainEndTime = Stop-TimeLog -Time $DomainTime -Option OneLiner
        Write-Verbose -Message "Get-WinADACLForest - [End  ][Domain $Domain][$DomainEndTime]"
    }
    $ForestEndTime = Stop-TimeLog -Time $ForestTime -Option OneLiner
    Write-Verbose -Message "Get-WinADACLForest - [End  ][Forest][$ForestEndTime]"
    if ($Separate) {
        $Output
    }
}