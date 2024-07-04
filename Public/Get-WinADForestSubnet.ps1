function Get-WinADForestSubnet {
    <#
    .SYNOPSIS
    Retrieves subnet information for a specified Active Directory forest.

    .DESCRIPTION
    Retrieves detailed information about subnets within the specified Active Directory forest.

    .PARAMETER Forest
    Specifies the target forest to retrieve subnet information from.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest.

    .PARAMETER VerifyOverlap
    Indicates whether to verify overlapping subnets.

    .EXAMPLE
    Get-WinADForestSubnet -Forest "example.com" -VerifyOverlap
    This example retrieves subnet information for the "example.com" forest and verifies overlapping subnets.

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
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
        $SubnetsList = Get-ADObject @ADObjectSplat -ErrorAction Stop
    } catch {
        Write-Warning "Get-WinADSites - LDAP Filter: $($ADObjectSplat.LDAPFilter), SearchBase: $($ADObjectSplat.SearchBase)), Error: $($_.Exception.Message)"
    }

    $Cache = @{}
    if ($VerifyOverlap) {
        $Subnets = Get-ADSubnet -Subnets $SubnetsList -AsHashTable
        $OverlappingSubnets = Test-ADSubnet -Subnets $Subnets
        foreach ($Subnet in $OverlappingSubnets) {
            if (-not $Cache[$Subnet.Name]) {
                $Cache[$Subnet.Name] = [System.Collections.Generic.List[string]]::new()
            }
            $Cache[$Subnet.Name].Add($Subnet.OverlappingSubnet)
        }
        foreach ($Subnet in $Subnets) {
            if ($Subnet.Type -eq 'IPv4') {
                # We only set it to false to IPV4, for IPV6 it will be null as we don't know
                $Subnet['Overlap'] = $false
            }
            if ($Cache[$Subnet.Name]) {
                $Subnet['Overlap'] = $true
                $Subnet['OverLapList'] = $Cache[$Subnet.Name]
            } else {

            }
            [PSCustomObject] $Subnet
        }
    } else {
        Get-ADSubnet -Subnets $SubnetsList
    }
}