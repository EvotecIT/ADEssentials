function Compare-WinADGlobalCatalogObjects {
    [CmdletBinding()]
    param(
        [switch] $Advanced
    )

    $SummaryDomains = [ordered] @{}
    $ForestInformation = Get-WinADForestDetails -PreferWritable
    foreach ($Domain in $ForestInformation.Domains) {
        Write-Color -Text "Processing Domain: ", $Domain -Color Yellow, White
        $QueryServer = $ForestInformation['QueryServers'][$Domain].HostName[0]
        $SummaryDomains[$Domain] = Compare-InternalMissingObject -ForestInformation $ForestInformation -Server $QueryServer -SourceDomain $Domain -TargetDomain $ForestInformation.Domains
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
                }
            }
        }
    }
}
