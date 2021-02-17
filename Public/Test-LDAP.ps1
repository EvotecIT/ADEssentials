Function Test-LDAP {
    [CmdletBinding()]
    param (
        [alias('Server', 'IpAddress')][Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)][string[]]$ComputerName,
        [int] $GCPortLDAP = 3268,
        [int] $GCPortLDAPSSL = 3269,
        [int] $PortLDAP = 389,
        [int] $PortLDAPS = 636,
        [switch] $VerifyCertificate,
        [PSCredential] $Credential
    )
    begin {
        Add-Type -Assembly System.DirectoryServices.Protocols
    }
    Process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Test-LDAP - Processing $Computer"
            # Checks for ServerName - Makes sure to convert IPAddress to DNS, otherwise SSL won't work
            $IPAddressCheck = [System.Net.IPAddress]::TryParse($Computer, [ref][ipaddress]::Any)
            $IPAddressMatch = $Computer -match '^(\d+\.){3}\d+$'
            if ($IPAddressCheck -and $IPAddressMatch) {
                [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue -Type PTR -Verbose:$false)
                if ($ADServerFQDN.Count -gt 0) {
                    $ServerName = $ADServerFQDN[0].NameHost
                } else {
                    $ServerName = $Computer
                }
            } else {
                [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue -Type A -Verbose:$false)
                if ($ADServerFQDN.Count -gt 0) {
                    $ServerName = $ADServerFQDN[0].Name
                } else {
                    $ServerName = $Computer
                }
            }
            if ($ServerName -notlike '*.*') {
                $FQDN = $false
                # querying SSL won't work for non-fqdn, we check if after all our checks it's string with dot.
                $GlobalCatalogSSL = [PSCustomObject] @{ Status = $false; ErrorMessage = 'No FQDN' }
                $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP
                $ConnectionLDAPS = [PSCustomObject] @{ Status = $false; ErrorMessage = 'No FQDN' }
                $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP

                $PortsThatWork = @(
                    if ($GlobalCatalogNonSSL.Status) { $GCPortLDAP }
                    if ($GlobalCatalogSSL.Status) { $GCPortLDAPSSL }
                    if ($ConnectionLDAP.Status) { $PortLDAP }
                    if ($ConnectionLDAPS.Status) { $PortLDAPS }
                ) | Sort-Object
            } else {
                $FQDN = $true
                $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL
                $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP
                $ConnectionLDAPS = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAPS
                $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP

                $PortsThatWork = @(
                    if ($GlobalCatalogNonSSL.Status) { $GCPortLDAP }
                    if ($GlobalCatalogSSL.Status) { $GCPortLDAPSSL }
                    if ($ConnectionLDAP.Status) { $PortLDAP }
                    if ($ConnectionLDAPS.Status) { $PortLDAPS }
                ) | Sort-Object
            }
            $Output = [ordered] @{
                Computer               = $Computer
                ComputerFQDN           = $ServerName
                GlobalCatalogLDAP      = $GlobalCatalogNonSSL.Status
                GlobalCatalogLDAPS     = $GlobalCatalogSSL.Status
                GlobalCatalogLDAPSBind = $null
                LDAP                   = $ConnectionLDAP.Status
                LDAPS                  = $ConnectionLDAPS.Status
                LDAPSBind              = $null
                AvailablePorts         = $PortsThatWork -join ','
                FQDN                   = $FQDN
            }
            if ($VerifyCertificate) {
                if ($psboundparameters.ContainsKey("Credential")) {
                    $Certificate = Test-LDAPCertificate -Computer $ServerName -Port $PortLDAPS -Credential $Credential
                    $CertificateGC = Test-LDAPCertificate -Computer $ServerName -Port $GCPortLDAPSSL -Credential $Credential
                } else {
                    $Certificate = Test-LDAPCertificate -Computer $ServerName -Port $PortLDAPS
                    $CertificateGC = Test-LDAPCertificate -Computer $ServerName -Port $GCPortLDAPSSL
                }
                $Output['LDAPSBind'] = $Certificate.State
                $Output['GlobalCatalogLDAPSBind'] = $CertificateGC.State
                $Certificate.Remove('State')
                $Output = $Output + $Certificate
            } else {
                $Output.Remove('LDAPSBind')
                $Output.Remove('GlobalCatalogLDAPSBind')
            }
            [PSCustomObject] $Output
        }
    }
}