Describe 'Get-WinADObject should return proper data' {
    It 'Checks few names with and without NetBios' {
        $Object = @(
            'Administrators'
            'Domain Admins'
            'przemyslaw.klys'
            'EVOTECPL\Print Operators'
            'EVOTEC\Administrator'
            'EVOTECPL\Domain Computers'
            'EVOTECPL\Protected Users'
            'CN=S-1-5-4,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
            'NT AUTHORITY\INTERACTIVE'
            'NT AUTHORITY\IUSR'
            'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
            'S-1-5-4'
            'S-1-5-11'
            #'INTERACTIVE' # this will not be resolved
        )
        $Results = Get-WinADObject -Identity $Object
        $Results.Count | Should -Be $Object.Count
        $Results[0].Distinguishedname | Should -Be 'CN=Administrators,CN=Builtin,DC=ad,DC=evotec,DC=xyz'
        $Results[1].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=xyz'
        $Results[2].Distinguishedname | Should -Be 'CN=Przemysław Kłys,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
        $Results[3].Distinguishedname | Should -Be 'CN=Print Operators,CN=Builtin,DC=ad,DC=evotec,DC=pl'
        $Results[4].Distinguishedname | Should -Be 'CN=Administrator,OU=Special,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
        $Results[5].Distinguishedname | Should -Be 'CN=Domain Computers,CN=Users,DC=ad,DC=evotec,DC=pl'
        $Results[6].Distinguishedname | Should -Be 'CN=Protected Users,CN=Users,DC=ad,DC=evotec,DC=pl'
        $Results[7].Distinguishedname | Should -Be 'CN=S-1-5-4,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
        $Results[8].Distinguishedname | Should -Be 'CN=S-1-5-4,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
        $Results[9].Distinguishedname | Should -Be 'CN=S-1-5-17,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
        $Results[10].Distinguishedname | Should -Be 'CN=S-1-5-9,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
        $Results[11].Distinguishedname | Should -Be 'CN=S-1-5-4,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
        $Results[12].Distinguishedname | Should -Be 'CN=S-1-5-11,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
        $Results[0].ObjectClass | Should -Be 'group'
        $Results[1].ObjectClass | Should -Be 'group'
        $Results[2].ObjectClass | Should -Be 'user'
        $Results[3].ObjectClass | Should -Be 'group'
        $Results[4].ObjectClass | Should -Be 'user'
        $Results[5].ObjectClass | Should -Be 'group'
        $Results[6].ObjectClass | Should -Be 'group'
        $Results[7].ObjectClass | Should -Be 'foreignSecurityPrincipal'
        $Results[8].ObjectClass | Should -Be 'foreignSecurityPrincipal'
        $Results[9].ObjectClass | Should -Be 'foreignSecurityPrincipal'
        $Results[10].ObjectClass | Should -Be 'foreignSecurityPrincipal'
        $Results[11].ObjectClass | Should -Be 'foreignSecurityPrincipal'
        $Results[12].ObjectClass | Should -Be 'foreignSecurityPrincipal'
    }
}
Describe 'Get-WinADObject should return proper data' {
    It 'Checks few names with and without NetBios' {
        $Object = @(
            'Administrators'
            'Domain Admins'
            'Print Operators'
            'Administrator'
            'Domain Computers'
            'Protected Users'
        )
        $Results = Get-WinADObject -Identity $Object -DomainName 'test.evotec.pl'
        $Results.Count | Should -Be $Object.Count
        $Results[0].Distinguishedname | Should -Be 'CN=Administrators,CN=Builtin,DC=test,DC=evotec,DC=pl'
        $Results[1].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[2].Distinguishedname | Should -Be 'CN=Print Operators,CN=Builtin,DC=test,DC=evotec,DC=pl'
        $Results[3].Distinguishedname | Should -Be 'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[4].Distinguishedname | Should -Be 'CN=Domain Computers,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[5].Distinguishedname | Should -Be 'CN=Protected Users,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[0].ObjectClass | Should -Be 'group'
        $Results[1].ObjectClass | Should -Be 'group'
        $Results[2].ObjectClass | Should -Be 'group'
        $Results[3].ObjectClass | Should -Be 'user'
        $Results[4].ObjectClass | Should -Be 'group'
        $Results[5].ObjectClass | Should -Be 'group'
    }
}
Describe 'Get-WinADObject should return proper data for SID, DN and NETBIOS' {
    It 'Checks few names with and without NetBios' {
        $Object = @(
            'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
            'S-1-5-21-1928204107-2710010574-1926425344-500' # CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl
            'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
            'S-1-5-21-1928204107-2710010574-1926425344-512' # CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl
            'CN=S-1-5-21-1928204107-2710010574-1926425344-512,CN=ForeignSecurityPrincipals,DC=ad,DC=evotec,DC=xyz'
            'TEST\Domain Admins'
            'EVOTECPL\Domain Admins'
            'BUILTIN\Administrators'
            'S-1-5-21-1928204107-2710010574-1926425344-500' # CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl
            'S-1-5-21-3661168273-3802070955-2987026695-512' # CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=pl
            'EVOWIN'
            'CN=DnsAdmins,CN=Users,DC=ad,DC=evotec,DC=pl'
            'S-1-5-21-3661168273-3802070955-2987026695-1101' # 'CN=DnsAdmins,CN=Users,DC=ad,DC=evotec,DC=pl'
        )
        $Results = Get-WinADObject -Identity $Object
        $Results.Count | Should -Be $Object.Count
        $Results[0].Distinguishedname | Should -Be 'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[1].Distinguishedname | Should -Be 'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[2].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[3].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[4].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[5].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[6].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=pl'
        $Results[7].Distinguishedname | Should -Be 'CN=Administrators,CN=Builtin,DC=ad,DC=evotec,DC=xyz'
        $Results[8].Distinguishedname | Should -Be 'CN=Administrator,CN=Users,DC=test,DC=evotec,DC=pl'
        $Results[9].Distinguishedname | Should -Be 'CN=Domain Admins,CN=Users,DC=ad,DC=evotec,DC=pl'
        $Results[10].Distinguishedname | Should -Be 'CN=EVOWIN,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
        $Results[11].Distinguishedname | Should -Be 'CN=DnsAdmins,CN=Users,DC=ad,DC=evotec,DC=pl'
        $Results[12].Distinguishedname | Should -Be 'CN=DnsAdmins,CN=Users,DC=ad,DC=evotec,DC=pl'
        $Results[0].ObjectClass | Should -Be 'user'
        $Results[1].ObjectClass | Should -Be 'user'
        $Results[2].ObjectClass | Should -Be 'group'
        $Results[3].ObjectClass | Should -Be 'group'
        $Results[4].ObjectClass | Should -Be 'group'
        $Results[5].ObjectClass | Should -Be 'group'
        $Results[6].ObjectClass | Should -Be 'group'
        $Results[7].ObjectClass | Should -Be 'group'
        $Results[8].ObjectClass | Should -Be 'user'
        $Results[9].ObjectClass | Should -Be 'group'
        $Results[10].ObjectClass | Should -Be 'computer'
        $Results[0].DomainName | Should -Be 'test.evotec.pl'
        $Results[1].DomainName | Should -Be 'test.evotec.pl'
        $Results[2].DomainName | Should -Be 'test.evotec.pl'
        $Results[3].DomainName | Should -Be 'test.evotec.pl'
        $Results[4].DomainName | Should -Be 'test.evotec.pl'
        $Results[5].DomainName | Should -Be 'test.evotec.pl'
        $Results[6].DomainName | Should -Be 'ad.evotec.pl'
        $Results[7].DomainName | Should -Be 'ad.evotec.xyz'
        $Results[8].DomainName | Should -Be 'test.evotec.pl'
        $Results[9].DomainName | Should -Be 'ad.evotec.pl'
        $Results[10].DomainName | Should -Be 'ad.evotec.xyz'
        $Results[11].DomainName | Should -Be 'ad.evotec.pl'
        $Results[12].DomainName | Should -Be 'ad.evotec.pl'
    }
}