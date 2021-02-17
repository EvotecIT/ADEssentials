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
        # Checks for ServerName - Makes sure to convert IPAddress to DNS
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Test-LDAP - Processing $Computer"
            [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue)
            if ($ADServerFQDN) {
                if ($ADServerFQDN.NameHost) {
                    $ServerName = $ADServerFQDN[0].NameHost
                } else {
                    [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue)
                    $FilterName = $ADServerFQDN | Where-Object { $_.QueryType -eq 'A' }
                    $ServerName = $FilterName[0].Name
                }
            } else {
                $ServerName = ''
            }

            $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL
            $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP
            $ConnectionLDAPS = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAPS
            $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP

            $PortsThatWork = @(
                if ($GlobalCatalogNonSSL) { $GCPortLDAP }
                if ($GlobalCatalogSSL) { $GCPortLDAPSSL }
                if ($ConnectionLDAP) { $PortLDAP }
                if ($ConnectionLDAPS) { $PortLDAPS }
            ) | Sort-Object
            $Output = [ordered] @{
                Computer           = $Computer
                ComputerFQDN       = $ServerName
                GlobalCatalogLDAP  = $GlobalCatalogNonSSL
                GlobalCatalogLDAPS = $GlobalCatalogSSL
                LDAP               = $ConnectionLDAP
                LDAPS              = $ConnectionLDAPS
                AvailablePorts     = $PortsThatWork -join ','
            }
            if ($VerifyCertificate) {
                Write-Verbose "Test-LDAP - Processing $Computer / Verifying Certificate"
                # code based on ChrisDent
                $connection = $null
                $directoryIdentifier = [DirectoryServices.Protocols.LdapDirectoryIdentifier]::new($Computer, $PortLDAPS)
                if ($psboundparameters.ContainsKey("Credential")) {
                    $connection = [DirectoryServices.Protocols.LdapConnection]::new($directoryIdentifier, $Credential.GetNetworkCredential())
                    $connection.AuthType = [DirectoryServices.Protocols.AuthType]::Basic
                } else {
                    $connection = [DirectoryServices.Protocols.LdapConnection]::new($directoryIdentifier)
                    $connection.AuthType = [DirectoryServices.Protocols.AuthType]::Kerberos
                }
                $connection.SessionOptions.ProtocolVersion = 3
                $connection.SessionOptions.SecureSocketLayer = $true

                # Declare a script level variable which can be used to return information from the delegate.
                New-Variable LdapCertificate -Scope Script -Force

                # Create a callback delegate to retrieve the negotiated certificate.
                # Note:
                #   * The certificate is unlikely to return the subject.
                #   * The delegate is documented as using the X509Certificate type, automatically casting this to X509Certificate2 allows access to more information.
                $connection.SessionOptions.VerifyServerCertificate = {
                    param(
                        [DirectoryServices.Protocols.LdapConnection]$Connection,
                        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
                    )
                    $Script:LdapCertificate = $Certificate
                    return $true
                }

                $state = "Connected"
                try {
                    $connection.Bind()
                } catch {
                    $state = "Failed ($($_.Exception.InnerException.Message.Trim()))"
                }
                $KeyExchangeAlgorithm = @{
                    # https://docs.microsoft.com/en-us/dotnet/api/system.security.authentication.exchangealgorithmtype?view=netcore-3.1
                    '0'     = 'None' # No key exchange algorithm is used.
                    '43522' = 'DiffieHellman' # The Diffie Hellman ephemeral key exchange algorithm.
                    '41984' = 'RsaKeyX' # The RSA public-key exchange algorithm.
                    '9216'  = 'RsaSign' # The RSA public-key signature algorithm.
                    '44550' = 'ECDH_Ephem'
                }

                $Certificate = [ordered]@{
                    State                   = $state
                    Protocol                = $connection.SessionOptions.SslInformation.Protocol
                    AlgorithmIdentifier     = $connection.SessionOptions.SslInformation.AlgorithmIdentifier
                    CipherStrength          = $connection.SessionOptions.SslInformation.CipherStrength
                    Hash                    = $connection.SessionOptions.SslInformation.Hash
                    HashStrength            = $connection.SessionOptions.SslInformation.HashStrength
                    KeyExchangeAlgorithm    = $KeyExchangeAlgorithm["$($Connection.SessionOptions.SslInformation.KeyExchangeAlgorithm)"]
                    ExchangeStrength        = $connection.SessionOptions.SslInformation.ExchangeStrength
                    X509FriendlyName        = $Script:LdapCertificate.FriendlyName
                    X509SendAsTrustedIssuer = $Script:LdapCertificate.SendAsTrustedIssuer
                    X509NotAfter            = $Script:LdapCertificate.NotAfter
                    X509NotBefore           = $Script:LdapCertificate.NotBefore
                    X509SerialNumber        = $Script:LdapCertificate.SerialNumber
                    X509Thumbprint          = $Script:LdapCertificate.Thumbprint
                    X509SubjectName         = $Script:LdapCertificate.Subject
                    X509Issuer              = $Script:LdapCertificate.Issuer
                    X509HasPrivateKey       = $Script:LdapCertificate.HasPrivateKey
                    X509Version             = $Script:LdapCertificate.Version
                    X509Archived            = $Script:LdapCertificate.Archived

                }
                $Output = $Output + $Certificate
            }
            [PSCustomObject] $Output
        }
    }
}