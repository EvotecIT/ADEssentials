function Get-WinADForestSubnet {
    [alias('Get-WinADSubnet')]
    [cmdletBinding()]
    param(
        [string] $Forest,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [switch] $VerifyOverlap
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    $QueryServer = $ForestInformation.QueryServers[$($ForestInformation.Forest.Name)]['HostName'][0]
    $ForestDN = ConvertTo-DistinguishedName -ToDomain -CanonicalName $ForestInformation.Forest.Name

    $ADObjectSplat = @{
        Server      = $QueryServer
        LDAPFilter  = '(objectClass=subnet)'
        SearchBase  = "CN=Subnets,CN=Sites,CN=Configuration,$($($ForestDN))"
        SearchScope = 'OneLevel'
        Properties  = 'Name', 'distinguishedName', 'CanonicalName', 'WhenCreated', 'whenchanged', 'ProtectedFromAccidentalDeletion', 'siteObject', 'location', 'objectClass', 'Description'
    }
    try {
        $Subnets = Get-ADObject @ADObjectSplat -ErrorAction Stop
    } catch {
        Write-Warning "Get-WinADSites - LDAP Filter: $($ADObjectSplat.LDAPFilter), SearchBase: $($ADObjectSplat.SearchBase)), Error: $($_.Exception.Message)"
    }

    $Cache = @{}
    if ($VerifyOverlap) {
        $Subnets = Get-ADSubnet -Subnets $Subnets -AsHashTable
        $OverlappingSubnets = Test-ADSubnet -Subnets $Subnets
        foreach ($Subnet in $OverlappingSubnets) {
            if (-not $Cache[$Subnet.Name]) {
                $Cache[$Subnet.Name] = [System.Collections.Generic.List[string]]::new()
            }
            $Cache[$Subnet.Name].Add($Subnet.OverlappingSubnet)
        }
        foreach ($Subnet in $Subnets) {
            $Subnet['Overlap'] = $false
            if ($Cache[$Subnet.Name]) {
                $Subnet['Overlap'] = $true
                $Subnet['OverLapList'] = $Cache[$Subnet.Name]
            } else {

            }
            [PSCustomObject] $Subnet
        }


    } else {
        Get-ADSubnet -Subnets $Subnets
    }
}