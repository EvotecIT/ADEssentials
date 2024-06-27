function Get-WinADDomain {
    [cmdletBinding()]
    param(
        [string] $Domain
    )
    try {
        if ($Domain) {
            $Type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
            $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($Type, $Domain)
            $DomainInformation = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        } else {
            $DomainInformation = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
        }
    } catch {
        Write-Warning "Get-WinADDomain - Can't get $Domain information, error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
    }
    $DomainInformation
}