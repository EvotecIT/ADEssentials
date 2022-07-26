function Show-WinADGroupCritical {
    [alias('Show-WinADCriticalGroups')]
    [cmdletBinding()]
    param(
        [validateSet(
            "Domain Admins",
            "Cert Publishers",
            "Schema Admins",
            "Enterprise Admins",
            "DnsAdmins",
            "DnsAdmins2",
            "DnsUpdateProxy",
            "Group Policy Creator Owners",
            'Protected Users',
            'Key Admins',
            'Enterprise Key Admins',
            'Server Management',
            'Organization Management',
            'DHCP Users',
            'DHCP Administrators',
            'Administrators',
            'Account Operators',
            'Server Operators',
            'Print Operators',
            'Backup Operators',
            'Replicators',
            'Network Configuration Operations',
            'Incoming Forest Trust Builders',
            'Internet Information Services',
            'Event Log Readers',
            'Hyper-V Administrators',
            'Remote Management Users'
        )]
        [string[]] $GroupName,
        [parameter(Mandatory)][string] $ReportPath,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $DisableBuiltinConditions,
        [switch] $AdditionalStatistics,
        [switch] $Summary
    )

    $ForestInformation = Get-WinADForestDetails -Extended
    [Array] $ListGroups = foreach ($Domain in $ForestInformation.Domains) {
        $DomainSidValue = $ForestInformation.DomainsExtended[$Domain].DomainSID
        $PriviligedGroups = [ordered] @{
            "Domain Admins"                    = "$DomainSidValue-512"
            "Cert Publishers"                  = "$DomainSidValue-517"
            "Schema Admins"                    = "$DomainSidValue-518"
            "Enterprise Admins"                = "$DomainSidValue-519"
            "DnsAdmins"                        = "$DomainSidValue-1101"
            "DnsAdmins2"                       = "$DomainSidValue-1105"
            "DnsUpdateProxy"                   = "$DomainSidValue-1106"
            "Group Policy Creator Owners"      = "$DomainSidValue-520"
            'Protected Users'                  = "$DomainSidValue-525"
            'Key Admins'                       = "$DomainSidValue-526"
            'Enterprise Key Admins'            = "$DomainSidValue-527"
            'Server Management'                = "$DomainSidValue-1125"
            'Organization Management'          = "$DomainSidValue-1117"
            'DHCP Users'                       = "$DomainSidValue-2111"
            'DHCP Administrators'              = "$DomainSidValue-2112"
            'Administrators'                   = "S-1-5-32-544"
            'Account Operators'                = "S-1-5-32-548"
            'Server Operators'                 = "S-1-5-32-549"
            'Print Operators'                  = "S-1-5-32-550"
            'Backup Operators'                 = "S-1-5-32-551"
            'Replicators'                      = "S-1-5-32-552"
            'Network Configuration Operations' = "S-1-5-32-556"
            'Incoming Forest Trust Builders'   = "S-1-5-32-557"
            'Internet Information Services'    = "S-1-5-32-568"
            'Event Log Readers'                = "S-1-5-32-573"
            'Hyper-V Administrators'           = "S-1-5-32-578"
            'Remote Management Users'          = "S-1-5-32-580"
        }
        foreach ($Group in $PriviligedGroups.Keys) {
            $SearchName = $PriviligedGroups[$Group]
            if ($GroupName -and $Group -notin $GroupName) {
                continue
            }
            $GroupInformation = (Get-ADGroup -Filter "SID -eq '$SearchName'" -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -ErrorAction SilentlyContinue).DistinguishedName
            if ($GroupInformation) {
                $GroupInformation
            }
        }
    }
    if ($ListGroups.Count -gt 0) {
        Show-WinADGroupMember -Identity $ListGroups -HideHTML:$HideHTML.IsPresent -FilePath $ReportPath -DisableBuiltinConditions:$DisableBuiltinConditions.IsPresent -Online:$Online.IsPresent -HideUsers:$HideUsers.IsPresent -HideComputers:$HideComputers.IsPresent -AdditionalStatistics:$AdditionalStatistics.IsPresent -Summary:$Summary.IsPresent
    } else {
        Write-Warning -Message "Show-WinADGroupCritical - Requested group(s) not found."
    }
}