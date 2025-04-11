function Get-WinADOrganization {
    [cmdletBinding()]
    param(

    )

    $ForestInformation = Get-WinADForestDetails
    $Organization = [ordered] @{
        Forest              = [System.Collections.Generic.List[PSCustomObject]]::new()
        Domains             = [System.Collections.Generic.List[PSCustomObject]]::new()
        OrganizationalUnits = [ordered] @{}
    }

    foreach ($Domain in $ForestInformation.Domains) {
        $CurrentDomainDN = ConvertTo-DistinguishedName -CanonicalName $Domain -ToDomain
        $Organization.Domains.Add(
            [PSCustomObject] @{
                Domain                   = $Domain
                Type                     = 'Domain'
                DistinguishedName        = $CurrentDomainDN
                Name                     = $Domain
                OrganizationalUnits      = @()
                OrganizationalUnitsCount = 0
            }
        )
        $Organization.OrganizationalUnits[$Domain] = @(
            $DomainOUs = Get-ADOrganizationalUnit -Filter "*" -Server $ForestInformation['QueryServers'][$Domain].HostName[0] -Properties DistinguishedName, CanonicalName
            foreach ($OU in $DomainOUs) {
                $SubOus = ConvertFrom-DistinguishedName -DistinguishedName $OU.DistinguishedName -ToMultipleOrganizationalUnit
                [Array] $OutputSubOu = @(
                    if ($SubOus) {
                        $SubOus
                    }
                    $CurrentDomainDN
                )
                $OUData = [PSCustomObject]@{
                    Domain                   = $Domain
                    Type                     = 'OrganizationalUnit'
                    DistinguishedName        = $OU.DistinguishedName
                    Name                     = $OU.Name
                    OrganizationalUnits      = $OutputSubOu
                    OrganizationalUnitsCount = $OutputSubOu.Count
                }

                $OUData
            }
        )
    }
    $Organization
}
