function New-ADForestDrives {
    <#
    .SYNOPSIS
    Maps network drives for all domains in a specified Active Directory forest.

    .DESCRIPTION
    The New-ADForestDrives function maps network drives for all domains in a specified Active Directory forest. It retrieves domain information and maps drives accordingly.

    .PARAMETER ForestName
    Specifies the name of the Active Directory forest to map drives for.

    .PARAMETER ObjectDN
    Specifies the distinguished name of the object to map drives for.

    .EXAMPLE
    New-ADForestDrives -ForestName "example.com" -ObjectDN "CN=Users,DC=example,DC=com"
    This example maps network drives for the specified forest and object distinguished name.

    .NOTES
    File Name      : New-ADForestDrives.ps1
    Author         : Your Name
    Prerequisite   : This function requires the Active Directory module.

    #>
    [cmdletbinding()]
    param(
        [string] $ForestName,
        [string] $ObjectDN
    )
    if (-not $Global:ADDrivesMapped) {
        if ($ForestName) {
            $Forest = Get-ADForest -Identity $ForestName
        } else {
            $Forest = Get-ADForest
        }
        if ($ObjectDN) {
            $DNConverted = (ConvertFrom-Distinguishedname -DistinguishedName $ObjectDN -ToDC) -replace '=' -replace ','
            if (-not(Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                try {
                    if ($Server) {
                        $null = New-PSDrive -Name $DNConverted -Root '' -PsProvider ActiveDirectory -Server $Server.Hostname[0] -Scope Global -WhatIf:$false
                        Write-Verbose "New-ADForestDrives - Mapped drive $Domain / $($Server.Hostname[0])"
                    } else {
                        $null = New-PSDrive -Name $DNConverted -Root '' -PsProvider ActiveDirectory -Server $Domain -Scope Global -WhatIf:$false
                    }
                } catch {
                    Write-Warning "New-ADForestDrives - Couldn't map new AD psdrive for $Domain / $($Server.Hostname[0])"
                }
            }
        } else {
            foreach ($Domain in $Forest.Domains) {
                try {
                    $Server = Get-ADDomainController -Discover -DomainName $Domain -Writable
                    $DomainInformation = Get-ADDomain -Server $Server.Hostname[0]
                } catch {
                    Write-Warning "New-ADForestDrives - Can't process domain $Domain - $($_.Exception.Message)"
                    continue
                }
                $ObjectDN = $DomainInformation.DistinguishedName
                $DNConverted = (ConvertFrom-Distinguishedname -DistinguishedName $ObjectDN -ToDC) -replace '=' -replace ','
                if (-not(Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                    try {
                        if ($Server) {
                            $null = New-PSDrive -Name $DNConverted -Root '' -PsProvider ActiveDirectory -Server $Server.Hostname[0] -Scope Global -WhatIf:$false
                            Write-Verbose "New-ADForestDrives - Mapped drive $Domain / $Server"
                        } else {
                            $null = New-PSDrive -Name $DNConverted -Root '' -PsProvider ActiveDirectory -Server $Domain -Scope Global -WhatIf:$false
                        }
                    } catch {
                        Write-Warning "New-ADForestDrives - Couldn't map new AD psdrive for $Domain / $Server $($_.Exception.Message)"
                    }
                }
            }
        }
        $Global:ADDrivesMapped = $true
    }
}