function Get-WinADTrustObject {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][alias('Domain')][string] $Identity,
        [switch] $AsHashTable
    )
    $Summary = [ordered] @{}

    # https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectory.trusttype?view=dotnet-plat-ext-3.1
    $TrustType = @{
        CrossLink   = 'The trust relationship is a shortcut between two domains that exists to optimize the authentication processing between two domains that are in separate domain trees.' # 2
        External    = 'The trust relationship is with a domain outside of the current forest.' # 3
        Forest      = 'The trust relationship is between two forest root domains in separate Windows Server 2003 forests.' # 4
        Kerberos    = 'The trusted domain is an MIT Kerberos realm.' # 5
        ParentChild	= 'The trust relationship is between a parent and a child domain.' # 1
        TreeRoot    = 'One of the domains in the trust relationship is a tree root.' # 0
        Unknown     = 'The trust is a non-specific type.' #6
    }
    # https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectory.trustdirection?view=dotnet-plat-ext-3.1
    $TrustDirection = @{
        Bidirectional	= 'Each domain or forest has access to the resources of the other domain or forest.' # 3
        Inbound       = 'This is a trusting domain or forest. The other domain or forest has access to the resources of this domain or forest. This domain or forest does not have access to resources that belong to the other domain or forest.' # 1
        Outbound      = 'This is a trusted domain or forest. This domain or forest has access to resources of the other domain or forest. The other domain or forest does not have access to the resources of this domain or forest.' # 2
    }

    if ($Identity -contains 'DC=') {
        $DomainName = "LDAP://$Domain"
        $TrustSource = ConvertFrom-DistinguishedName -DistinguishedName $DomainName -ToDomainCN
    } else {
        $DomainDN = ConvertTo-DistinguishedName -CanonicalName $Identity -ToDomain
        $DomainName = "LDAP://$DomainDN"
        $TrustSource = $Identity
    }
    $searcher = [adsisearcher]'(objectClass=trustedDomain)'
    $searcher.SearchRoot = [adsi] $DomainName   #'LDAP://DC=TEST,DC=EVOTEC,DC=PL'
    $Trusts = $searcher.FindAll()

    foreach ($Trust in $Trusts) {
        $TrustD = [System.DirectoryServices.ActiveDirectory.TrustDirection] $Trust.properties.trustdirection[0]
        $TrustT = [System.DirectoryServices.ActiveDirectory.TrustType] $Trust.properties.trusttype[0]


        if ($Trust.properties.'msds-trustforesttrustinfo') {
            $msDSTrustForestTrustInfo = Convert-TrustForestTrustInfo -msDSTrustForestTrustInfo $Trust.properties.'msds-trustforesttrustinfo'[0]
        } else {
            $msDSTrustForestTrustInfo = $null
        }
        if ($Trust.properties.trustattributes) {
            $TrustAttributes = Get-ADTrustAttributes -Value ([int] $Trust.properties.trustattributes[0])
        } else {
            $TrustAttributes = $null
        }
        if ($Trust.properties.securityidentifier) {
            try {
                $ObjectSID = [System.Security.Principal.SecurityIdentifier]::new($Trust.properties.securityidentifier[0], 0).Value
            } catch {
                $ObjectSID = $null
            }
        } else {
            $ObjectSID = $null
        }

        $TrustObject = [PSCustomObject] @{
            #Name                   = [string] $Trust.properties.name              #        {ad.evotec.xyz}
            TrustSource                  = $TrustSource
            TrustPartner                 = [string] $Trust.properties.trustpartner           #        {ad.evotec.xyz}
            TrustPartnerNetBios          = [string] $Trust.properties.flatname               #        {EVOTEC}
            TrustDirection               = $TrustD.ToString()         #        {3}
            TrustType                    = $TrustT.ToString()             #        {2}
            TrustAttributes              = $TrustAttributes       #        {32}
            TrustDirectionText           = $TrustDirection[$TrustD.ToString()]
            TrustTypeText                = $TrustType[$TrustT.ToString()]
            WhenCreated                  = [DateTime] $Trust.properties.whencreated[0]         #        {26.07.2018 10:59:52}
            WhenChanged                  = [DateTime] $Trust.properties.whenchanged[0]            #        {14.08.2020 22:23:14}
            ObjectSID                    = $ObjectSID
            Distinguishedname            = [string] $Trust.properties.distinguishedname      #        {CN=ad.evotec.xyz,CN=System,DC=ad,DC=evotec,DC=pl}
            IsCriticalSystemObject       = [bool]::Parse($Trust.properties.iscriticalsystemobject[0]) #        {True}
            ObjectGuid                   = [guid]::new($Trust.properties.objectguid[0])
            ObjectCategory               = [string] $Trust.properties.objectcategory         #        {CN=Trusted-Domain,CN=Schema,CN=Configuration,DC=ad,DC=evotec,DC=xyz}
            ObjectClass                  = ([array] $Trust.properties.objectclass)[-1]           #        {top, leaf, trustedDomain}
            UsnCreated                   = [string] $Trust.properties.usncreated             #        {14149}
            UsnChanged                   = [string] $Trust.properties.usnchanged             #        {4926091}
            ShowInAdvancedViewOnly       = [bool]::Parse($Trust.properties.showinadvancedviewonly) #        {True}
            TrustPosixOffset             = [string] $Trust.properties.trustposixoffset       #        {-2147483648}
            msDSTrustForestTrustInfo     = $msDSTrustForestTrustInfo
            msDSSupportedEncryptionTypes = if ($Trust.properties.'msds-supportedencryptiontypes') { Get-ADEncryptionTypes -Value ([int] $Trust.properties.'msds-supportedencryptiontypes'[0]) } else { $null }
            #SecurityIdentifier     = [string] $Trust.properties.securityidentifier     #        {1 4 0 0 0 0 0 5 21 0 0 0 113 37 225 50 27 133 23 171 67 175 144 188}
            #InstanceType           = $Trust.properties.instancetype           #        {4}
            #AdsPath                = [string] $Trust.properties.adspath                #        {LDAP://CN=ad.evotec.xyz,CN=System,DC=ad,DC=evotec,DC=pl}
            #CN                     = [string] $Trust.properties.cn                     #        {ad.evotec.xyz}
            #ObjectGuid             = $Trust.properties.objectguid             #        {193 58 187 220 218 30 146 77 162 218 90 74 159 98 153 219}
            #dscorepropagationdata  = $Trust.properties.dscorepropagationdata  #        {01.01.1601 00:00:00}

        }
        if ($AsHashTable) {
            $Summary[$TrustObject.trustpartner] = $TrustObject
        } else {
            $TrustObject
        }
    }
    if ($AsHashTable) {
        $Summary
    }
}