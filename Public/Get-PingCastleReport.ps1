function Get-PingCastleReport {
    <#
    .SYNOPSIS
    Retrieves PingCastle report data from the specified file.

    .DESCRIPTION
    This function retrieves PingCastle report data from the specified file path.

    .PARAMETER FilePath
    Specifies the path to the PingCastle report file.

    .EXAMPLE
    Get-PingCastleReport -FilePath "C:\Reports\PingCastleReport.xml"
    Retrieves PingCastle report data from the specified file.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $FilePath
    )
    if (-not (Test-Path $FilePath)) {
        Write-Warning -Message "Get-PingCastle - File $FilePath does not exist. "
        return
    }

    $XmlRiskRules = (Select-Xml -Path $FilePath -XPath "/HealthcheckData/RiskRules").node
    $XmlDomainName = (Select-Xml -Path $FilePath -XPath "/HealthcheckData/DomainFQDN").node.InnerXML
    $XmlScanDate = [datetime](Select-Xml -Path $FilePath -XPath "/HealthcheckData/GenerationDate").node.InnerXML
    $XmlRisks = $XmlRiskRules.HealthcheckRiskRule | Select-Object Category, Points, Rationale, RiskId
    $XmlRisksPoints = $XmlRisks | Measure-Object -Sum Points

    $DataOutput = [ordered] @{
        DomainName  = $XmlDomainName
        DateScan    = $XmlScanDate
        TotalPoints = $XmlRisksPoints.Sum
        Risks       = $XmlRisks
        Categories  = [ordered]@{}
        RisksIds    = [ordered]@{}
    }
    foreach ($Risk in $XmlRisks) {
        $Category = $Risk.Category
        if (-not $DataOutput.Categories[$Category]) {
            $DataOutput.Categories[$Category] = [System.Collections.Generic.List[object]]::new()
        }
        $DataOutput.Categories[$Category].Add($Risk)
    }
    foreach ($Risk in $XmlRisks) {
        $RiskId = $Risk.RiskId
        $DataOutput.RisksIds[$RiskId] = $Risk

    }
    $DataOutput
}
