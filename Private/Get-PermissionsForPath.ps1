function Get-PermissionsForPath {
    <#
    .SYNOPSIS
    Retrieves permissions for a specified path, optionally including subdirectories.

    .DESCRIPTION
    This function retrieves permissions for a specified path, optionally including subdirectories.

    .PARAMETER Path
    Specifies the path to the item for which to retrieve permissions.

    .PARAMETER NoRecursion
    Disables recursive querying of permissions and limits the query to the root of the specified path.

    .PARAMETER Depth
    Limits the depth of recursion that happens when querying a directory.

    .PARAMETER Owner
    Specifies that the cmdlet should only return the owner of the item instead of the full permissions.

    .EXAMPLE
    Get-PermissionsForPath -Path "C:\MyFolder" -NoRecursion -Owner

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $Path,
        [switch] $NoRecursion,
        [int] $Depth,
        [switch] $Owner
    )

    try {
        $targetItem = Get-Item -Path $Path -Force -ErrorAction Stop
    } catch {
        Write-Warning "Get-PermissionsForPath - Failed to get item '$Path': $($_.Exception.Message)"
        return
    }

    # Determine child items based on recursion settings
    $childItems = if ($NoRecursion) {
        @()
    } elseif ($Depth -ge 0) {
        Get-ChildItem -Path $Path -Recurse -Depth $Depth -Force -ErrorAction SilentlyContinue
    } else {
        Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    }

    $items = @($targetItem) + $childItems

    foreach ($item in $items) {
        try {
            if ($Owner) {
                $Output = Get-FileOwner -JustPath -Path $item.FullName -Resolve -AsHashTable -ErrorAction Stop
                $Output['Attributes'] = $item.Attributes
                [PSCustomObject] $Output
            } else {
                $Output = Get-FilePermission -Path $item.FullName -ResolveTypes -Extended -AsHashTable -ErrorAction Stop
                foreach ($O in $Output) {
                    $O['Attributes'] = $item.Attributes
                    [PSCustomObject] $O
                }
            }
        } catch {
            Write-Warning "Get-PermissionsForPath - Failed to process '$($item.FullName)': $($_.Exception.Message)"
        }
    }
}
