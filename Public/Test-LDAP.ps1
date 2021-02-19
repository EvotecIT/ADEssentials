Function Test-LDAP {
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
                Test-LdapServer -ServerName $($Computer.HostName) -Computer $Computer.HostName
            }
        }
    }
}