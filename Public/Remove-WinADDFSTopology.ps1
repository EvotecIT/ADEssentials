function Remove-WinADDFSTopology {
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