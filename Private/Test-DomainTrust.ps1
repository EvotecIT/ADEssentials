function Test-DomainTrust {
    <#
    .SYNOPSIS
    Test the trust relationship between two domains.

    .DESCRIPTION
    This function tests the trust relationship between the specified domain and a trusted domain.

    .PARAMETER Domain
    Specifies the domain to test the trust relationship for.

    .PARAMETER TrustedDomain
    Specifies the trusted domain to test the trust relationship against.

    .EXAMPLE
    Test-DomainTrust -Domain "contoso.com" -TrustedDomain "fabrikam.com"
    Tests the trust relationship between the "contoso.com" domain and the "fabrikam.com" trusted domain.

    .NOTES
    Author: Your Name
    Date: Date
    Version: 1.0
    #>
    [cmdletBinding()]
    param(
        [string] $Domain,
        [string] $TrustedDomain
    )
    #$DomainPDC = $ForestInformation['DomainDomainControllers'][$Domain] | Where-Object { $_.IsPDC -eq $true }
    $DomainInformation = Get-WinADDomain -Domain $Domain
    $DomainPDC = $DomainInformation.PdcRoleOwner.Name

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
    $getCimInstanceSplat = @{
        ClassName    = 'Microsoft_DomainTrustStatus'
        Namespace    = 'root\MicrosoftActiveDirectory'
        ComputerName = $DomainPDC
        ErrorAction  = 'SilentlyContinue'
        Property     = $PropertiesTrustWMI
        Verbose      = $false
    }
    if ($TrustedDomain) {
        $getCimInstanceSplat['Filter'] = "TrustedDomain = `"$TrustedDomain`""
    }
    $TrustStatatuses = Get-CimInstance @getCimInstanceSplat
    if ($TrustStatatuses) {
        foreach ($Status in $TrustStatatuses) {
            [PSCustomObject] @{
                'TrustSource'     = $DomainInformation.Name
                'TrustPartner'    = $Status.TrustedDomain
                'TrustAttributes' = if ($Status.TrustAttributes) { Get-ADTrustAttributes -Value $Status.TrustAttributes } else { 'Error - needs fixing' }
                'TrustStatus'     = if ($null -ne $Status) { $Status.TrustStatusString } else { 'N/A' }
                'TrustSourceDC'   = if ($null -ne $Status) { $Status.PSComputerName } else { '' }
                'TrustTargetDC'   = if ($null -ne $Status) { $Status.TrustedDCName.Replace('\\', '') } else { '' }
                #'TrustOK'         = if ($null -ne $Status) { $Status.TrustIsOK } else { $false }
                #'TrustStatusInt'  = if ($null -ne $Status) { $Status.TrustStatus } else { -1 }
            }
        }
    } else {
        [PSCustomObject] @{
            'TrustSource'     = $DomainInformation.Name
            'TrustPartner'    = $TrustedDomain
            'TrustAttributes' = 'Error - needs fixing'
            'TrustStatus'     = 'N/A'
            'TrustSourceDC'   = ''
            'TrustTargetDC'   = ''
            #'TrustOK'         = $false
            #'TrustStatusInt'  = -1
        }
    }
}