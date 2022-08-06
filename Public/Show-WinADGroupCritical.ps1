function Show-WinADGroupCritical {
    <#
    .SYNOPSIS
    Command to gather nested group membership from default critical groups in the Active Directory.

    .DESCRIPTION
    Command to gather nested group membership from default critical groups in the Active Directory.
    This command will show data in table and diagrams in HTML format.

    .PARAMETER GroupName
    Group Name or Names to search for from provided list. If skipped all groups will be checked.

    .PARAMETER FilePath
    Path to HTML file where it's saved. If not given temporary path is used

    .PARAMETER HideAppliesTo
    Allows to define to which diagram HideComputers,HideUsers,HideOther applies to

    .PARAMETER HideComputers
    Hide computers from diagrams - useful for performance reasons

    .PARAMETER HideUsers
    Hide users from diagrams - useful for performance reasons

    .PARAMETER HideOther
    Hide other objects from diagrams - useful for performance reasons

    .PARAMETER Online
    Forces use of online CDN for JavaScript/CSS which makes the file smaller. Default - use offline.

    .PARAMETER HideHTML
    Prevents HTML output from being displayed in browser after generation is done

    .PARAMETER DisableBuiltinConditions
    Disables table coloring allowing user to define it's own conditions

    .PARAMETER AdditionalStatistics
    Adds additional data to Self object. It includes count for NestingMax, NestingGroup, NestingGroupSecurity, NestingGroupDistribution. It allows for easy filtering where we expect security groups only when there are nested distribution groups.

    .PARAMETER SkipDiagram
    Skips diagram generation and only displays table. Useful if the diagram can't handle amount of data or if the diagrams are not nessecary.

    .PARAMETER Summary
    Adds additional tab with all groups together on two diagrams

    .EXAMPLE
    Show-WinADGroupCritical

    .NOTES
    General notes
    #>
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
        [parameter(Mandatory)][alias('ReportPath')][string] $FilePath,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $DisableBuiltinConditions,
        [switch] $AdditionalStatistics,
        [switch] $SkipDiagram,
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
        Show-WinADGroupMember -Identity $ListGroups -HideHTML:$HideHTML.IsPresent -FilePath $FilePath -DisableBuiltinConditions:$DisableBuiltinConditions.IsPresent -Online:$Online.IsPresent -HideUsers:$HideUsers.IsPresent -HideComputers:$HideComputers.IsPresent -AdditionalStatistics:$AdditionalStatistics.IsPresent -Summary:$Summary.IsPresent -SkipDiagram:$SkipDiagram.IsPresent
    } else {
        Write-Warning -Message "Show-WinADGroupCritical - Requested group(s) not found."
    }
}