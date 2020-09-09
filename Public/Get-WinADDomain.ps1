function Get-WinADDomain {
    [cmdletBinding()]
    param(
        [string] $Domain
    )
    try {
        if ($Domain) {
            $Type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
            $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($Type, $Domain)
            $DomainInformaiton = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        } else {
            $DomainInformaiton = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
        }
    } catch {
        Write-Warning "Get-WinADDomain - Error: $($_.Exception.Message)"
    }
    $DomainInformaiton
}