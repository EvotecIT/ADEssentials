function Test-LdapServer {
    [cmdletBinding()]
    param(
        [string] $ServerName,
        [string] $Computer
    )
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
        Computer               = $ServerName
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