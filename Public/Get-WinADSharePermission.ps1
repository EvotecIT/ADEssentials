function Get-WinADSharePermission {
    <#
    .SYNOPSIS
    Retrieves the permissions for a specified Windows Active Directory share or shares based on type.

    .DESCRIPTION
    This cmdlet retrieves the permissions for a specified Windows Active Directory share or shares based on type. It can target a specific path or retrieve permissions for shares of a specified type across multiple domains in a forest. The cmdlet can also filter the results to include or exclude specific domains and provide additional forest information.

    .PARAMETER Path
    Specifies the path to the share for which to retrieve permissions. This parameter is mandatory when using the 'Path' parameter set.

    .PARAMETER ShareType
    Specifies the type of share for which to retrieve permissions. This parameter is mandatory when using the 'ShareType' parameter set. Valid values are 'NetLogon' and 'SYSVOL'.

	.PARAMETER NoRecursion
    Disables recursive querying of permissions and limits the query to the root of the sepcified path. This is a switch so no other variable is neeed. Just add `-NoRecursion`. This superceeds the `-Depth` parameter.

	.PARAMETER Depth
    Limit the depth of recursion that happens when querying a directory. Especially useful for large and complex folders with several hundred or dozen subfolders.  -1 = unlimited recursion, 0 = no recursion, 1-1023 total limit of recursion depth

    .PARAMETER Owner
    Specifies that the cmdlet should only return the owner of the share instead of the full permissions.

    .PARAMETER Name
    Specifies the name of the share for which to retrieve permissions. This parameter is not currently used.

    .PARAMETER Forest
    Specifies the name of the forest to target for share permissions retrieval. This parameter is used in conjunction with the 'ShareType' parameter.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the share permissions retrieval.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the share permissions retrieval.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest to use for share permissions retrieval.

    .EXAMPLE
    Get-WinADSharePermission -Path "\\domain\share"
    Retrieves the permissions for the specified share path.

    .EXAMPLE
    Get-WinADSharePermission -ShareType NetLogon -Forest MyForest
    Retrieves the permissions for all NetLogon shares across the specified forest.

    .EXAMPLE
    Get-WinADSharePermission -ShareType SYSVOL -IncludeDomains MyDomain1, MyDomain2
    Retrieves the permissions for all SYSVOL shares in the specified domains.

    .NOTES
    This cmdlet requires the 'Get-WinADForestDetails', 'Get-FileOwner', and 'Get-FilePermission' cmdlets to function.
    #>
    [cmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory)][string] $Path,
        [Parameter(ParameterSetName = 'ShareType', Mandatory)][validateset('NetLogon', 'SYSVOL')][string[]] $ShareType,
        [switch]$NoRecursion,   # Prevents recursive scanning (supercedes Depth)
        [int]$Depth = -1,       # -1 means unlimited recursion
        [switch] $Owner,
        [string[]] $Name,
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    if ($ShareType) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
        foreach ($Domain in $ForestInformation.Domains) {
            $SharePath = "\\$Domain\$ShareType"
            Invoke-SharePath -Path $SharePath -NoRecursion:$NoRecursion -Depth $Depth -Owner:$Owner
        }
    } else {
        if ($Path -and (Test-Path -Path $Path)) {
            Invoke-SharePath -Path $Path -NoRecursion:$NoRecursion -Depth $Depth -Owner:$Owner
        } else {
            Write-Warning "Path does not exist: $Path"
        }
    }
}