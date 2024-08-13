function Get-WinADSiteCoverage {
    <#
    .SYNOPSIS
    Provides information about custom configuration for Site Coverage of Domain Controllers

    .DESCRIPTION
    Provides information about custom configuration for Site Coverage of Domain Controllers
    It requires Domain Admin rights to execute, as it checks registry settings on Domain Controllers
    It will check what Site Coverage is set on Domain Controllers and for both Site Coverage and GC Site Coverage.
    It will check if the Site exists in AD Sites and Services

    .PARAMETER Forest
    Specifies the target forest to retrieve site information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in the search.

    .PARAMETER SkipRODC
    Indicates whether to skip read-only domain controllers.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .EXAMPLE
    Get-WinADSiteCoverage -Forest "example.com"

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [string[]] $ExcludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation

    $AllSitesCache = [ordered] @{}
    try {
        $AllSites = Get-ADReplicationSite -Filter * -ErrorAction Stop -Server $ForestInformation.QueryServers['Forest'].HostName[0]
        foreach ($Site in $AllSites) {
            $AllSitesCache[$Site.Name] = $Site
        }
    } catch {
        Write-Warning -Message "Get-WinADSiteCoverage - We couldn't get all sites. Make sure you have RSAT installed and you have permissions to read AD Sites and Services. Error: $($_.Exception.Message)"
        return
    }

    $Count = 0
    foreach ($Domain in $ForestInformation.Domains) {
        $Count++
        $CountDC = 0
        foreach ($DC in $ForestInformation.DomainDomainControllers[$Domain]) {
            $CountDC++
            $DCSettings = Get-WinADDomainControllerNetLogonSettings -DomainController $DC.HostName
            [Array] $WrongSiteCoverage = foreach ($Site in $DCSettings.SiteCoverage) {
                if (-not $AllSitesCache[$Site]) {
                    $Site
                }
            }
            [Array] $WrongGCSiteCoverage = foreach ($Site in $DCSettings.GCSiteCoverage) {
                if (-not $AllSitesCache[$Site]) {
                    $Site
                }
            }

            Write-Verbose -Message "Get-WinADSiteCoverage - Processing Domain $Domain [$Count/$($ForestInformation.Domains.Count)] - DC $($DC.HostName) [$CountDC/$($ForestInformation.DomainDomainControllers[$Domain].Count)]"
            $Data = [PSCustomObject] @{
                'Domain'                         = $Domain
                'DomainController'               = $DC.HostName
                'Error'                          = $DCSettings.Error
                'HasIssues'                      = $null
                'DynamicSiteName'                = $DCSettings.DynamicSiteName
                'SiteCoverageCount'              = $DCSettings.SiteCoverage.Count
                'GCSiteCoverageCount'            = $DCSettings.GCSiteCoverage.Count
                'SiteCoverage'                   = $DCSettings.SiteCoverage
                'GCSiteCoverage'                 = $DCSettings.GCSiteCoverage
                'NonExistingSiteCoverage'        = $WrongSiteCoverage
                'NonExistingGCSiteCoverage'      = $WrongGCSiteCoverage
                'NonExistingSiteCoverageCount'   = $WrongSiteCoverage.Count
                'NonExistingGCSiteCoverageCount' = $WrongGCSiteCoverage.Count
                'ErrorMessage'                   = $DCSettings.ErrorMessage
            }
            # If there are no non-existing sites, we are good
            if ($Data.NonExistingSiteCoverageCount -eq 0 -and $Data.NonExistingGCSiteCoverageCount -eq 0 -and $false -eq $Data.Error) {
                $Data.HasIssues = $false
            } else {
                $Data.HasIssues = $true
            }
            $Data
        }
    }
}