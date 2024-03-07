function Test-WinADDNSResolving {
    <#
    .SYNOPSIS
    Test DNS resolving for specific DNS record type across all Domain Controllers in the forest.

    .DESCRIPTION
    Test DNS resolving for specific DNS record type across all Domain Controllers in the forest.

    .PARAMETER Name
    Name of the DNS record to resolve

    .PARAMETER Type
    Type of the DNS record to resolve

    .PARAMETER Forest
    Forest name to use for resolving. If not given it will use current forest.

    .PARAMETER ExcludeDomains
    Exclude specific domains from test

    .PARAMETER ExcludeDomainControllers
    Exclude specific domain controllers from test

    .PARAMETER IncludeDomains
    Include specific domains in test

    .PARAMETER IncludeDomainControllers
    Include specific domain controllers in test

    .PARAMETER SkipRODC
    Skip Read Only Domain Controllers when querying for information

    .PARAMETER NotDNSOnly
    Do not use DNS only switch for resolving DNS names

    .EXAMPLE
    @(
        Test-WinADDNSResolving -Name "PILAFU085.ad.evotec.xyz" -Type "A" -Verbose -IncludeDomains 'ad.evotec.xyz'
        Test-WinADDNSResolving -Name "15.241.168.192.in-addr.arpa" -Type "PTR" -Verbose
        Test-WinADDNSResolving -Name "192.168.241.15" -Type "PTR" -Verbose
        Test-WinADDNSResolving -Name "Evo-win.ad.evotec.xyz" -Type "CNAME" -Verbose
        Test-WinADDNSResolving -Name "test.domain.pl" -Type "MX" -Verbose
    ) | Format-Table

    .OUTPUTS
    Name                        Type  DC                  Resolving Identical ErrorMessage ResolvedName                ResolvedData
    ----                        ----  --                  --------- --------- ------------ ------------                ------------
    PILAFU085.ad.evotec.xyz     A     AD2.ad.evotec.xyz        True      True              PILAFU085.ad.evotec.xyz     10.104.65.85
    PILAFU085.ad.evotec.xyz     A     AD1.ad.evotec.xyz        True      True              PILAFU085.ad.evotec.xyz     10.104.65.85
    PILAFU085.ad.evotec.xyz     A     AD0.ad.evotec.xyz        True      True              PILAFU085.ad.evotec.xyz     10.104.65.85
    15.241.168.192.in-addr.arpa PTR   AD2.ad.evotec.xyz        True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    15.241.168.192.in-addr.arpa PTR   AD1.ad.evotec.xyz        True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    15.241.168.192.in-addr.arpa PTR   AD0.ad.evotec.xyz        True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    15.241.168.192.in-addr.arpa PTR   DC1.ad.evotec.pl         True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    15.241.168.192.in-addr.arpa PTR   ADRODC.ad.evotec.pl      True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    192.168.241.15              PTR   AD2.ad.evotec.xyz        True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    192.168.241.15              PTR   AD1.ad.evotec.xyz        True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    192.168.241.15              PTR   AD0.ad.evotec.xyz        True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    192.168.241.15              PTR   DC1.ad.evotec.pl         True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    192.168.241.15              PTR   ADRODC.ad.evotec.pl      True      True              15.241.168.192.in-addr.arpa ADConnect.ad.evotec.xyz
    Evo-win.ad.evotec.xyz       CNAME AD2.ad.evotec.xyz        True      True              Evo-win.ad.evotec.xyz       EVOWIN.ad.evotec.xyz
    Evo-win.ad.evotec.xyz       CNAME AD1.ad.evotec.xyz        True      True              Evo-win.ad.evotec.xyz       EVOWIN.ad.evotec.xyz
    Evo-win.ad.evotec.xyz       CNAME AD0.ad.evotec.xyz        True      True              Evo-win.ad.evotec.xyz       EVOWIN.ad.evotec.xyz
    Evo-win.ad.evotec.xyz       CNAME DC1.ad.evotec.pl         True      True              Evo-win.ad.evotec.xyz       EVOWIN.ad.evotec.xyz
    Evo-win.ad.evotec.xyz       CNAME ADRODC.ad.evotec.pl      True      True              Evo-win.ad.evotec.xyz       EVOWIN.ad.evotec.xyz
    test.domain.pl              MX    AD2.ad.evotec.xyz        True      True              test.domain.pl              10 office.com
    test.domain.pl              MX    AD1.ad.evotec.xyz        True      True              test.domain.pl              10 office.com
    test.domain.pl              MX    AD0.ad.evotec.xyz        True      True              test.domain.pl              10 office.com
    test.domain.pl              MX    DC1.ad.evotec.pl         True      True              test.domain.pl              10 office.com
    test.domain.pl              MX    ADRODC.ad.evotec.pl      True      True              test.domain.pl              10 office.com

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]] $Name,
        [Parameter(Mandatory)][ValidateSet('PTR', 'A', 'AAAA', 'MX', 'CNAME', 'SRV')][string] $Type,

        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,

        [switch] $NotDNSOnly
    )

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExcludeDomainControllers $ExcludeDomainControllers -IncludeDomainControllers $IncludeDomainControllers -SkipRODC:$SkipRODC -ExtendedForestInformation $ExtendedForestInformation -Extended
    $StatusIdentical = [ordered] @{}
    foreach ($N in $Name) {
        foreach ($DC in $ForestInformation.ForestDomainControllers) {
            Write-Verbose -Message "Test-WinADDNSResolving - Processing $N on $($DC.Hostname)"
            try {
                $ResolvedDNS = Resolve-DnsName -Name $N -Server $DC.Hostname -Type $Type -ErrorAction Stop -DnsOnly:(-not $NotDNSOnly) -Verbose:$false
                $ErrorMessage = $null
            } catch {
                $ErrorMessage = $_.Exception.Message
                $ResolvedDNS = $null
                Write-Warning -Message "Test-WinADDNSResolving - Failed to resolve $N on $($DC.HostName). Error: $($_.Exception.Message)"
            }
            $Status = $false
            $ResolvedName = $null
            $ResolvedData = $null

            if ($ResolvedDNS) {
                if ($ResolvedDNS.Type -eq 'SOA') {
                    $Status = $false
                } else {
                    if ($Type -eq "PTR") {
                        $ResolvedName = $ResolvedDNS.Name
                        $ResolvedData = $ResolvedDNS.NameHost
                        $Status = $true
                    } elseif ($Type -eq "A") {
                        $ResolvedName = $ResolvedDNS.Name
                        $ResolvedData = $ResolvedDNS.IPAddress
                        $Status = $true
                    } elseif ($Type -eq 'AAAA') {
                        $ResolvedName = $ResolvedDNS.Name
                        $ResolvedData = $ResolvedDNS.IPAddress
                        $Status = $true
                    } elseif ($Type -eq "SRV") {
                        $ResolvedName = $ResolvedDNS.Name
                        $ResolvedData = $ResolvedDNS.NameTarget
                        $Status = $true
                    } elseif ($Type -eq 'CNAME') {
                        $ResolvedName = $ResolvedDNS.Name
                        $ResolvedData = $ResolvedDNS.NameHost
                        $Status = $true
                    } elseif ($Type -eq 'MX') {
                        $OnlyMX = $ResolvedDNS | Where-Object { $_.QueryType -eq 'MX' }
                        if ($OnlyMX) {
                            $ResolvedName = $OnlyMX.Name
                            $ResolvedData = "$($OnlyMX.Preference) $($OnlyMX.NameExchange)"
                            $Status = $true
                        } else {
                            $ResolvedName = $null
                            $ResolvedData = $null
                            $Status = $false
                        }
                    } else {
                        $ResolvedName = $ResolvedDNS.Name
                        $ResolvedData = $ResolvedDNS.NameHost
                        $Status = $true
                    }
                }
            }

            if (-not $StatusIdentical[$N]) {
                $StatusIdentical[$N] = $ResolvedData
                $Identical = $true
            } else {
                if ($StatusIdentical[$N] -ne $ResolvedData) {
                    $Identical = $false
                } else {
                    $Identical = $true
                }
            }

            [PSCustomObject] @{
                Name         = $N
                Type         = $Type
                DC           = $DC.Hostname
                Resolving    = $Status
                Identical    = $Identical
                ErrorMessage = $ErrorMessage
                ResolvedName = $ResolvedName
                ResolvedData = $ResolvedData
            }
        }
    }
}