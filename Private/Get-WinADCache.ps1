function Get-WinADCache {
    <#
    .SYNOPSIS
    Retrieves Windows Active Directory cache information.

    .DESCRIPTION
    This function retrieves Windows Active Directory cache information based on specified parameters.

    .PARAMETER ByDN
    Specifies to retrieve AD cache information by DistinguishedName.

    .PARAMETER ByNetBiosName
    Specifies to retrieve AD cache information by NetBIOSName.

    .EXAMPLE
    Get-WinADCache -ByDN
    Retrieves AD cache information by DistinguishedName.

    .EXAMPLE
    Get-WinADCache -ByNetBiosName
    Retrieves AD cache information by NetBIOSName.

    .NOTES
    This cmdlet retrieves and organizes Active Directory cache information for specified parameters.

    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
    [alias('Get-ADCache')]
    [cmdletbinding()]
    param(
        [switch] $ByDN,
        [switch] $ByNetBiosName
    )
    $ForestObjectsCache = [ordered] @{ }
    $Forest = Get-ADForest
    foreach ($Domain in $Forest.Domains) {
        $Server = Get-ADDomainController -Discover -DomainName $Domain
        try {
            $DomainInformation = Get-ADDomain -Server $Server.Hostname[0]
            $Users = Get-ADUser -Filter "*" -Server $Server.Hostname[0]
            $Groups = Get-ADGroup -Filter "*" -Server $Server.Hostname[0]
            $Computers = Get-ADComputer -Filter "*" -Server $Server.Hostname[0]
        } catch {
            Write-Warning "Get-ADCache - Can't process domain $Domain - $($_.Exception.Message)"
            continue
        }

        if ($ByDN) {
            foreach ($_ in $Users) {
                $ForestObjectsCache["$($_.DistinguishedName)"] = $_
            }
            foreach ($_ in $Groups) {
                $ForestObjectsCache["$($_.DistinguishedName)"] = $_
            }
            foreach ($_ in $Computers) {
                $ForestObjectsCache["$($_.DistinguishedName)"] = $_
            }
        } elseif ($ByNetBiosName) {
            foreach ($_ in $Users) {
                $Identity = -join ($DomainInformation.NetBIOSName, '\', $($_.SamAccountName))
                $ForestObjectsCache["$Identity"] = $_
            }
            foreach ($_ in $Groups) {
                $Identity = -join ($DomainInformation.NetBIOSName, '\', $($_.SamAccountName))
                $ForestObjectsCache["$Identity"] = $_
            }
            foreach ($_ in $Computers) {
                $Identity = -join ($DomainInformation.NetBIOSName, '\', $($_.SamAccountName))
                $ForestObjectsCache["$Identity"] = $_
            }
        } else {
            Write-Warning "Get-ADCache - No choice made."
        }
    }
    $ForestObjectsCache
}
