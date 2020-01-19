function Get-WinADLDAPBindingsSummary {
    [cmdletbinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [int] $Days = 1
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC
    $Events = Get-Events -LogName 'Directory Service' -ID 2887 -Machine $ForestInformation.ForestDomainControllers.HostName -DateFrom ((Get-Date).Date.adddays(-$Days))
    foreach ($Event in $Events) {
        [PSCustomobject] @{
            'Domain Controller'                                                        = $Event.Computer
            'Number of simple binds performed without SSL/TLS'                         = $Event.'NoNameA0'
            'Number of Negotiate/Kerberos/NTLM/Digest binds performed without signing' = $Event.'NoNameA1'
            'GatheredFrom'                                                             = $Event.'GatheredFrom'
            'GatheredLogName'                                                          = $Event.'GatheredLogName'
        }
    }
}