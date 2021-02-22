﻿function Test-LDAPCertificate {
    [CmdletBinding()]
    param(
        [string] $Computer,
        [int] $Port,
        [PSCredential] $Credential
    )
    $Date = Get-Date
    if ($Credential) {
        Write-Verbose "Test-LDAPCertificate - Certificate verification $Computer/$Port/Auth Basic"
    } else {
        Write-Verbose "Test-LDAPCertificate - Certificate verification $Computer/$Port/Auth Kerberos"
    }
    # code based on ChrisDent
    $Connection = $null
    $DirectoryIdentifier = [DirectoryServices.Protocols.LdapDirectoryIdentifier]::new($Computer, $Port)
    if ($psboundparameters.ContainsKey("Credential")) {
        $Connection = [DirectoryServices.Protocols.LdapConnection]::new($DirectoryIdentifier, $Credential.GetNetworkCredential())
        $Connection.AuthType = [DirectoryServices.Protocols.AuthType]::Basic
    } else {
        $Connection = [DirectoryServices.Protocols.LdapConnection]::new($DirectoryIdentifier)
        $Connection.AuthType = [DirectoryServices.Protocols.AuthType]::Kerberos
    }
    $Connection.SessionOptions.ProtocolVersion = 3
    $Connection.SessionOptions.SecureSocketLayer = $true

    # Declare a script level variable which can be used to return information from the delegate.
    New-Variable LdapCertificate -Scope Script -Force

    # Create a callback delegate to retrieve the negotiated certificate.
    # Note:
    #   * The certificate is unlikely to return the subject.
    #   * The delegate is documented as using the X509Certificate type, automatically casting this to X509Certificate2 allows access to more information.
    $Connection.SessionOptions.VerifyServerCertificate = {
        param(
            [DirectoryServices.Protocols.LdapConnection]$Connection,
            [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
        )
        $Script:LdapCertificate = $Certificate
        return $true
    }

    $State = $true
    try {
        $Connection.Bind()
        $ErrorMessage = ''
    } catch {
        $State = $false
        $ErrorMessage = $_.Exception.Message.Trim()
    }
    $KeyExchangeAlgorithm = @{
        # https://docs.microsoft.com/en-us/dotnet/api/system.security.authentication.exchangealgorithmtype?view=netcore-3.1
        '0'     = 'None' # No key exchange algorithm is used.
        '43522' = 'DiffieHellman' # The Diffie Hellman ephemeral key exchange algorithm.
        '41984' = 'RsaKeyX' # The RSA public-key exchange algorithm.
        '9216'  = 'RsaSign' # The RSA public-key signature algorithm.
        '44550' = 'ECDH_Ephem'
    }

    if ($Script:LdapCertificate.NotBefore -is [DateTime]) {
        $X509NotBeforeDays = (New-TimeSpan -Start $Date -End $Script:LdapCertificate.NotBefore).Days
    } else {
        $X509NotBeforeDays = $null
    }
    if ($Script:LdapCertificate.NotAfter -is [DateTime]) {
        $X509NotAfterDays = (New-TimeSpan -Start $Date -End $Script:LdapCertificate.NotAfter).Days
    } else {
        $X509NotAfterDays = $null
    }

    $Certificate = [ordered]@{
        State                   = $State
        X509NotBeforeDays       = $X509NotBeforeDays
        X509NotAfterDays        = $X509NotAfterDays
        X509DnsNameList         = $Script:LdapCertificate.DnsNameList.Unicode
        X509NotBefore           = $Script:LdapCertificate.NotBefore
        X509NotAfter            = $Script:LdapCertificate.NotAfter
        AlgorithmIdentifier     = $Connection.SessionOptions.SslInformation.AlgorithmIdentifier
        CipherStrength          = $Connection.SessionOptions.SslInformation.CipherStrength
        X509FriendlyName        = $Script:LdapCertificate.FriendlyName
        X509SendAsTrustedIssuer = $Script:LdapCertificate.SendAsTrustedIssuer
        X509SerialNumber        = $Script:LdapCertificate.SerialNumber
        X509Thumbprint          = $Script:LdapCertificate.Thumbprint
        X509SubjectName         = $Script:LdapCertificate.Subject
        X509Issuer              = $Script:LdapCertificate.Issuer
        X509HasPrivateKey       = $Script:LdapCertificate.HasPrivateKey
        X509Version             = $Script:LdapCertificate.Version
        X509Archived            = $Script:LdapCertificate.Archived
        Protocol                = $Connection.SessionOptions.SslInformation.Protocol
        Hash                    = $Connection.SessionOptions.SslInformation.Hash
        HashStrength            = $Connection.SessionOptions.SslInformation.HashStrength
        KeyExchangeAlgorithm    = $KeyExchangeAlgorithm["$($Connection.SessionOptions.SslInformation.KeyExchangeAlgorithm)"]
        ExchangeStrength        = $Connection.SessionOptions.SslInformation.ExchangeStrength
        ErrorMessage            = $ErrorMessage
    }
    $Certificate
}