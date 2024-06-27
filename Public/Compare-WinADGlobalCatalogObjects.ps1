function Compare-WinADGlobalCatalogObjects {
    <#
    .SYNOPSIS
    This function compares objects in the Global Catalog of an Active Directory forest.

    .DESCRIPTION
    The function iterates over each domain in the forest, and for each domain, it compares the objects in the domain with the objects in the Global Catalog.
    It checks for missing objects and objects with wrong GUIDs. The results are returned in a summary object.

    .PARAMETER Advanced
    If this switch is provided, the function will return the full summary object.
    If not, it will only return the missing objects and objects with wrong GUIDs.

    .EXAMPLE
    Compare-WinADGlobalCatalogObjects -Advanced

    This will return the full summary object for all domains in the forest.

    .EXAMPLE
    Compare-WinADGlobalCatalogObjects

    This will return only the missing objects and objects with wrong GUIDs for all domains in the forest.

    .NOTES
    This function requires the Get-WinADForestDetails and Compare-InternalMissingObject functions.
    #>
    [CmdletBinding()]
    param(
        [switch] $Advanced,
        [string] $Forest,
        [string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [int] $LimitPerDomain
    )

    $SummaryDomains = [ordered] @{}
    $ForestInformation = Get-WinADForestDetails -PreferWritable -Forest $Forest
    foreach ($Domain in $ForestInformation.Domains) {
        if ($IncludeDomains -and $Domain -notin $IncludeDomains) { continue }
        if ($ExcludeDomains -and $Domain -in $ExcludeDomains) { continue }
        Write-Color -Text "Processing Domain: ", $Domain -Color Yellow, White
        $QueryServer = $ForestInformation['QueryServers'][$Domain].HostName[0]
        $SummaryDomains[$Domain] = Compare-InternalMissingObject -ForestInformation $ForestInformation -Server $QueryServer -SourceDomain $Domain -TargetDomain $ForestInformation.Domains -LimitPerDomain $LimitPerDomain
    }

    if ($Advanced) {
        $SummaryDomains
    } else {
        foreach ($Domain in $SummaryDomains.Keys) {
            foreach ($Server in $SummaryDomains[$Domain].Keys) {
                if ($Server -notin 'Summary') {
                    if ($null -ne $SummaryDomains[$Domain][$Server].Missing.Count -gt 0) {
                        $SummaryDomains[$Domain][$Server].Missing
                    }
                    if ($Null -ne $SummaryDomains[$Domain][$Server].WrongGuid.Count -gt 0) {
                        $SummaryDomains[$Domain][$Server].WrongGuid
                    }
                    if ($Null -ne $SummaryDomains[$Domain][$Server].Ignored.Count -gt 0) {
                        $SummaryDomains[$Domain][$Server].Ignored
                    }
                }
            }
        }
    }
}
