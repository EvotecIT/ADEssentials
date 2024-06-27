function Get-WinADForest {
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