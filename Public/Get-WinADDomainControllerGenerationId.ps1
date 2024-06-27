function Get-WinADDomainControllerGenerationId {
    <#
    .SYNOPSIS
    Provides information about the msDS-GenerationId of domain controllers

    .DESCRIPTION
    Provides information about the msDS-GenerationId of domain controllers

    .PARAMETER Forest
    Forest name to use for resolving. If not given it will use current forest.

    .PARAMETER ExcludeDomains
    Exclude specific domains from test

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers from test

    .PARAMETER IncludeDomains
    Include specific domains in test

    .PARAMETER IncludeDomainControllers
    Include specific domain controllers in test

    .PARAMETER SkipRODC
    Skip Read Only Domain Controllers when querying for information

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .EXAMPLE
    $Output = Get-WinADDomainControllerGenerationId -IncludeDomainControllers 'dc1.ad.evotec.pl'
    $Output | Format-Table

    .NOTES
    For virtual machine snapshot resuming detection. This attribute represents the VM Generation ID.

    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'Forest')][alias('ForestName')][string] $Forest,
        [Parameter(ParameterSetName = 'Forest')][string[]] $ExcludeDomains,
        [Parameter(ParameterSetName = 'Forest')][string[]] $ExcludeDomainControllers,
        [Parameter(ParameterSetName = 'Forest')][alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [Parameter(ParameterSetName = 'Forest')][alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [Parameter(ParameterSetName = 'Forest')][switch] $SkipRODC,
        [Parameter(ParameterSetName = 'Forest')][System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestDetails = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -SkipRODC:$SkipRODC.IsPresent -IncludeDomainControllers $IncludeDomainControllers -ExcludeDomainControllers $ExcludeDomainControllers
    foreach ($Domain in $ForestDetails.Domains) {
        foreach ($D in $ForestDetails.DomainDomainControllers[$Domain]) {
            Write-Verbose -Message "Get-MSDSGenerationID - Executing Get-ADObject $D.ComputerObjectDN -Server $D.HostName -Properties Name, SamAccountName, 'msDS-GenerationId'"
            try {
                $Data = Get-ADObject $D.DistinguishedName -Server $D.HostName -Properties Name, SamAccountName, 'msDS-GenerationId' -ErrorAction Stop
                $ErrorProvided = $null
            } catch {
                $ErrorProvided = $_.Exception.Message
                $Data = $null
            }
            if ($Data) {
                $GenerationID = $Data.'msDS-GenerationId'
            } else {
                $GenerationID = $null
            }
            if ($GenerationID) {
                $TranslatedGenerationID = ($GenerationID | ForEach-Object { $_.ToString("X2") }) -join ''
                #$TranslatedGenerationIDAlternative = [System.Convert]::ToHexString($GenerationID)
            } else {
                #$TranslatedGenerationIDAlternative = $null
                $TranslatedGenerationID = $null
            }
            [PSCustomObject] @{
                HostName            = $D.HostName
                Domain              = $Domain
                Name                = $D.Name
                SamAccountName      = $Data.SamAccountName
                'msDS-GenerationId' = $TranslatedGenerationID
                #'msDS-GenerationId' = $TranslatedGenerationIDAlternative
                Error               = $ErrorProvided
            }

        }
    }
}