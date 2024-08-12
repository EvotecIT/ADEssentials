function Get-WinADForest {
    <#
    .SYNOPSIS
    Retrieves information about a specified Active Directory forest.

    .DESCRIPTION
    This function retrieves detailed information about the specified Active Directory forest.
    It queries the forest to gather information such as domain controllers, sites, and other forest-related details.

    .PARAMETER Forest
    Specifies the target forest to retrieve information from.

    .EXAMPLE
    Get-WinADForest -Forest "example.com"

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [cmdletBinding()]
    param(
        [string] $Forest
    )
    try {
        if ($Forest) {
            $Type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest
            $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($Type, $Forest)
            $ForestInformation = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
        } else {
            $ForestInformation = ([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest())
        }
    } catch {
        Write-Warning "Get-WinADForest - Can't get $Forest information, error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
    }
    $ForestInformation
}