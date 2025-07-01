function Invoke-SharePath {
    <#
    .SYNOPSIS
    Retrieves share permissions for a specified path, optionally including subdirectories.

    .DESCRIPTION
    This function retrieves share permissions for a specified path, optionally including subdirectories.

    .PARAMETER Path
    Specifies the path to the share for which to retrieve permissions.

    .PARAMETER NoRecursion
    Disables recursive querying of permissions and limits the query to the root of the specified path.

    .PARAMETER Depth
    Limits the depth of recursion that happens when querying a directory.

    .PARAMETER Owner
    Specifies that the cmdlet should only return the owner of the share instead of the full permissions.

    .EXAMPLE
    Invoke-SharePath -Path "\\server\share" -NoRecursion -Owner

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [string]$Path,
        [switch]$NoRecursion,
        [int]$Depth,
        [switch]$Owner
    )

    # Ensure the root path is always included
    $items = @(
        if (Test-Path -Path $Path) {
            Get-Item -Path $Path -Force  # Always include the root folder
        }

        # Get subdirectories based on recursion settings
        if (-not $NoRecursion) {
            if ($Depth -ge 0) {
                Get-ChildItem -Path $Path -Directory -Depth $Depth -Force -ErrorAction SilentlyContinue
            } else {
                Get-ChildItem -Path $Path -Directory -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    )
    # Process each item
    $items | ForEach-Object -Process {
        if ($Owner) {
            $Output = Get-FileOwner -JustPath -Path $_.FullName -Resolve -AsHashTable
            $Output['Attributes'] = $_.Attributes
            [PSCustomObject] $Output
        } else {
            $Output = Get-FilePermission -Path $_.FullName -ResolveTypes -Extended -AsHashTable
            foreach ($O in $Output) {
                $O['Attributes'] = $_.Attributes
                [PSCustomObject] $O
            }
        }
    }
}