Import-Module .\ADEssentials.psd1 -Force

#Show-WinADGroupMember -GroupName 'GDS-TestGroup2'
#Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins','Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html -Summary -HideUsers
#Show-WinADGroupMember -GroupName 'Test-Group', 'Domain Admins','Enterprise Admins', 'Administrators' -FilePath $PSScriptRoot\Reports\GroupMembership.html #-SummaryOnly

$ForestInformation = Get-WinADForestDetails -Extended #-IncludeDomains 'ad.evotec.xyz'
$ListGroups = foreach ($Domain in $ForestInformation.Domains) {
    $DomainSidValue = $ForestInformation.DomainsExtended[$Domain].DomainSID
    $PriviligedGroups = @{
        "Domain Admins"                            = "$DomainSidValue-512"
        "Cert Publishers"                          = "$DomainSidValue-517"
        "Schema Admins"                            = "$DomainSidValue-518"
        "Enterprise Admins"                        = "$DomainSidValue-519"
        "Dns Admins1"                              = "$DomainSidValue-1101"
        "Dns Admins2"                              = "$DomainSidValue-1102"
        "Dns Admins3"                              = "$DomainSidValue-1105"
        "DnsUpdateProxy"                           = "$DomainSidValue-1106"
        "Group Policy Creator Owners"              = "$DomainSidValue-520"
        'Protected Users'                          = "$DomainSidValue-525"
        'Key Admins'                               = "$DomainSidValue-526"
        'Enterprise Key Admins'                    = "$DomainSidValue-527"
        'Server Management'                        = "$DomainSidValue-1125"
        'Organization Management'                  = "$DomainSidValue-1117"
        'DHCP Users'                               = "$DomainSidValue-2111"
        'DHCP Administrators'                      = "$DomainSidValue-2112"
        'BUILTIN\Administrators'                   = "S-1-5-32-544"
        'BUILTIN\Account Operators'                = "S-1-5-32-548"
        'BUILTIN\Server Operators'                 = "S-1-5-32-549"
        'BUILTIN\Print Operators'                  = "S-1-5-32-550"
        'BUILTIN\Backup Operators'                 = "S-1-5-32-551"
        'BUILTIN\Replicators'                      = "S-1-5-32-552"
        'BUILTIN\Network Configuration Operations' = "S-1-5-32-556"
        'BUILTIN\Incoming Forest Trust Builders'   = "S-1-5-32-557"
        'BUILTIN\Event Log Readers'                = "S-1-5-32-573"
        'BUILTIN\Hyper-V Administrators'           = "S-1-5-32-578"
        'BUILTIN\Remote Management Users'          = "S-1-5-32-580"
    }
    foreach ($Group in $PriviligedGroups.Values) {
        (Get-ADGroup -Filter "SID -eq '$Group'" -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -ErrorAction SilentlyContinue).DistinguishedName
    }
}
Show-WinADGroupMember -Identity $ListGroups -Verbose -FilePath $PSScriptRoot\Reports\GroupReport.html -Online