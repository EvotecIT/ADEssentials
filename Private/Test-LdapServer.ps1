function Test-LdapServer {
    [cmdletBinding()]
    param(
        [string] $ServerName,
        [string] $Computer,
        [PSCustomObject] $Advanced
    )
    if ($ServerName -notlike '*.*') {
        # $FQDN = $false
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
        #$FQDN = $true
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
    if ($VerifyCertificate) {
        $Output = [ordered] @{
            Computer                = $ServerName
            Site                    = $Advanced.Site
            IsRO                    = $Advanced.IsReadOnly
            IsGC                    = $Advanced.IsGlobalCatalog
            GlobalCatalogLDAP       = $GlobalCatalogNonSSL.Status
            GlobalCatalogLDAPS      = $GlobalCatalogSSL.Status
            GlobalCatalogLDAPSBind  = $null
            LDAP                    = $ConnectionLDAP.Status
            LDAPS                   = $ConnectionLDAPS.Status
            LDAPSBind               = $null
            AvailablePorts          = $PortsThatWork -join ','
            X509NotBeforeDays       = $null
            X509NotAfterDays        = $null
            X509DnsNameList         = $null
            OperatingSystem         = $Advanced.OperatingSystem
            IPV4Address             = $Advanced.IPV4Address
            IPV6Address             = $Advanced.IPV6Address
            X509NotBefore           = $null
            X509NotAfter            = $null
            AlgorithmIdentifier     = $null
            CipherStrength          = $null
            X509FriendlyName        = $null
            X509SendAsTrustedIssuer = $null
            X509SerialNumber        = $null
            X509Thumbprint          = $null
            X509SubjectName         = $null
            X509Issuer              = $null
            X509HasPrivateKey       = $null
            X509Version             = $null
            X509Archived            = $null
            Protocol                = $null
            Hash                    = $null
            HashStrength            = $null
            KeyExchangeAlgorithm    = $null
            ExchangeStrength        = $null
            ErrorMessage            = $null
        }
    } else {
        $Output = [ordered] @{
            Computer               = $ServerName
            Site                   = $Advanced.Site
            IsRO                   = $Advanced.IsReadOnly
            IsGC                   = $Advanced.IsGlobalCatalog
            GlobalCatalogLDAP      = $GlobalCatalogNonSSL.Status
            GlobalCatalogLDAPS     = $GlobalCatalogSSL.Status
            GlobalCatalogLDAPSBind = $null
            LDAP                   = $ConnectionLDAP.Status
            LDAPS                  = $ConnectionLDAPS.Status
            LDAPSBind              = $null
            AvailablePorts         = $PortsThatWork -join ','
            OperatingSystem        = $Advanced.OperatingSystem
            IPV4Address            = $Advanced.IPV4Address
            IPV6Address            = $Advanced.IPV6Address
        }
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
        $Output['X509NotBeforeDays'] = $Certificate['X509NotBeforeDays']
        $Output['X509NotAfterDays'] = $Certificate['X509NotAfterDays']
        $Output['X509DnsNameList'] = $Certificate['X509DnsNameList']
        $Output['X509NotBefore'] = $Certificate['X509NotBefore']
        $Output['X509NotAfter'] = $Certificate['X509NotAfter']
        $Output['AlgorithmIdentifier'] = $Certificate['AlgorithmIdentifier']
        $Output['CipherStrength'] = $Certificate['CipherStrength']
        $Output['X509FriendlyName'] = $Certificate['X509FriendlyName']
        $Output['X509SendAsTrustedIssuer'] = $Certificate['X509SendAsTrustedIssuer']
        $Output['X509SerialNumber'] = $Certificate['X509SerialNumber']
        $Output['X509Thumbprint'] = $Certificate['X509Thumbprint']
        $Output['X509SubjectName'] = $Certificate['X509SubjectName']
        $Output['X509Issuer'] = $Certificate['X509Issuer']
        $Output['X509HasPrivateKey'] = $Certificate['X509HasPrivateKey']
        $Output['X509Version'] = $Certificate['X509Version']
        $Output['X509Archived'] = $Certificate['X509Archived']
        $Output['Protocol'] = $Certificate['Protocol']
        $Output['Hash'] = $Certificate['Hash']
        $Output['HashStrength'] = $Certificate['HashStrength']
        $Output['KeyExchangeAlgorithm'] = $Certificate['KeyExchangeAlgorithm']
        $Output['ExchangeStrength'] = $Certificate['ExchangeStrength']
        $Output['ErrorMessage'] = $Certificate['ErrorMessage']
    } else {
        $Output.Remove('LDAPSBind')
        $Output.Remove('GlobalCatalogLDAPSBind')
    }
    if (-not $Advanced) {
        $Output.Remove('IPV4Address')
        $Output.Remove('OperatingSystem')
        $Output.Remove('IPV6Address')
        $Output.Remove('Site')
        $Output.Remove('IsRO')
        $Output.Remove('IsGC')
    }
    [PSCustomObject] $Output
}