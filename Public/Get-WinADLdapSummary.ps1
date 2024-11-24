function Get-WinADLDAPSummary {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        $Identity,
        [int] $RetryCount = 3,
        [switch] $Extended
    )

    Write-Color -Text '[i] ', "Testing LDAP on all servers" -Color Yellow, White, Yellow
    $CachedServers = [ordered] @{}

    $testLDAPSplat = @{
        VerifyCertificate        = $true
        Identity                 = $Identity
        RetryCount               = $RetryCount
        IncludeDomains           = $IncludeDomains
        ExcludeDomains           = $ExcludeDomains
        IncludeDomainControllers = $IncludeDomainControllers
        ExcludeDomainControllers = $ExcludeDomainControllers
        SkipRODC                 = $SkipRODC
        Forest                   = $Forest
    }
    if ($Credential) {
        $testLDAPSplat['Credential'] = $Credential
    }
    Remove-EmptyValue -Hashtable $testLDAPSplat
    Test-LDAP @testLDAPSplat | ForEach-Object {
        $Server = $_
        Write-Color -Text "Testing LDAP on ", $Server.Computer -Color Yellow, White, Yellow
        $CachedServers[$Server.Computer] = $Server
    }

    $AllServers = $CachedServers.Values

    $Output = [ordered] @{
        Status                        = $true
        List                          = $AllServers
        Count                         = $AllServers.Count
        ServersExpiringMoreThan30Days = [System.Collections.Generic.List[string]]::new()
        ServersExpiringIn30Days       = [System.Collections.Generic.List[string]]::new()
        ServersExpiringIn15Days       = [System.Collections.Generic.List[string]]::new()
        ServersExpiringIn7Days        = [System.Collections.Generic.List[string]]::new()
        ServersExpiringIn3DaysOrLess  = [System.Collections.Generic.List[string]]::new()
        ServersExpired                = [System.Collections.Generic.List[string]]::new()
        FailedServers                 = [System.Collections.Generic.List[PSCustomObject]]::new()
        FailedServersCount            = 0
        GoodServers                   = [System.Collections.Generic.List[PSCustomObject]]::new()
        GoodServersCount              = 0
        IncludeDomains                = $IncludeDomains
        ExcludeDomains                = $ExcludeDomains
        IncludeDomainControllers      = $IncludeDomainControllers
        ExcludeDomainControllers      = $ExcludeDomainControllers
        SkipRODC                      = $SkipRODC.IsPresent
        Forest                        = $Forest
        # ExternalServers         = [ordered] @{
        #     List                          = $ExternalServersOutput
        #     Count                         = $ExternalServersOutput.Count
        #     ServersExpiringMoreThan30Days = [System.Collections.Generic.List[string]]::new()
        #     ServersExpiringIn30Days       = [System.Collections.Generic.List[string]]::new()
        #     ServersExpiringIn15Days       = [System.Collections.Generic.List[string]]::new()
        #     ServersExpiringIn7Days        = [System.Collections.Generic.List[string]]::new()
        #     ServersExpiringIn3DaysOrLess  = [System.Collections.Generic.List[string]]::new()
        #     ServersExpired                = [System.Collections.Generic.List[string]]::new()
        #     FailedServers                 = [System.Collections.Generic.List[PSCustomObject]]::new()
        #     FailedServersCount            = $null
        #     GoodServers                   = [System.Collections.Generic.List[PSCustomObject]]::new()
        #     GoodServersCount              = $null
        # }
    }

    foreach ($Server in $AllServers) {
        if ($null -ne $Server.X509NotAfterDays) {
            if ($Server.X509NotAfterDays -lt 0) {
                $Output.ServersExpired.Add($Server.Computer)
            } elseif ($Server.X509NotAfterDays -le 3) {
                $Output.ServersExpiringIn3DaysOrLess.Add($Server.Computer)
            } elseif ($Server.X509NotAfterDays -le 7) {
                $Output.ServersExpiringIn7Days.Add($Server.Computer)
            } elseif ($Server.X509NotAfterDays -le 15) {
                $Output.ServersExpiringIn15Days.Add($Server.Computer)
            } elseif ($Server.X509NotAfterDays -le 30) {
                $Output.ServersExpiringIn30Days.Add($Server.Computer)
            } else {
                $Output.ServersExpiringMoreThan30Days.Add($Server.Computer)
            }
        }
        if ($Server.StatusDate -eq 'Failed' -or $Server.StatusPorts -eq 'Failed' -or $Server.StatusIdentity -eq 'Failed') {
            $Output.FailedServers.Add($Server)
            $Output.Status = $false
        } else {
            $Output.GoodServers.Add($Server)
        }
    }
    if ($Extended) {
        $Output
    } else {
        $Output.List
    }
}