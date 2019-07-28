Function Test-LDAP {
    [CmdletBinding()]
    param (
        [alias('Server', 'IpAddress')][Parameter(Mandatory = $True)][string[]]$ComputerName,
        [int] $GCPortLDAP = 3268,
        [int] $GCPortLDAPSSL = 3269,
        [int] $PortLDAP = 389,
        [int] $PortLDAPS = 636
    )
    # Checks for ServerName - Makes sure to convert IPAddress to DNS
    foreach ($Computer in $ComputerName) {
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
            if ($GlobalCatalogNonSSL.Status) { $GCPortLDAP }
            if ($GlobalCatalogSSL.Status) { $GCPortLDAPSSL }
            if ($ConnectionLDAP.Status) { $PortLDAP }
            if ($ConnectionLDAPS.Status) { $PortLDAPS }
        ) | Sort-Object
        <#
        $Comments = @(
            $GlobalCatalogNonSSL.Comment
            $GlobalCatalogSSL.Comment
            $ConnectionLDAP.Comment
            $ConnectionLDAPS.Comment
        ) | Sort-Object -Unique
        #>
        [pscustomobject]@{
            Computer           = $Computer
            ComputerFQDN       = $ServerName
            GlobalCatalogLDAP  = $GlobalCatalogNonSSL.Status
            GlobalCatalogLDAPS = $GlobalCatalogSSL.Status
            LDAP               = $ConnectionLDAP.Status
            LDAPS              = $ConnectionLDAPS.Status
            AvailablePorts     = $PortsThatWork -join ','
            #Comment            = $Comments -join ';'
        }
    }
}