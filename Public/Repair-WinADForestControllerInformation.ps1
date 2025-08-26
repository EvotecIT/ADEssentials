function Repair-WinADForestControllerInformation {
    <#
    .SYNOPSIS
    Repairs the Active Directory forest controller information by fixing ownership and management settings for domain controllers.

    .DESCRIPTION
    This cmdlet repairs the Active Directory forest controller information by ensuring that domain controllers are properly owned and managed. It can fix the ownership and management settings for domain controllers based on the specified type of repair. The cmdlet supports processing a limited number of domain controllers at a time.

    .PARAMETER Type
    Specifies the type of repair to perform on the domain controllers. The valid types are 'Owner' and 'Manager'. 'Owner' repairs the ownership settings, and 'Manager' repairs the management settings.

    .PARAMETER ForestName
    Specifies the name of the forest to repair.

    .PARAMETER ExcludeDomains
    Specifies the domains to exclude from the repair process.

    .PARAMETER IncludeDomains
    Specifies the domains to include in the repair process.

    .PARAMETER ExtendedForestInformation
    Specifies the extended information about the forest to use for the repair process.

    .PARAMETER LimitProcessing
    Specifies the maximum number of domain controllers to process in a single run.

    .EXAMPLE
    Repair-WinADForestControllerInformation -Type Owner, Manager -ForestName example.com -IncludeDomains example.com, sub.example.com -LimitProcessing 10

    This example repairs the ownership and management settings for up to 10 domain controllers in the example.com and sub.example.com domains within the example.com forest.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported.
    #>
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][validateSet('Owner', 'Manager')][string[]] $Type,
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [int] $LimitProcessing
    )
    $ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    if (-not $ADAdministrativeGroups) {
        $ADAdministrativeGroups = Get-ADADministrativeGroups -Type DomainAdmins, EnterpriseAdmins -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ForestInformation
    }
    $Fixed = 0
    $DCs = Get-WinADForestControllerInformation -Forest $Forest -ExtendedForestInformation $ForestInformation -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains | ForEach-Object {
        $DC = $_
        $Done = $false
        if ($Type -contains 'Owner') {
            if ($DC.OwnerType -ne 'Administrative') {
                Write-Verbose -Message "Repair-WinADForestControllerInformation - Fixing (Owner) [$($DC.DomainName)]($Count/$($DCs.Count)) $($DC.DNSHostName)"
                $Principal = $ADAdministrativeGroups[$DC.DomainName]['DomainAdmins']
                Set-ADACLOwner -ADObject $DC.DistinguishedName -Principal $Principal
                $Done = $true
            }
        }
        if ($Type -contains 'Manager') {
            if ($null -ne $DC.ManagedBy) {
                Write-Verbose -Message "Repair-WinADForestControllerInformation - Fixing (Manager) [$($DC.DomainName)]($Count/$($DCs.Count)) $($DC.DNSHostName)"
                Set-ADComputer -Identity $DC.DistinguishedName -Clear ManagedBy -Server $ForestInformation['QueryServers'][$DC.DomainName]['HostName'][0]
                $Done = $true
            }
        }
        if ($Done -eq $true) {
            $Fixed++
        }
        if ($LimitProcessing -ne 0 -and $Fixed -eq $LimitProcessing) {
            break
        }
    }
}