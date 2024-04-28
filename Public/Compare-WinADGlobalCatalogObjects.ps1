function Compare-WinADGlobalCatalogObjects {
    [CmdletBinding()]
    param(

    )

    $SummaryDomains = [ordered] @{}
    $ForestInformation = Get-WinADForestDetails -PreferWritable
    foreach ($Domain in $ForestInformation.Domains) {
        Write-Color -Text "Processing Domain: ", $Domain -Color Yellow, White
        $QueryServer = $ForestInformation['QueryServers'][$Domain].HostName[0]
        $SummaryDomains[$Domain] = Compare-InternalMissingObject -ForestInformation $ForestInformation -Server $QueryServer -SourceDomain $Domain -TargetDomain $ForestInformation.Domains
    }
    $SummaryDomains
}
