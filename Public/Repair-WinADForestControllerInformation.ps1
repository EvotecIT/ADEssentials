function Repair-WinADForestControllerInformation {
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
    $Count = 0
    $Fixed = 0
    $DCs = Get-WinADForestControllerInformation -Forest $Forest -ExtendedForestInformation $ForestInformation -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    foreach ($DC in $DCS) {
        Write-Verbose -Message "Repair-WinADForestControllerInformation - Processing [$($DC.DomainName)]($Count/$($DCs.Count)) $($DC.DNSHostName)"
        $Count++
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