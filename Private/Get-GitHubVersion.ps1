function Get-GitHubVersion {
    <#
    .SYNOPSIS
    Retrieves the latest version information from GitHub for a specified cmdlet.

    .DESCRIPTION
    This function retrieves the latest version information from GitHub for a specified cmdlet and compares it with the current version.

    .PARAMETER Cmdlet
    Specifies the name of the cmdlet to check for the latest version.

    .PARAMETER RepositoryOwner
    Specifies the owner of the GitHub repository.

    .PARAMETER RepositoryName
    Specifies the name of the GitHub repository.

    .EXAMPLE
    Get-GitHubVersion -Cmdlet "YourCmdlet" -RepositoryOwner "OwnerName" -RepositoryName "RepoName"
    Retrieves and compares the latest version information for the specified cmdlet from the GitHub repository.

    .NOTES
    Author: Your Name
    Date: Current Date
    Version: 1.0
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Cmdlet,
        [Parameter(Mandatory)][string] $RepositoryOwner,
        [Parameter(Mandatory)][string] $RepositoryName
    )
    $App = Get-Command -Name $Cmdlet -ErrorAction SilentlyContinue
    if ($App) {
        [Array] $GitHubReleases = (Get-GitHubLatestRelease -Url "https://api.github.com/repos/$RepositoryOwner/$RepositoryName/releases" -Verbose:$false)
        $LatestVersion = $GitHubReleases[0]
        if (-not $LatestVersion.Errors) {
            if ($App.Version -eq $LatestVersion.Version) {
                "Current/Latest: $($LatestVersion.Version) at $($LatestVersion.PublishDate)"
            } elseif ($App.Version -lt $LatestVersion.Version) {
                "Current: $($App.Version), Published: $($LatestVersion.Version) at $($LatestVersion.PublishDate). Update?"
            } elseif ($App.Version -gt $LatestVersion.Version) {
                "Current: $($App.Version), Published: $($LatestVersion.Version) at $($LatestVersion.PublishDate). Lucky you!"
            }
        } else {
            "Current: $($App.Version)"
        }
    }
}