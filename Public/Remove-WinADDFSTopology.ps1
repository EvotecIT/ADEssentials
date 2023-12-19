function Remove-WinADDFSTopology {
    <#
    .SYNOPSIS
    This command removes DFS topology objects from Active Directory that are missing one or more properties

    .DESCRIPTION
    This command removes DFS topology objects from Active Directory that are missing one or more properties.

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER Type
    Type of objects to remove - to remove those missing at least one property or all properties (MissingAtLeastOne, MissingAll)

    .EXAMPLE
    Remove-WinADDFSTopology -Type MissingAll -Verbose -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [parameter(Mandatory)][ValidateSet('MissingAtLeastOne', 'MissingAll')][string] $Type
    )
    Write-Verbose -Message "Remove-WinADDFSTopology - Getting topology"
    $Topology = Get-WinADDFSTopology -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -Type $Type
    foreach ($Object in $Topology) {
        Write-Verbose -Message "Remove-WinADDFSTopology - Removing '$($Object.Name)' with status '$($Object.Status)' / DN: '$($Object.DistinguishedName)' using '$($Object.QueryServer)'"
        try {
            Remove-ADObject -Identity $Object.DistinguishedName -Server $Object.QueryServer -Confirm:$false -ErrorAction Stop
        } catch {
            Write-Warning -Message "Remove-WinADDFSTopology - Failed to remove '$($Object.Name)' with status '$($Object.Status)' / DN: '$($Object.DistinguishedName)' using '$($Object.QueryServer)'. Error: $($_.Exception.Message)"
        }
    }
}