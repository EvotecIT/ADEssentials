function Get-WinADTrustLegacy {
    <#
    .SYNOPSIS
    Retrieves trust relationships within a specified Active Directory forest, including legacy trusts.

    .DESCRIPTION
    This cmdlet is designed to gather detailed information about trust relationships within an Active Directory forest. It can target a specific forest, include or exclude specific domains, and display the results in a detailed or concise format. Additionally, it can filter out duplicate trusts and provide extended forest information.

    .PARAMETER Forest
    Specifies the target forest to query. If not provided, the current forest is used by default.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search. This parameter is optional and can be used to narrow down the search scope.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search. This parameter is optional and can be used to limit the search scope to specific domains.

    .PARAMETER Display
    A switch parameter that controls the level of detail in the output. If set, the output includes all available trust properties. If not set, the output is more concise.

    .PARAMETER ExtendedForestInformation
    A dictionary object that contains additional information about the forest. This parameter is optional and can be used to provide more context about the forest.

    .PARAMETER Unique
    A switch parameter that filters out duplicate trusts based on the source and target domains. If set, only unique trusts are returned.

    .EXAMPLE
    Get-WinADTrustLegacy -Display -Unique

    This example retrieves all trust relationships within the current forest, displaying detailed information and filtering out duplicate trusts.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires access to the target forest and domains.
    #>
    [CmdletBinding()]
    param(
        [string] $Forest,
        [alias('Domain')][string[]] $IncludeDomains,
        [string[]] $ExcludeDomains,
        [switch] $Display,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $Unique
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    $UniqueTrusts = [ordered]@{}
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        $Trusts = Get-ADTrust -Server $QueryServer -Filter "*" -Properties *
        $DomainPDC = $ForestInformation['DomainDomainControllers'][$Domain] | Where-Object { $_.IsPDC -eq $true }

        $PropertiesTrustWMI = @(
            'FlatName',
            'SID',
            'TrustAttributes',
            'TrustDirection',
            'TrustedDCName',
            'TrustedDomain',
            'TrustIsOk',
            'TrustStatus',
            'TrustStatusString', # TrustIsOk/TrustStatus are covered by this
            'TrustType'
        )
        $TrustStatatuses = Get-CimInstance -ClassName Microsoft_DomainTrustStatus -Namespace root\MicrosoftActiveDirectory -ComputerName $DomainPDC.HostName -ErrorAction SilentlyContinue -Verbose:$false -Property $PropertiesTrustWMI

        $ReturnData = foreach ($Trust in $Trusts) {
            if ($Unique) {
                $UniqueID1 = -join ($Domain, $Trust.trustPartner)
                $UniqueID2 = -join ($Trust.trustPartner, $Domain)
                if (-not $UniqueTrusts[$UniqueID1]) {
                    $UniqueTrusts[$UniqueID1] = $true
                } else {
                    continue
                }
                if (-not $UniqueTrusts[$UniqueID2]) {
                    $UniqueTrusts[$UniqueID2] = $true
                } else {
                    continue
                }
            }
            $TrustWMI = $TrustStatatuses | & { process { if ($_.TrustedDomain -eq $Trust.Target ) { $_ } } }
            if ($Display) {
                [PsCustomObject] @{
                    'Trust Source'               = $Domain
                    'Trust Target'               = $Trust.Target
                    'Trust Direction'            = $Trust.Direction.ToString()
                    'Trust Attributes'           = if ($Trust.TrustAttributes -is [int]) { (Get-ADTrustAttributes -Value $Trust.TrustAttributes) -join '; ' } else { 'Error - needs fixing' }
                    'Trust Status'               = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatusString } else { 'N/A' }
                    'Forest Transitive'          = $Trust.ForestTransitive
                    'Selective Authentication'   = $Trust.SelectiveAuthentication
                    'SID Filtering Forest Aware' = $Trust.SIDFilteringForestAware
                    'SID Filtering Quarantined'  = $Trust.SIDFilteringQuarantined
                    'Disallow Transivity'        = $Trust.DisallowTransivity
                    'Intra Forest'               = $Trust.IntraForest
                    'Is Tree Parent'             = $Trust.IsTreeParent
                    'Is Tree Root'               = $Trust.IsTreeRoot
                    'TGTDelegation'              = $Trust.TGTDelegation
                    'TrustedPolicy'              = $Trust.TrustedPolicy
                    'TrustingPolicy'             = $Trust.TrustingPolicy
                    'TrustType'                  = $Trust.TrustType.ToString()
                    'UplevelOnly'                = $Trust.UplevelOnly
                    'UsesAESKeys'                = $Trust.UsesAESKeys
                    'UsesRC4Encryption'          = $Trust.UsesRC4Encryption
                    'Trust Source DC'            = if ($null -ne $TrustWMI) { $TrustWMI.PSComputerName } else { '' }
                    'Trust Target DC'            = if ($null -ne $TrustWMI) { $TrustWMI.TrustedDCName.Replace('\\', '') } else { '' }
                    'Trust Source DN'            = $Trust.Source
                    'ObjectGUID'                 = $Trust.ObjectGUID
                    'Created'                    = $Trust.Created
                    'Modified'                   = $Trust.Modified
                    'Deleted'                    = $Trust.Deleted
                    'SID'                        = $Trust.securityIdentifier
                    'TrustOK'                    = if ($null -ne $TrustWMI) { $TrustWMI.TrustIsOK } else { $false }
                    'TrustStatus'                = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatus } else { -1 }
                }
            } else {
                [PsCustomObject] @{
                    'TrustSource'               = $Domain
                    'TrustTarget'               = $Trust.Target
                    'TrustDirection'            = $Trust.Direction.ToString()
                    'TrustAttributes'           = if ($Trust.TrustAttributes -is [int]) { Get-ADTrustAttributes -Value $Trust.TrustAttributes } else { 'Error - needs fixing' }
                    'TrustStatus'               = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatusString } else { 'N/A' }
                    'ForestTransitive'          = $Trust.ForestTransitive
                    'SelectiveAuthentication'   = $Trust.SelectiveAuthentication
                    'SIDFiltering Forest Aware' = $Trust.SIDFilteringForestAware
                    'SIDFiltering Quarantined'  = $Trust.SIDFilteringQuarantined
                    'DisallowTransivity'        = $Trust.DisallowTransivity
                    'IntraForest'               = $Trust.IntraForest
                    'IsTreeParent'              = $Trust.IsTreeParent
                    'IsTreeRoot'                = $Trust.IsTreeRoot
                    'TGTDelegation'             = $Trust.TGTDelegation
                    'TrustedPolicy'             = $Trust.TrustedPolicy
                    'TrustingPolicy'            = $Trust.TrustingPolicy
                    'TrustType'                 = $Trust.TrustType.ToString()
                    'UplevelOnly'               = $Trust.UplevelOnly
                    'UsesAESKeys'               = $Trust.UsesAESKeys
                    'UsesRC4Encryption'         = $Trust.UsesRC4Encryption
                    'TrustSourceDC'             = if ($null -ne $TrustWMI) { $TrustWMI.PSComputerName } else { '' }
                    'TrustTargetDC'             = if ($null -ne $TrustWMI) { $TrustWMI.TrustedDCName.Replace('\\', '') } else { '' }
                    'TrustSourceDN'             = $Trust.Source
                    'ObjectGUID'                = $Trust.ObjectGUID
                    'Created'                   = $Trust.Created
                    'Modified'                  = $Trust.Modified
                    'Deleted'                   = $Trust.Deleted
                    'SID'                       = $Trust.securityIdentifier
                    'TrustOK'                   = if ($null -ne $TrustWMI) { $TrustWMI.TrustIsOK } else { $false }
                    'TrustStatusInt'            = if ($null -ne $TrustWMI) { $TrustWMI.TrustStatus } else { -1 }
                }
            }
        }
        $ReturnData
    }
}