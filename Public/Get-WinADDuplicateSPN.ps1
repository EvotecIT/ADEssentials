function Get-WinADDuplicateSPN {
    <#
    .SYNOPSIS
    Detects and lists duplicate Service Principal Names (SPNs) in the Active Directory Domain.

    .DESCRIPTION
    Detects and lists duplicate Service Principal Names (SPNs) in the Active Directory Domain.

    .PARAMETER All
    Returns all duplicate and non-duplicate SPNs. Default is to only return duplicate SPNs.

    .PARAMETER Exclude
    Provides ability to exclude specific SPNs from the duplicate detection. By default it excludes kadmin/changepw as with multiple forests it will happen for sure.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .EXAMPLE
    Get-WinADDuplicateSPN | Format-Table

    .EXAMPLE
    Get-WinADDuplicateSPN -All | Format-Table

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [switch] $All,
        [string[]] $Exclude,
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [Parameter(ParameterSetName = 'Forest')][System.Collections.IDictionary] $ExtendedForestInformation
    )
    $Excluded = @(
        'kadmin/changepw'
        foreach ($Item in $Exclude) {
            $iTEM
        }
    )

    $SPNCache = [ordered] @{}
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        Write-Verbose -Message "Get-WinADDuplicateSPN - Processing $Domain"
        $Objects = (Get-ADObject -LDAPFilter "ServicePrincipalName=*" -Properties ServicePrincipalName -Server $ForestInformation['QueryServers'][$domain]['HostName'][0])
        Write-Verbose -Message "Get-WinADDuplicateSPN - Found $($Objects.Count) objects. Processing..."
        foreach ($Object in $Objects) {
            foreach ($SPN in $Object.ServicePrincipalName) {
                if (-not $SPNCache[$SPN]) {
                    $SPNCache[$SPN] = [PSCustomObject] @{
                        Name      = $SPN
                        Duplicate = $false
                        Count     = 0
                        Excluded  = $false
                        List      = [System.Collections.Generic.List[Object]]::new()
                    }
                }
                if ($SPN -in $Excluded) {
                    $SPNCache[$SPN].Excluded = $true
                }
                $SPNCache[$SPN].List.Add($Object)
                $SPNCache[$SPN].Count++
            }
        }
    }
    Write-Verbose -Message "Get-WinADDuplicateSPN - Finalizing output. Processing..."
    foreach ($SPN in $SPNCache.Values) {
        if ($SPN.Count -gt 1 -and $SPN.Excluded -ne $true) {
            $SPN.Duplicate = $true
        }
        if ($All) {
            $SPN
        } else {
            if ($SPN.Duplicate) {
                $SPN
            }
        }
    }
}