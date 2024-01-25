function Test-LdapServer {
    [cmdletBinding()]
    param(
        [string] $ServerName,
        [string] $Computer,
        [PSCustomObject] $Advanced,
        [int] $GCPortLDAP = 3268,
        [int] $GCPortLDAPSSL = 3269,
        [int] $PortLDAP = 389,
        [int] $PortLDAPS = 636,
        [switch] $VerifyCertificate,
        [PSCredential] $Credential,
        [string] $Identity
    )
    if ($ServerName -notlike '*.*') {
        # $FQDN = $false
        # querying SSL won't work for non-fqdn, we check if after all our checks it's string with dot.
        $GlobalCatalogSSL = [PSCustomObject] @{ Status = $false; ErrorMessage = 'No FQDN' }
        $ConnectionLDAPS = [PSCustomObject] @{ Status = $false; ErrorMessage = 'No FQDN' }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            if (-not $Advanced) {
                $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Credential $Credential -Identity $Identity
            } else {
                if ($Advanced.IsGlobalCatalog) {
                    $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Credential $Credential -Identity $Identity
                } else {
                    $GlobalCatalogNonSSL = [PSCustomObject] @{ Status = $null; ErrorMessage = 'Not Global Catalog' }
                }
            }
            $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP -Credential $Credential -Identity $Identity
        } else {
            if (-not $Advanced) {
                $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Identity $Identity
            } else {
                if ($Advanced.IsGlobalCatalog) {
                    $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Identity $Identity
                } else {
                    $GlobalCatalogNonSSL = [PSCustomObject] @{ Status = $null; ErrorMessage = 'Not Global Catalog' }
                }
            }
            $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP -Identity $Identity
        }
    } else {
        if ($PSBoundParameters.ContainsKey('Credential')) {
            if (-not $Advanced) {
                $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL -Credential $Credential -Identity $Identity
                $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Credential $Credential -Identity $Identity
            } else {
                if ($Advanced.IsGlobalCatalog) {
                    $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL -Credential $Credential -Identity $Identity
                    $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Credential $Credential -Identity $Identity
                } else {
                    $GlobalCatalogSSL = [PSCustomObject] @{ Status = $null; ErrorMessage = 'Not Global Catalog' }
                    $GlobalCatalogNonSSL = [PSCustomObject] @{ Status = $null; ErrorMessage = 'Not Global Catalog' }
                }
            }
            $ConnectionLDAPS = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAPS -Credential $Credential -Identity $Identity
            $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP -Credential $Credential -Identity $Identity
        } else {
            if (-not $Advanced) {
                $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL -Identity $Identity
                $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Identity $Identity
            } else {
                if ($Advanced -and $Advanced.IsGlobalCatalog) {
                    $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL -Identity $Identity
                    $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP -Identity $Identity
                } else {
                    $GlobalCatalogSSL = [PSCustomObject] @{ Status = $null; ErrorMessage = 'Not Global Catalog' }
                    $GlobalCatalogNonSSL = [PSCustomObject] @{ Status = $null; ErrorMessage = 'Not Global Catalog' }
                }
            }
            $ConnectionLDAPS = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAPS -Identity $Identity
            $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP -Identity $Identity
        }
    }
    $PortsThatWork = @(
        if ($GlobalCatalogNonSSL.Status) { $GCPortLDAP }
        if ($GlobalCatalogSSL.Status) { $GCPortLDAPSSL }
        if ($ConnectionLDAP.Status) { $PortLDAP }
        if ($ConnectionLDAPS.Status) { $PortLDAPS }
    ) | Sort-Object

    $PortsIdentityStatus = @(
        if ($GlobalCatalogNonSSL.IdentityStatus) { $GCPortLDAP }
        if ($GlobalCatalogSSL.IdentityStatus) { $GCPortLDAPSSL }
        if ($ConnectionLDAP.IdentityStatus) { $PortLDAP }
        if ($ConnectionLDAPS.IdentityStatus) { $PortLDAPS }
    ) | Sort-Object

    $ListIdentityStatus = @(
        $GlobalCatalogSSL.IdentityStatus
        $GlobalCatalogNonSSL.IdentityStatus
        $ConnectionLDAP.IdentityStatus
        $ConnectionLDAPS.IdentityStatus
    )
    if ($ListIdentityStatus -contains $false) {
        $IsIdentical = $false
    } else {
        $IsIdentical = $true
    }

    if ($VerifyCertificate) {
        if ($PSBoundParameters.ContainsKey("Credential")) {
            $Certificate = Test-LDAPCertificate -Computer $ServerName -Port $PortLDAPS -Credential $Credential
            if (-not $Advanced) {
                $CertificateGC = Test-LDAPCertificate -Computer $ServerName -Port $GCPortLDAPSSL -Credential $Credential
            } else {
                if ($Advanced.IsGlobalCatalog) {
                    $CertificateGC = Test-LDAPCertificate -Computer $ServerName -Port $GCPortLDAPSSL -Credential $Credential
                } else {
                    $CertificateGC = [PSCustomObject] @{ Status = 'N/A'; ErrorMessage = 'Not Global Catalog' }
                }
            }
        } else {
            $Certificate = Test-LDAPCertificate -Computer $ServerName -Port $PortLDAPS
            if (-not $Advanced) {
                $CertificateGC = Test-LDAPCertificate -Computer $ServerName -Port $GCPortLDAPSSL
            } else {
                if ($Advanced.IsGlobalCatalog) {
                    $CertificateGC = Test-LDAPCertificate -Computer $ServerName -Port $GCPortLDAPSSL
                } else {
                    $CertificateGC = [PSCustomObject] @{ Status = 'N/A'; ErrorMessage = 'Not Global Catalog' }
                }
            }
        }
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

            Identity                = $Identity
            IdentityStatus          = $IsIdentical
            IdentityAvailablePorts  = $PortsIdentityStatus -join ','
            IdentityData            = $null
            IdentityErrorMessage    = $null

            IdentityGCLDAP          = $GlobalCatalogNonSSL.IdentityStatus
            IdentityGCLDAPS         = $GlobalCatalogSSL.IdentityStatus
            IdentityLDAP            = $ConnectionLDAP.IdentityStatus
            IdentityLDAPS           = $ConnectionLDAPS.IdentityStatus

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

            Identity               = $Identity
            IdentityStatus         = $IsIdentical
            IdentityAvailablePorts = $PortsIdentityStatus -join ','
            IdentityData           = $null
            IdentityErrorMessage   = $null

            OperatingSystem        = $Advanced.OperatingSystem
            IPV4Address            = $Advanced.IPV4Address
            IPV6Address            = $Advanced.IPV6Address
        }
    }
    if ($VerifyCertificate) {
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
    if ($Identity) {
        $Output['IdentityData'] = $ConnectionLDAP.IdentityData
        $Output['IdentityErrorMessage'] = $ConnectionLDAP.IdentityErrorMessage
    } else {
        $Output.Remove('Identity')
        $Output.Remove('IdentityStatus')
        $Output.Remove('IdentityAvailablePorts')
        $Output.Remove('IdentityData')
        $Output.Remove('IdentityErrorMessage')
        $Output.Remove('IdentityGCLDAP')
        $Output.Remove('IdentityGCLDAPS')
        $Output.Remove('IdentityLDAP')
        $Output.Remove('IdentityLDAPS')
    }
    if (-not $Advanced) {
        $Output.Remove('IPV4Address')
        $Output.Remove('OperatingSystem')
        $Output.Remove('IPV6Address')
        $Output.Remove('Site')
        $Output.Remove('IsRO')
        $Output.Remove('IsGC')
    }
    # lets return the objects if required
    if ($Extended) {
        $Output['GlobalCatalogSSL'] = $GlobalCatalogSSL
        $Output['GlobalCatalogNonSSL'] = $GlobalCatalogNonSSL
        $Output['ConnectionLDAP'] = $ConnectionLDAP
        $Output['ConnectionLDAPS'] = $ConnectionLDAPS
        $Output['Certificate'] = $Certificate
        $Output['CertificateGC'] = $CertificateGC
    }
    [PSCustomObject] $Output
}