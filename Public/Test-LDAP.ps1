Function Test-LDAP {
    <#
    .SYNOPSIS
    Tests LDAP connectivity to one ore more servers.

    .DESCRIPTION
    Tests LDAP connectivity to one ore more servers. It's able to gather certificate information which provides useful information.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers, by default there are no exclusions, as long as VerifyDomainControllers switch is enabled. Otherwise this parameter is ignored.

    .PARAMETER IncludeDomainControllers
    Include only specific domain controllers, by default all domain controllers are included, as long as VerifyDomainControllers switch is enabled. Otherwise this parameter is ignored.

    .PARAMETER SkipRODC
    Skip Read-Only Domain Controllers. By default all domain controllers are included.

    .PARAMETER ExtendedForestInformation
    Ability to provide Forest Information from another command to speed up processing

    .PARAMETER ComputerName
    Provide FQDN, IpAddress or NetBIOS name to test LDAP connectivity. This can be used instead of targetting Forest/Domain specific LDAP Servers

    .PARAMETER GCPortLDAP
    Global Catalog Port for LDAP. If not defined uses default 3268 port.

    .PARAMETER GCPortLDAPSSL
    Global Catalog Port for LDAPs. If not defined uses default 3269 port.

    .PARAMETER PortLDAP
    LDAP port. If not defined uses default 389

    .PARAMETER PortLDAPS
    LDAPs port. If not defined uses default 636

    .PARAMETER VerifyCertificate
    Binds to LDAP and gathers information about certificate available

    .PARAMETER Credential
    Allows to define credentials. This switches authentication for LDAP Binding from Kerberos to Basic

    .EXAMPLE
    Test-LDAP -ComputerName 'AD1' -VerifyCertificate | Format-Table *

    .EXAMPLE
    Test-LDAP -VerifyCertificate -SkipRODC | Format-Table *

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'Forest')]
    param (
        [Parameter(ParameterSetName = 'Forest')][alias('ForestName')][string] $Forest,
        [Parameter(ParameterSetName = 'Forest')][string[]] $ExcludeDomains,
        [Parameter(ParameterSetName = 'Forest')][string[]] $ExcludeDomainControllers,
        [Parameter(ParameterSetName = 'Forest')][alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [Parameter(ParameterSetName = 'Forest')][alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [Parameter(ParameterSetName = 'Forest')][switch] $SkipRODC,
        [Parameter(ParameterSetName = 'Forest')][System.Collections.IDictionary] $ExtendedForestInformation,

        [alias('Server', 'IpAddress')][Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory, ParameterSetName = 'Computer')][string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Forest')]
        [Parameter(ParameterSetName = 'Computer')]
        [int] $GCPortLDAP = 3268,
        [Parameter(ParameterSetName = 'Forest')]
        [Parameter(ParameterSetName = 'Computer')]
        [int] $GCPortLDAPSSL = 3269,
        [Parameter(ParameterSetName = 'Forest')]
        [Parameter(ParameterSetName = 'Computer')]
        [int] $PortLDAP = 389,
        [Parameter(ParameterSetName = 'Forest')]
        [Parameter(ParameterSetName = 'Computer')]
        [int] $PortLDAPS = 636,
        [Parameter(ParameterSetName = 'Forest')]
        [Parameter(ParameterSetName = 'Computer')]
        [switch] $VerifyCertificate,
        [Parameter(ParameterSetName = 'Forest')]
        [Parameter(ParameterSetName = 'Computer')]
        [PSCredential] $Credential
    )
    begin {
        Add-Type -Assembly System.DirectoryServices.Protocols
        if (-not $ComputerName) {
            $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -SkipRODC:$SkipRODC.IsPresent -IncludeDomainControllers $IncludeDomainControllers -ExcludeDomainControllers $ExcludeDomainControllers
        }
    }
    Process {
        if ($ComputerName) {
            foreach ($Computer in $ComputerName) {
                Write-Verbose "Test-LDAP - Processing $Computer"
                $ServerName = ConvertTo-ComputerFQDN -Computer $Computer
                Test-LdapServer -ServerName $ServerName -Computer $Computer
            }
        } else {
            foreach ($Computer in $ForestInformation.ForestDomainControllers) {
                Write-Verbose "Test-LDAP - Processing $($Computer.HostName)"
                Test-LdapServer -ServerName $($Computer.HostName) -Computer $Computer.HostName -Advanced $Computer
            }
        }
    }
}